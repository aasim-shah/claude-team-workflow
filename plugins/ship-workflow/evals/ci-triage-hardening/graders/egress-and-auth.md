---
type: llm
weight: 1
---
PASS if network egress is restricted (egress firewall / allowlist) or the exfiltration risk is explicitly addressed, AND auth uses short-lived OIDC / workload identity or explicitly flags a static API key as the weaker fallback. Otherwise FAIL.
