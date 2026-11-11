# SelectEnglish

**在阅读中理解英文，积累表达。**

[![macOS checks](https://github.com/James-Yao-xj/SelectEnglish/actions/workflows/ci.yml/badge.svg)](https://github.com/James-Yao-xj/SelectEnglish/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

SelectEnglish 是一款面向 MacBook 的英语阅读工具。阅读网页或文档时，选中英文并用力点按触控板，即可在原文附近的小浮窗中查看生词、整句解释和固定表达，把查词与理解句子放在同一个阅读动作里。

[下载测试版](https://github.com/James-Yao-xj/SelectEnglish/releases/tag/v0.10.0-beta.1) · [安装指南](docs/INSTALL.md) · [隐私说明](PRIVACY.md) · [参与贡献](CONTRIBUTING.md)

## 为阅读而设计

- **重按取词**：通过 Force Touch 用力点按触发，结果在指针附近呈现，点击外部或按 Esc 即可关闭。
- **先词后句**：按“生词 → 整句解释 → 固定表达”的顺序分析，兼顾当前理解与后续积累。
- **面向六级读者**：优先选择较难词、专业词和熟词生义，略过普通基础词；单独查询一个词时始终解释该词。
- **原生小浮窗**：使用 AppKit 构建，牛皮纸背景与可滚动内容适合短暂查阅，日常入口收在菜单栏“译”中。
- **自选 AI 服务**：支持自定义 HTTPS 地址、模型和 API 密钥的 OpenAI 兼容接口。
- **手动收藏**：需要积累时再保存原文和分析，收藏留在本机，可随时查看与删除。

六级难度由 AI 根据语境估计，并未接入官方词表；不保证词表归属。图片文字和扫描 PDF 不支持取词；辅助功能未暴露选区时也可能读取失败。浏览器 PDF 的可选复制兼容方案与验证进度见[PDF 选区说明](docs/BROWSER-PDF.md)。

## 一次查询，可以学到什么

以这句话为例，以下内容仅用于说明学习结果的组织方式，实际返回因模型而异：

> Despite the setback, she persevered and eventually turned the tide in her favor.

| 内容 | 示例 |
|---|---|
| 生词 | **persevered** · 动词：坚持不懈；**setback** · 名词：挫折 |
| 整句解释 | 尽管遭遇挫折，她仍坚持不懈，最终扭转了局势，使之对自己有利。 |
| 固定表达 | **turn the tide**：扭转局势。例：Their persistence helped turn the tide. |

简单句可以没有生词或固定表达，不强行凑数。已有收藏保留原分析，不会随提示词更新而改写。

## 开始使用

1. 从 [v0.10.0-beta.1 发布页](https://github.com/James-Yao-xj/SelectEnglish/releases/tag/v0.10.0-beta.1)下载 ZIP 与校验文件，解压后将 `SelectEnglish.app` 放入“应用程序”。先退出旧副本，统一从 `/Applications/SelectEnglish.app` 启动。
2. 在菜单栏“译”的使用帮助中，按指引授予“辅助功能”和“输入监控”权限。输入监控只观察鼠标和触控板手势，不监听全局键盘。
3. 打开“AI 设置”，填写完整 HTTPS `/chat/completions` 接口地址、模型和密钥。
4. 在 TextEdit 或浏览器中选中一句愿意发送给该服务的英文，用力点按触控板。

**当前为早期公开测试版，采用临时签名，尚未完成 Apple 公证，下载后可能被 macOS 拦截。** 遇到拦截时可等待正式签名版本，或具备开发经验时从源码构建；不要关闭 Gatekeeper 或移除隔离标记。授权、系统词典冲突及排错步骤见[安装指南](docs/INSTALL.md)。

安装包包含 Apple 芯片和 Intel 两种架构，需要支持 Force Touch 的触控板。macOS 13.0 是编译部署下限；最低系统实际运行、Intel 触控板及另一台 Mac 的全新安装仍待验证。具体证据与待办见[发布验收记录](docs/RELEASE-CHECKLIST.md)。

## 隐私与数据

**保存有效配置后，重按会自动把选中文字发送到你指定的 AI 服务，可能产生该服务的费用。** 未配置时不发送。第三方如何保留或使用数据，取决于该服务的政策。

应用没有开发者运营的中转服务器、遥测或自动崩溃上传。默认通过辅助功能取词，不使用剪贴板；候选版可自行开启浏览器复制兼容，会向重按时的原浏览器发送 ⌘C，并临时备份、清空和读取剪贴板，再尝试恢复。剪贴板管理器可能记录这些内容，详见[隐私说明](PRIVACY.md)。分析结果不会自动保存为历史记录，只有点击“收藏”才写入本机。

API 密钥以**明文**保存在本机用户私有文件，通过本机文件权限限制访问，未使用加密存储。密钥与收藏均位于 `~/Library/Application Support/SelectEnglish/`，与项目仓库分离。完整数据流、删除和权限说明见[隐私说明](PRIVACY.md)。

## 开发与贡献

原生 Swift / AppKit 实现，需要 Xcode Command Line Tools。

```sh
bash Probe/test.sh
bash Probe/build.sh
open .build/probe/SelectEnglish.app
```

离线测试使用模拟 HTTP、假密钥和临时文件；CI 覆盖 Apple 芯片与 Intel 宿主的回归测试及双架构构建。它们不替代实际触控板、第三方 AI 和全新机器安装测试。

- [贡献指南](CONTRIBUTING.md)：开发环境、代码边界与验证方式
- [发布流程](docs/DISTRIBUTION.md)：打包、签名与公证
- [六级筛选评估](docs/evaluation/README.md)：公开样例与人工评估规则
- [安全反馈](SECURITY.md)：如何报告问题并保护凭据与私人文本

项目采用 [MIT 许可证](LICENSE)。
