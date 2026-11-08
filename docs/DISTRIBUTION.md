# 开发者发布流程

当前没有 Developer ID 证书或公证账号，正式分发验收未完成。临时签名测试包只能明确标为 prerelease。不要用发布脚本成功代替另一台 Mac 的下载、启动、授权与物理重按验收。

## 本地构建与测试包

```sh
bash Probe/test.sh
bash Probe/build.sh
bash Probe/release.sh --beta
```

`build.sh` 默认运行离线测试，输出 `.build/probe/SelectEnglish.app`，包含 arm64 和 x86_64 两种架构，部署目标 macOS 13.0。`--unsigned` 只编译供发行脚本签名，`--skip-tests` 仅用于已经完成验证的本地迭代，发布验收不应跳过测试。

测试包输出 `.build/releases/SelectEnglish-v0.10.0-beta.1.zip` 和 `.zip.sha256`。打包资源含 LICENSE 与 PRIVACY.md，不包含 Application Support、偏好设置、密钥或收藏。上传前核对 ZIP 内只有预期应用内容、架构和签名，并检查待发布文件没有凭据。

只有本次发布命令成功退出后，才能发布其产物。失败时可能仍保留此前同版本的 ZIP 和校验文件；文件存在不代表本次构建或公证通过，不应将旧文件作为本次验收证据。

## 正式签名与公证

维护者需先自行开通 Apple Developer 账号，在钥匙串安装有效的 **Developer ID Application** 签名证书及对应私钥，并通过 `notarytool store-credentials` 交互方式保存可用凭据配置。不要把账号密码、证书私钥或 App Store Connect API 私钥提交到仓库或聊天。账号开通、付费或协议接受由账号所有者操作。

正式流程读取非秘密的证书名和凭据配置名：

```sh
SIGNING_IDENTITY='Developer ID Application: your exact certificate name' NOTARY_PROFILE='your-existing-notarytool-profile' bash Probe/release.sh --formal
```

正式模式缺少凭据或任何签名、公证检查失败都必须停止，不得降级为临时签名继续发布。流程包括 Universal 编译、Hardened Runtime 与安全时间戳签名、提交 Apple 并确认 Accepted、附加公证票据、验证票据与 Gatekeeper、最后重新生成 ZIP 和 SHA256。签名后不得修改应用或再次编译；修改后必须重新完成流程。最终发布仍取决于[实机验收](RELEASE-CHECKLIST.md)。

只有这些外部门槛实际通过后，才取消测试版标记并向普通用户推广。需要支持 Intel 不只要有 Intel 切片，还要有实际 Intel/Force Touch 机器验证。

## 发布记录

记录源提交、版本/build、Xcode/Swift/macOS、架构、签名模式、公证提交及 Accepted 状态、最终 SHA256、干净机器测试结果和已知限制。正式公证前，本项目不宣称 Gatekeeper 下载启动已通过。GitHub CI 不接触发行私钥、不自动上传未经审核的正式包。

参考：[Apple 分发](https://developer.apple.com/macos/distribution/)、[公证](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)、[打包](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution)、[GitHub macOS runner](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)。
