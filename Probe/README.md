# SelectEnglish 原生应用

此目录保留历史名称 Probe，目前是完整菜单栏应用，会在配置服务后自动调用外部 AI，并非离线探针。项目使用和数据说明见[根目录 README](../README.md)及[隐私说明](../PRIVACY.md)。

```sh
bash Probe/test.sh
bash Probe/build.sh
open .build/probe/SelectEnglish.app
```

开发构建为双架构临时签名包，不是公证发行版。授权、真实硬件交付和服务质量需分别验证。日常使用仅运行 `/Applications/SelectEnglish.app` 一个副本。

## 本机选区诊断

打开“译 → 触发与选区状态”，在 TextEdit 选中公开例句，选择目标应用后点击“读取指定应用选区”。它只读取选区，不调用 AI；浮层“重试”或已配置后的物理重按会调用服务。原始事件计数、stage 2、完整选区与 AI 成功是不同证据，不能相互替代。

`Probe/Experiments/` 是单独的历史被动事件实验，只输出数字元数据。当前不再提供历史“5 秒后读取”控件。
