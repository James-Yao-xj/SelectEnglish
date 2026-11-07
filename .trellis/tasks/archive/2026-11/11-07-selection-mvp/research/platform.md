# 平台与流程调研

2026-11-07：本机存在 Trellis、Swift 6.3.3、GitHub CLI；GitHub 登录已验证。

- Trellis 官方：https://github.com/mindfold-ai/Trellis
- Apple AXUIElementCopyAttributeValue：https://developer.apple.com/documentation/applicationservices/1462085-axuielementcopyattributevalue
- Apple AXUIElement：https://developer.apple.com/documentation/applicationservices/axuielement_h

AX 是选区读取的候选机制，应用兼容性必须实际验证。不能从 API 的存在推断所有应用均支持选区读取。
Trellis native 流程要求需求探索、方案审阅、激活任务后实现，并在收尾前检查与回写规范。

## Force Click 调研与待验证事项
用户已确认主触发是触控板 Force Click。
Apple stage 文档将 stage 2 用于 Force Click 即时动作：
https://developer.apple.com/documentation/appkit/nsevent/stage
全局事件监视器只能观察，不能阻止原应用接收：
https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents(matching:handler:)
本机 SDK NSEvent.h 同样说明全局监听异步传递、不能修改或阻止原事件。
尚未实测：其他应用中的 pressure 事件可见性、重按时选区保留、系统查询冲突。以上不是已实现功能。

## User feedback and v0.2 diagnostics
User screenshot: global events 0, local events 69, visible stage 1 only. User also reports manual selection read failure; exact error not yet available. Root cause remains unknown. v0.2 adds actual permission refresh, target/AX role metadata, named AX errors, Chinese instructions, and a one-shot delayed read that hides the probe. It keeps the existing per-app AX focus algorithm and Force Click gate. No clipboard or private API workaround is introduced. Physical retest remains required.
