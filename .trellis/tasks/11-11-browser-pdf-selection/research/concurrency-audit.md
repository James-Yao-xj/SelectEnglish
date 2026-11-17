# Compiler concurrency diagnostic audit

Reviewed source: clean HEAD `e117d2a`. Audit performed during the 2026-11-17 autonomous session; recorded on 2026-11-18 (Asia/Shanghai). This records the existing check; no compiler or test rerun accompanied this record.

## Method and result

Installed compiler: Apple Swift 6.3.3 (`swiftlang-6.3.3.1.3`, clang `2100.1.1.101`). Typechecked all production Swift sources for arm64 and macOS 13.0 with the installed macOS SDK:

```sh
xcrun swiftc -typecheck -warn-concurrency -strict-concurrency=complete \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -target arm64-apple-macosx13.0 \
  -module-cache-path /tmp/selectenglish-concurrency.F5kM5Q/module-cache \
  Probe/Sources/*.swift -framework AppKit -framework ApplicationServices
```

Exit status: **0**. There were **299 warning diagnostics**, counted from diagnostic header lines (excluding repeated source excerpts and notes):

| Source | Warnings |
|---|---:|
| `Probe/Sources/main.swift` | 172 |
| `Probe/Sources/ResultPopup.swift` | 123 |
| `Probe/Sources/ForceClickMonitor.swift` | 3 |
| `Probe/Sources/PopupMouseEvent.swift` | 1 |

Full diagnostic log: `/tmp/selectenglish-concurrency.F5kM5Q/diagnostics.log`. It contains build diagnostics only; its temporary location is not durable evidence storage. No executable was produced or launched, and no UI, clipboard, credentials, runtime user files, or network were accessed.

## Ownership assessment

No actual cross-thread defect was confirmed by this audit. The warnings principally identify main-actor ownership that the compiler cannot establish from the current annotations, non-Sendable closure captures, and the imported AX prompt constant. The assessment used these production boundaries:

- `.trellis/spec/macos/index.md:28–32` requires worker-side AX, main-thread UI publication with generation guards, and no AX/network calls inside the event tap callback.
- `ForceClickMonitor.swift:3`, `:45–48`, and `:100–105` document main-run-loop callback ownership, install the tap source on the main run loop, and dispatch deferred handoffs to main. Its mutable gesture and deferred-trigger state remain under that ownership.
- `main.swift:401–432` performs selection work on the reader queue and accesses controller generation/UI in the nested main-queue callback. Capturing the controller weakly in the worker closure does not itself establish a concurrent controller mutation.
- `ResultPopup.swift:166–175` receives AppKit local/global monitor callbacks; popup/controller actions follow the existing main-thread lifecycle. `main.swift:642` invalidates pending work and stops the monitor during application termination.
- `SelectionCommand.swift:30–70` retains an immutable captured AX reference and performs window validation on workers. `BrowserCopyFallback.swift:65–103` retains immutable source/permit references and serializes posting. These unchecked Sendable handles do not introduce mutable application state shared without synchronization in the reviewed paths.
- `SelectionCapturePermit.swift` protects cancellation state with `NSLock`. Controller publication also retains generation/cancellation checks after asynchronous work.

## Evidence limits

Exit 0 is a successful diagnostic typecheck in the compiler's default language mode, **not** a Swift 6 language-mode strict-concurrency pass. The command did not use `-swift-version 6`; its warnings remain unresolved compiler diagnostics. Static ownership tracing and the absence of a confirmed defect do not prove race freedom, actual event-delivery ordering, or native AX behavior. Prior permit-only Thread Sanitizer evidence covers only that exercised scenario, not the entire application.

No actor migration, warning suppression, source changes, or new runtime tests were performed or recommended solely on the basis of these warnings.
