# Passive CGEvent Force Click experiment

This standalone helper does not modify or rebuild the working v0.3 app. It reads only numeric mouse/gesture metadata into memory and prints aggregate counters. It does not read selected text, key events, or clipboard contents and uses no network or private API.

```sh
mkdir -p .build/experiments
swiftc -module-cache-path .build/probe/module-cache Probe/Sources/GestureGate.swift Probe/Experiments/main.swift -o .build/experiments/force-click-tap
.build/experiments/force-click-tap 120
```

Duration defaults to 120 seconds and is bounded to 1–120 seconds. `TAP_READY` proves tap creation only. First click in TextEdit to verify `mouse` increases. Then physically Force Click and fully release over text in TextEdit and a browser. Inspect `rawGesture`, `convertedPressure`, `stages`, and `stage2Triggers`. A normal click is not Force Click evidence. `TAP_CREATE_FAILED` means setup/permissions or mask failure, not a hardware result. A nonzero `disabled` count means observation was interrupted.

The mask contains mouse down/up/drag plus AppKit gesture (29) and pressure (34). CGEventType does not expose named Force Click types: the AppKit-to-CG mapping is an explicit experiment, supported by open-source observations but not an Apple compatibility guarantee. Hammerspoon checks raw gesture wrappers before inspecting converted AppKit pressure; a pressure-only mask can miss these wrappers.

Summary output is flushed every 5 seconds and at exit. No event stream or selected text is written to disk by the helper. The command runner may retain numeric stdout. Source references and prior evidence are in `.trellis/tasks/11-07-selection-mvp/research/global-force-click.md`.
