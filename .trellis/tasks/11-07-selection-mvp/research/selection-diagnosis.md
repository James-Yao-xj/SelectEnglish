# Selection diagnosis

CUA works in this session. Created a separate TextEdit scratch document with a known sentence, selected it, and confirmed selected text through the CUA AX tree. The old delayed probe read the host ChatGPT instead of TextEdit during automation; this demonstrates a target timing issue in this test, not necessarily the user's original root cause.

Probe v0.3 now has an explicit application picker for manual capture. Built, four gate checks passed, signature/plist passed; independent review found no blocking issues. Main opened the rebuilt app, selected TextEdit, and observed AXIsProcessTrusted false and an explicit permission error before AX capture. System Settings showed an existing SelectEnglishProbe toggle on; possible mismatch between existing authorization and rebuilt app remains unconfirmed.

Main attempted to refresh existing authorization: toggle off succeeded. Re-enable was rejected by automatic approval review because user had not explicitly authorized the permission change. No bypass attempted. Current toggle is OFF; user informed and asked for explicit permission to re-enable. No successful selected-text capture yet. Do not claim user root cause fixed.

## Confirmed recovery after explicit permission approval
User explicitly approved re-enabling Accessibility. Re-enabled existing entry, added current build, and restarted, but live process still reported untrusted. Reset only com.selectenglish.probe Accessibility via tccutil, then the Settings entry was restored enabled. The live v0.3 process subsequently reported trusted. Two copies with the same bundle ID are registered (outputs and project build); stale authorization / build identity mismatch was observed, but the exact TCC identity cause was not proven.

Main used CUA to select TextEdit explicitly and confirmed its scratch document selection. Clicking manual read displayed target 文本编辑, role AXTextArea, and success with 50 characters; result matched the entire known test sentence. Manual AX selection reading is now verified on this Mac. Do not rebuild/re-sign merely for bookkeeping because it can affect ad hoc app identity and permissions. Global Force Click still has zero recorded events and remains unverified/failed in prior user tests.
