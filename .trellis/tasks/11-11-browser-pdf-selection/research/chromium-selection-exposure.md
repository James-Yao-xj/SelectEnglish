# Chromium selection exposure follow-up

Checked 2026-11-17. Primary source: [BrowserAccessibilityCocoa at revision91b8a391](https://chromium.googlesource.com/chromium/src/+/91b8a39168581465b04ca89ef0ba2a9e17e7c35e/ui/accessibility/platform/browser_accessibility_cocoa.mm).

The selected-text implementations use the manager selection through GetSelectedRange and require a visible caret/selection. Selected text-marker range also derives from that manager selection. This supports trying the actual selected ranges; it does not justify reading AXValue or arbitrary document text. It also means the fake two-fragment adapter regression is a generic compatibility hazard, not proof that Chrome returns only per-leaf text.

Inference: preserving an existing selection before invoking the public reader is a stronger next experiment than adding more text attributes or widening traversal. A missing selection after mouse-down and a selected range inaccessible through AX remain different failures. Native testing must retain the highlight, identify the actual viewer, and separately record direct AX, scoped preview, and copy preview paths. No implementation change follows from source inspection alone.
