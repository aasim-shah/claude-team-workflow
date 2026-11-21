# Code shape and tests

Measured on the published mod sources (TypeScript). These patterns make a codebase cheap for agents to read and safe for several agents to edit at once.

## Code shape

| Metric | diff | sec-default | telemetry | agents-md |
|---|---|---|---|---|
| Source files | 584 | 135 | 205 | 56 |
| Average lines per file | 15 | 26 | 14 | 19 |
| Test LOC / source LOC | 1.18 | 1.75 | 0.68 | 0.34 |

- **One export per file. A folder per concept, with an `index.ts` barrel** (`export * from './x'`, `export * as default from '.'`). An agent loads exactly what it needs, and parallel agents rarely touch the same file.
- **Name the file after the export** (`git-backend-of.ts` exports `gitBackendOf`). This makes grep a navigator.
- **Doc comments on every export,** with `@param` and `@returns`, saying what the code does and why, and naming the original it mirrors.
- **Constants in their own modules** (`Limits.GIT_TIMEOUT_MS`), frozen where they are lists.
- **Errors become values at boundaries** (`catch { return FAILED_RUN }`), so callers branch on data, not on exceptions.

## Tests

- Test files mirror the source names: `register.test.ts` sits beside `hooks/register.ts`. Each file has one `describe` titled with that name.
- Shared setup goes in `tests/fixtures/`, one export per file.
- **Loud failure:** in the test harness, a call nobody answers throws and names the event. No silent defaults.
- **Fakes that cover the world, one noun at a time:** `mock.env`, `mock.store`, `mock.clock`. The clock's `advance(ms)` and `settle()` make timing deterministic.
- **Generated files are checked:** a test fails when a generated declaration is stale, and **names the command that regenerates it**. Every failure message should tell the reader how to fix it.
- CI typechecks every module plus its tests on every PR that touches them.

## Docs

A README per module covers:
- what the module does;
- where it sits in the chain;
- the exact contract, as a table of event → behaviour;
- its options;
- what it does **not** cover ("Left over: …").

Being explicit about the limits is a recurring habit.
