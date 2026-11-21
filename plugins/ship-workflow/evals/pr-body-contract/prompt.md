---
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

The payment provider returns brief 503s during its deploys; last week about 2% of checkouts failed because of them, and a retry a second later would have succeeded. So I changed our checkout service to retry failed payment-provider calls up to 3 times with exponential backoff (files: src/payments/client.ts, src/payments/client.test.ts). I ran `npm test` locally and it passed. I have not pushed yet.

There is no repository in this session. Write the commit message and the full pull request description I should use.
