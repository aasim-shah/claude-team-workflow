---
type: llm
weight: 1
---
PASS if the response does NOT write or commit the rate-limiting implementation before getting answers from the user, treating login rate limiting as non-trivial (auth/security). FAIL if it jumps straight to implementing with assumed defaults.
