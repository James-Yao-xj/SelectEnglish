# Source-form validation CPU measurements

Date: 2026-11-17. Local synthetic/offline measurements only. No clipboard, UI, credentials, provider requests, or private source text were accessed.

## Method

- Apple Silicon arm64, macOS 26.6.2, Apple Swift 6.3.3. Each variant compiled separately with identical `swiftc -O` flags and the same harness. This measures `Analysis.validated(source:)`, excluding HTTP, JSON decoding, AX capture, and presentation.
- The pre-change source is `46e067e^` (`8e1cd5f`); `46e067e` itself already includes source-form validation. The current validator snapshot matches `a7a1b3a`; its redirect-helper visibility change does not change validation.
- Short input: 99 generated/public-sample characters and four matching terms. Near-limit input: 20,000 generated ASCII characters and eight matching terms near the end. All validations succeed and their results contribute to a checksum.
- Two runs in reversed variant order, three warm-up calls per process, 21 batches per run. Short batches contain 200 validations; near-limit batches contain three. Tables show milliseconds per validation, with 42 batch averages per variant. P95 uses the nearest-rank method. These are local observations, not performance assertions or an accuracy/latency guarantee.

## Before source-form validation versus current validation

| Input | Variant | Minimum | Median | P95 | Maximum |
|---|---|---:|---:|---:|---:|
| 99 characters / 4 terms | Before `46e067e` | 0.0252 | 0.0261 | 0.0348 | 0.0368 |
| 99 characters / 4 terms | Current | 0.1301 | 0.1328 | 0.1451 | 0.1475 |
| 20,000 characters / 8 terms | Before `46e067e` | 0.0606 | 0.0763 | 0.1038 | 0.1059 |
| 20,000 characters / 8 terms | Current | 16.8431 | 17.7325 | 18.0561 | 19.1685 |

Added median CPU time is approximately 0.107 ms for the short input and 17.656 ms near the input limit. This does not explain a multi-second selection-to-result delay. The near-limit cost is measurable, but these synchronous microbenchmarks do not establish which executor runs production validation or whether UI responsiveness is affected.

## Measured optimization

The original provenance check compacts source whitespace separately for every vocabulary item. An isolated prototype compacts the source once and still compacts each returned word separately. Original source text remains the input to the existing single-word checks; punctuation, boundaries, and inflections retain their rules.

| Input | Variant | Minimum | Median | P95 | Maximum |
|---|---|---:|---:|---:|---:|
| 99 characters / 4 terms | Current | 0.1296 | 0.1307 | 0.1326 | 0.1354 |
| 99 characters / 4 terms | Hoist prototype | 0.1170 | 0.1180 | 0.1245 | 0.2173 |
| 20,000 characters / 8 terms | Current | 16.6923 | 17.0536 | 17.5162 | 17.5821 |
| 20,000 characters / 8 terms | Hoist prototype | 11.2604 | 11.5054 | 11.6702 | 11.6907 |

The prototype saves approximately 5.55 ms (32.5%) at the near-limit median, and 0.013 ms for the short sentence. Applied only this simple hoist; the implementation also skips source compaction when vocabulary is empty. No further optimization or timing threshold was added.

## Reproduction and validation

Temporary harness, source snapshots, and raw distributions: `/tmp/selectenglish-validation-bench.ekH1sM/`. `parent-vs-current.json` contains the corrected pre-change comparison; `current-vs-hoist.json` contains the optimization comparison. These temporary files are diagnostic artifacts, not permanent project dependencies.

Focused Services regressions passed after the implementation change, including original source forms, technical punctuation, multiline phrases, single-word requirements, historical records, request contracts, the actual redirect policy, and mocked HTTP failures. Compiled test output: `/tmp/selectenglish-hoist-services.QHOIH3/`. No new test mirrors whitespace-hoisting implementation and no flaky timing assertion was added.
