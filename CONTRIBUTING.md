# 贡献指南

提交前先阅读 `AGENTS.md`、`.trellis/workflow.md` 和 `.trellis/spec/macos/index.md`。请以一个明确问题为范围，附可复现步骤和相关验证。

## 环境和构建

需要 macOS 与 Xcode Command Line Tools。双架构目标为 arm64、x86_64，最低部署版本为 macOS 13.0；编译成功不代表在最低版本或 Intel 触控板上完成实际验证。

```sh
bash Probe/test.sh
bash Probe/build.sh
open .build/probe/SelectEnglish.app
```

开发构建临时签名，与已安装应用使用同一 bundle ID。不要同时启动多个副本，也不要为了文档改动重装或清除现有授权。应用内部的 `Probe` 命名属于历史兼容身份，不要随意更换。

测试使用模拟 HTTP、假凭据和临时目录，禁止读取真实 API 密钥或上传用户数据。真实服务测试必须明确选择公开样例并由使用者配置凭据；它与离线测试、硬件重按测试各自独立。

## 代码边界

AppKit 呈现和控制器在 `Probe/Sources/`。保留选区读取、触发检测、AI 请求和本机持久化之间的边界；网络或辅助功能读取不可放进事件回调。保留取消和过期结果保护，不扩大监听范围。不得提交真实凭据、偏好设置或收藏。

提交修改时说明触发条件、结果变化和测试依据。CI 在两种架构宿主上运行离线验证；真实新机器安装流程按[发布验收表](docs/RELEASE-CHECKLIST.md)单独记录。

源码采用 [MIT](LICENSE)。提交贡献前应确认你有权提供相关代码和素材；依赖或外部素材另需保留其许可。
