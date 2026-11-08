# SelectEnglish

MacBook 菜单栏英语阅读工具：选中英文 → 触控板用力点按 → 牛皮纸小浮窗展示生词、整句解释、固定表达。支持自定义地址、模型和密钥的 OpenAI 兼容接口，结果可手动收藏。

**当前为早期公开测试版。** 本轮候选版本为 [v0.10.0-beta.1](https://github.com/James-Yao-xj/SelectEnglish/releases/tag/v0.10.0-beta.1)，以发布页实际状态为准。尚未取得 Developer ID 证书或完成 Apple 公证；不承诺普通用户下载后能直接打开。旧发布版本也不能视为已完成正式分发验收。

## 安装和首次使用

测试包为 `SelectEnglish-v0.10.0-beta.1.zip`，包含 Apple 芯片和 Intel 两种架构。构建目标为 macOS 13.0 及以上；最低版本实际运行、其他 Mac 的全新安装及 Intel 触控板取词仍待验证，详见[验收记录](docs/RELEASE-CHECKLIST.md)。需要支持 Force Touch 的触控板；图片文字、扫描 PDF 不支持。

1. 从上述发布页下载 ZIP 和 SHA256 文件，校验后解压，将 `SelectEnglish.app` 放入“应用程序”。统一从 `/Applications/SelectEnglish.app` 运行，先退出其他副本。
2. 测试包采用临时签名，可能被 macOS 拦截。遇到拦截时请等待正式签名版本，或具备开发经验时[自行构建](CONTRIBUTING.md)；不要关闭 Gatekeeper 或移除隔离标记。
3. 启动后菜单栏出现“译”。未配置的新用户会看到首次使用指引，也可从菜单重新打开。按指引在系统设置中授权“辅助功能”和“输入监控”；后者仅用于观察鼠标及触控板，不监听全局键盘。
4. 打开“AI 设置”，填写完整 HTTPS `/chat/completions` 地址、模型名和 API 密钥。**配置后重按会自动将选中文字发送至该服务**，可能产生该服务的费用；未配置不会发送。
5. 在 TextEdit 或网页选中愿意发送的一句英文，再用力点按。点击浮层外部、Esc 或关闭按钮可取消并关闭。菜单中可查看设置、收藏和触发状态。

更多见[安装与排错](docs/INSTALL.md)。临时签名更新后可能需要重新授权同一个应用。升级只替换应用，保留本机配置和收藏；无需每次重新输入本地密钥。

## 学习内容

生词 → 整句解释 → 固定表达。整句生词筛选面向六级阅读水平：优先六级及以上、专业词和熟词的少见语境义，略过基础高频词，最多 8 个且不凑数；单独选中一个词时始终解释该词。难度由 AI 根据语境估计，未接入官方词表，不能保证官方词表归属。固定表达最多 5 个，没有则明确说明。已有收藏不会重新分析。

接口最长接受 20,000 字符，超时 60 秒；完整结果生成后显示，速度取决于网络、模型和服务负载。官方 DeepSeek 指定模型使用关闭深度思考的请求；其他自定义服务不附加厂商参数。同一次运行可复用最近一次相同原文、接口及模型的成功结果，“重试”始终重新请求。

## 数据和隐私

没有开发者运营的中转服务器、遥测或自动崩溃上传；应用不读取剪贴板，不做 OCR。自动分析不保存为历史记录，点击“收藏”才保存原文和结果。API 密钥按用户选择以明文保存在本机私有文件，**不是加密保险箱**。

- 密钥：`~/Library/Application Support/SelectEnglish/Private/api-key`（目录 0700、文件 0600）。
- 收藏：`~/Library/Application Support/SelectEnglish/notebook.json`。
- 接口、模型等偏好：macOS 用户偏好设置。

第三方 AI 的保留和训练政策由该服务决定。详细的数据流、删除及权限说明见[隐私说明](PRIVACY.md)。不要把密钥或私人选区放进 GitHub Issue。

## 开发与验证

```sh
bash Probe/test.sh
bash Probe/build.sh
open .build/probe/SelectEnglish.app
```

需要 Xcode Command Line Tools。构建包含双架构编译；离线测试使用假密钥、模拟 HTTP 和临时文件。CI 测试通过不代表真实 Force Click、第三方服务质量或其他机器的 Gatekeeper 安装通过。已有单机 TextEdit/Chrome 重按和真实服务测试来自历史版本，不能替代新版本全量验收。

- [贡献与构建](CONTRIBUTING.md) · [发布流程](docs/DISTRIBUTION.md)
- [发布验收与待办](docs/RELEASE-CHECKLIST.md) · [六级筛选评估](docs/evaluation/README.md)
- [安全反馈](SECURITY.md) · [MIT 许可证](LICENSE)

项目开发记录遵循 `AGENTS.md` 和 `.trellis/workflow.md`。
