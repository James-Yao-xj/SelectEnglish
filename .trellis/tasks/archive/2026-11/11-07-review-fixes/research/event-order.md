# Mouse-event ordering for pending AX dismissal
Apple primary references:
- https://developer.apple.com/documentation/appkit/nsevent/timestamp : event timestamp in seconds since system startup; links to ProcessInfo.systemUptime.
- https://developer.apple.com/documentation/foundation/processinfo/systemuptime : uptime seconds since restart.

The initiating ordinary mouse-down precedes Force Click stage2. A delayed NSEvent global/local monitor callback for that same down must not cancel the newly begun AX capture. Compare event timestamp with capture-start uptime, not callback receipt time. While capture is pending and panel hidden, later mouse-downs represent click-away; otherwise use the visible-panel inside/outside policy. No new keyboard/eventtap mask or forced synthetic mouse events needed.
