# mobile_codex_helper_for_mac

[English](README.md) | [中文](README.zh-CN.md)

把你 Mac 上本地运行的 Codex 会话，变成一个可以在手机上访问和继续控制的私有网页面板。

## 项目来源

这个仓库基于原始项目 [StarsTom/mobileCodexHelper](https://github.com/StarsTom/mobileCodexHelper)。

原项目已经完成了最核心的设计：

- 给本地 Codex 会话提供一个适合手机查看的 Web 面板
- 新设备第一次登录时必须经过电脑端批准
- 推荐走 Tailscale 之类的私有网络，而不是直接公网暴露
- 用“单用户、受限、可审批”的方式控制本机 Codex，而不是做成高风险开放服务

不过原项目主要面向 Windows。

这个 fork 保留了它原本的整体架构和安全思路，在这个基础上补上了 macOS 可用的部署和运维链路。

## 我们在原项目之上做了什么

这个 fork 目前主要增加了下面这些内容：

- 一套 macOS 可直接运行的 `sh` 脚本：初始化、启动、停止、环境检查、远程发布
- 本地运行时自动引导：如果系统里没有 Node.js 22 或 Caddy，会下载到仓库内使用
- macOS 下用 Caddy 取代原 Windows 方案里的 nginx 打包路径
- 桌面控制工具改成跨平台可运行，能在 macOS 上查看状态和执行启停
- 默认关闭 WebSocket query-string token 回退，降低代理日志把 token 落盘的风险
- 把认证数据库和运行时更明确地固定在工作区内，方便受限环境运行
- 增加可关闭项目 watcher 的开关，避免某些 macOS / 沙盒环境里触发文件句柄上限

## 这个项目能做什么

- 在手机浏览器里查看 Codex 项目、会话和消息
- 在手机上继续发提示词，让 Mac 上的 Codex 接着执行
- 新设备首次登录时，必须在电脑端批准
- 让手机端聚焦在“查看 + 对话控制”，而不是开放成完整远程桌面或通用执行平台

## 推荐工作方式

```text
手机浏览器
   ↓
Tailscale 私网 HTTPS
   ↓
本地反向代理（macOS 下默认是 Caddy）
   ↓
带有本 fork 补丁的本地 claudecodeui
   ↓
Mac 上的 Codex 会话
```

## 界面预览

下面这张图来自原项目的桌面控制台思路。  
这个 fork 延续了同样的操作模型，只是把它做成了适合 macOS 的版本。

![移动 Codex 控制台预览](docs/assets/mobile-codex-control-console.png)

## macOS 快速开始

1. 克隆这个仓库
2. 运行 `./scripts/setup-upstream-mac.sh`
3. 运行 `./scripts/check-mobile-codex-runtime.sh`
4. 运行 `./scripts/start-mobile-codex-stack.sh`
5. 打开 `http://127.0.0.1:8080`
6. 在浏览器里完成第一次注册
7. 如需桌面控制台，可运行 `python3 mobile_codex_control.py`
8. 如果你使用 Tailscale，在 Mac 和手机都加入同一个 tailnet 后，再运行 `./scripts/enable-mobile-codex-remote.sh`

## 文档入口

- macOS 英文部署指南：[docs/MACOS.md](docs/MACOS.md)
- macOS 中文部署指南：[docs/MACOS.zh-CN.md](docs/MACOS.zh-CN.md)
- 保留的原始 Windows 部署文档：[docs/DEPLOYMENT.zh-CN.md](docs/DEPLOYMENT.zh-CN.md)
- 原项目仓库：[StarsTom/mobileCodexHelper](https://github.com/StarsTom/mobileCodexHelper)

## 安全说明

虽然这个 fork 现在能在 macOS 上跑，但安全边界并没有改变：

- 服务应尽量只在本机监听
- 远程访问优先走 Tailscale 之类的私有网络
- 新设备第一次登录必须走电脑端审批
- 不建议直接公网暴露

## 当前 fork 的范围

这个 fork 现在聚焦在“让原项目在 macOS 上真正可用”。  
它并不打算把项目改造成多用户托管平台，也不打算把它扩展成通用远程执行服务。
