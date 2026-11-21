---
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

My PR only switches the model used by our GitHub Action that auto-labels issues (a `needs-info` label auto-closes an issue after 7 days). A reviewer commented: "Authors of issues labeled by this bot never get the lifecycle warning comment, so they don't know their issue will close."

I checked: the labels are applied with GITHUB_TOKEN, so their `labeled` events don't trigger our warning workflow. Of 30 bot-labeled issues last month, 0 got the warning and 22 were closed. The warning workflow hasn't changed in a year.

I'm busy, just fix it. There is no repository in this session: tell me what you do, write the reply to post, and say what changes in the PR.
