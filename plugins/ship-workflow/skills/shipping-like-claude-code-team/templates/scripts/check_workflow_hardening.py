#!/usr/bin/env python3
"""Fail when a workflow job that calls Claude breaks the rules in CLAUDE.md ("Workflows that call Claude").

Usage:  python3 scripts/check_workflow_hardening.py [repo_root]
Needs PyYAML (pip install pyyaml). Exit 1 with ::error:: lines on any violation.

A job "calls Claude" when a step uses anthropics/claude-code-action (or -base-action), or the job
text mentions anthropic_federation_rule_id. Exemptions: add "<workflow file>:<job id>" with a reason.
"""
import pathlib
import re
import sys

import yaml

FIREWALL_RUNNER = "ubuntu-24.04-firewall"
CLAUDE_ACTIONS = ("anthropics/claude-code-action", "anthropics/claude-code-base-action")
SIGN_IN_MARKER = "anthropic_federation_rule_id"
AUTO_MODE_MIN = (4, 6)  # auto mode needs claude-*-4-6 or newer; older models fall back silently
MODEL = re.compile(r"claude-(?:opus|sonnet|haiku)-(\d+)(?:-(\d{1,2}))?(?![\d.])")
WRITE_TOOLS = ("Write", "Edit", "WebFetch", "WebSearch")

EXEMPT_FROM_FIREWALL_RUNNER: dict[str, str] = {}
EXEMPT_FROM_AUTO_MODE: dict[str, str] = {}


def main(root: pathlib.Path) -> int:
    errors: list[str] = []
    workflows = sorted((root / ".github/workflows").glob("*.y*ml"))
    any_claude_job = False

    for wf in workflows:
        doc = yaml.safe_load(wf.read_text(encoding="utf-8")) or {}
        for job_id, job in (doc.get("jobs") or {}).items():
            key = f"{wf.name}:{job_id}"
            text = yaml.safe_dump(job)
            steps = job.get("steps") or []
            claude_steps = [s for s in steps if str(s.get("uses", "")).startswith(CLAUDE_ACTIONS)]
            if not claude_steps and SIGN_IN_MARKER not in text.lower():
                continue
            any_claude_job = True

            if job.get("runs-on") != FIREWALL_RUNNER and key not in EXEMPT_FROM_FIREWALL_RUNNER:
                errors.append(f"{key}: runs-on must be {FIREWALL_RUNNER}")

            if "defaultMode" in text and key not in EXEMPT_FROM_AUTO_MODE:
                errors.append(f"{key}: sets defaultMode; permission mode must come from --permission-mode auto only")

            for step in claude_steps:
                inputs = step.get("with") or {}
                args = str(inputs.get("claude_args", ""))
                if key in EXEMPT_FROM_AUTO_MODE:
                    continue
                if "--permission-mode auto" not in args:
                    errors.append(f"{key}: claude_args lacks --permission-mode auto")
                for major, minor in MODEL.findall(args):
                    if (int(major), int(minor or 0)) < AUTO_MODE_MIN:
                        errors.append(f"{key}: model claude-*-{major}-{minor or 0} is too old for auto mode")
                if "anthropic_api_key" in inputs:
                    errors.append(f"{key}: uses a static API key; use workload identity federation")
                if inputs.get("allowed_non_write_users"):
                    denied = set(re.findall(r"[A-Za-z]+", args.split("--disallowedTools", 1)[-1]))
                    missing = [t for t in WRITE_TOOLS if t not in denied]
                    if "--disallowedTools" not in args or missing:
                        errors.append(f"{key}: open to non-write users but does not disallow {missing or WRITE_TOOLS}")

    if any_claude_job:
        policy_path = root / ".github/egress-firewall.yaml"
        if not policy_path.exists():
            errors.append(".github/egress-firewall.yaml is missing")
        else:
            policy = yaml.safe_load(policy_path.read_text(encoding="utf-8")) or {}
            hosts = policy.get("allow") or []
            if policy.get("mode") != "enforce":
                errors.append(".github/egress-firewall.yaml: mode must be enforce")
            if not hosts:
                errors.append(".github/egress-firewall.yaml: allow list is empty")
            errors += [f".github/egress-firewall.yaml: wildcard host {h!r}" for h in hosts if "*" in str(h)]

    for e in errors:
        print(f"::error::{e}. See CLAUDE.md, 'Workflows that call Claude'.")
    if not errors:
        print(f"OK: {len(workflows)} workflow file(s) checked")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")))
