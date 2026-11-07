# SelectEnglish

MacBook 原生菜单栏工具：选中英文 → 触控板用力点按 → 中文翻译与表达积累 → 手动收藏。

## 运行

```sh
bash Probe/build.sh
open .build/probe/SelectEnglishProbe.app
```

需要 macOS、Force Touch 触控板与 Xcode Command Line Tools。点击结果窗口的“触发状态”可授权辅助功能并检查监听。关闭窗口后应用仍在菜单栏“译”中运行；从菜单可退出。

首次运行请在“AI 设置”填写完整 HTTPS `/chat/completions` 接口地址、模型名和 API 密钥。未配置不会发送文字。保存有效配置后，重按会自动分析所选原文；也可点击“分析 / 重试”。最长 20,000 字符，超时 60 秒。服务需要支持非流式 OpenAI 兼容 chat completions；密钥仅写入系统钥匙串，更换服务域名必须重新输入密钥。

结果包含中文翻译、原文中的有用表达、中文释义与用法、英文例句。短原文可以少于 3 个表达。点击“收藏这次结果”才会保存原文与分析；“我的收藏”可查看及删除。

收藏位于 `~/Library/Application Support/SelectEnglish/notebook.json`。自动分析结果不落盘；收藏文件损坏时保留原文件并阻止覆盖。接口失败不记录响应正文或密钥。

## 验证与限制

`bash Probe/test.sh` 运行手势去重、模拟 HTTP 请求/解析/错误/超时/取消和收藏持久化/删除/损坏保护测试，不发真实网络请求。

本机真实 Force Click 已验证：被动全局手势转换到 stage 2，随后读取 TextEdit 完整 50 字符选区。最终 v0.5 在 Chrome 重按后成功读取 40 字符选区；其他应用仍需实测；系统查询可能同时弹出或改变选区。图片和扫描 PDF 不支持。首次真实 AI 请求需要你填写服务配置，尚未验证特定供应商。

当前开发构建临时签名，重编译可能需要重新授权同一个应用。包名和 bundle ID 保留探针身份，以避免无谓更换权限身份。验证过的 v0.4 副本保存在 `.build/verified-v0.4/`；不要同时运行多个副本。

## Trellis

阅读 `AGENTS.md` 与 `.trellis/workflow.md`；活动任务为 `.trellis/tasks/11-07-selection-mvp/`。

GitHub 私有仓库：https://github.com/James-Yao-xj/SelectEnglish 。尚未提交推送。
