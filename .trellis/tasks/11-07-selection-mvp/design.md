# 技术设计草案

## 边界与数据流
全局触发器 → SelectionReader → AnalysisClient → 结果窗口 → NotebookStore。
首版使用 AppKit 原生控件实现设置、结果、收藏及诊断窗口，管理菜单栏和窗口生命周期。

## 选区
通过 ApplicationServices 的 AXUIElement 读取前台应用焦点元素的 kAXSelectedTextAttribute。
必须在激活自身窗口之前捕获选区。缺少辅助功能授权时引导用户授权。
不同应用的辅助功能支持不同；首版以 TextEdit 和浏览器验证兼容性。
不默认使用模拟复制或修改剪贴板。图片文字延后处理。
主触发方式已确认为 Force Click。优先研究 NSEvent pressure 事件，在进入 stage 2 时触发；每次手势只触发一次，在释放后重置。
公开 API 可识别压力阶段，但跨进程事件投递必须实测，不能由本应用内可用推断全局可用。全局 NSEvent 监听只能观察，无法吞掉原应用事件；系统查询等动作可能同时发生。
先做不联网的触发与选区验证，检查重按过程中选区是否被普通 mouseDown 改变。失败时报告限制，请用户决定后续方向，不擅自改成快捷键。

## AI 契约
已确认采用支持自定义地址、模型、密钥的 OpenAI 兼容 chat completions 接口；地址和模型不硬编码。
请求包括选区及中文学习分析指令；把选区明确标记为待翻译数据。
响应解析成 translation 和 expressions（phrase、meaning、usage、example）。
限制选区长度，定义超时，支持取消；同一时刻只保留一个有效分析任务，防止旧结果覆盖新结果。
对网络、HTTP 和结构解析错误分别给出可操作提示；不记录原文或密钥。

## 存储
Keychain 保存密钥；UserDefaults 保存非敏感设置。
收藏使用 Application Support 下的 Codable JSON，原子写入；损坏时保留原文件并提示。

## 回退
首版无服务器及远程迁移。实现按选区、接口、存储分步验证，失败时保留错误并允许重试。
以上架构已落地；验证状态见 implement.md 与 research/，不把模拟测试视为真实供应商验证。

## Validated trigger adapter update
Use a passive session CGEvent tap with selective mouse/gesture/pressure mask. Convert raw gestures using public NSEvent(cgEvent:); only read pressure/stage when converted type is pressure. Gate stage 2 once until release. Keep the callback lightweight: snapshot source PID, perform AX reads on a worker, then update UI on main with stale-result checks. Live independent helper delivered real stage2 twice. Preserve manual target picker for diagnosis; no keyboard or private gesture synthesis.

## Final MVP architecture
Native AppKit menu-bar controller replaces the diagnostic-only window. `ForceClickMonitor` observes the same passive CG gesture/pressure masks; `SelectionReader` runs on a serial worker. Source capture completes before the result window opens. Settings, notebook and trigger status are separate windows. A shared generation invalidates AX/AI results after a newer capture, cancel or result-window close.
`AnalysisClient` uses an ephemeral URLSession, rejects redirects and sends the complete configured HTTPS chat-completions endpoint unchanged. It requests plain JSON in message content without forcing response_format, parses optional complete Markdown fences, validates required fields, and never echoes provider bodies on error.
Keychain holds one API key, preferences hold endpoint/model and the key's normalized origin. Changing the origin requires new key input; request configuration also checks binding. Blank secure fields preserve keys only for the bound origin.
`NotebookStore` atomically commits user-saved source/result pairs before publishing state; corrupt existing files remain untouched and prevent writes.
