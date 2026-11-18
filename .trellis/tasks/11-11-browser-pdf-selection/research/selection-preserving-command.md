# Selection-preserving command

Verified 2026-11-17 against the installed macOS SDK and Apple documentation.

- Apple `NSMenuDelegate.menuWillOpen`: https://developer.apple.com/documentation/appkit/nsmenudelegate/menuwillopen(_:)
  The callback precedes menu opening. Snapshot the external foreground process here, without mutating the menu structure. Dispatch capture after menu tracking closes; revalidate process identity and do not reactivate a stale application.
- Installed public `HIToolbox.framework/Headers/CarbonEvents.h`, declarations around lines 15428–15518: `RegisterEventHotKey` registers a fixed virtual key/modifier command, available since macOS 10.0. Exclusive registration is available since 10.5 and reports a conflict instead of silently sharing the chord. The API is not thread safe; registration, event handling, and cleanup belong to the main thread.
- The installed header is authoritative for the exclusive flag. Older archived web reference pages incorrectly describe the options field as always zero for current deployments.

A registered command does not require an ordinary global keyboard event monitor. Preserve the passive mouse/pressure mask and use one explicit Control-Option-Command-T command. This avoids PDF body mouse-down and therefore avoids the known destructive selection-clear step. It does not prove native AX selection or copy support; those need separate public-fixture runtime evidence.

AX focused-window equality can reject a changed window when the reference is available. It cannot identify a browser tab. Never document it as tab identity protection.
