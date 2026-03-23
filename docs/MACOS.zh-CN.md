# macOS 部署指南

这份指南对应当前 fork 里的 macOS 版本。

这个 fork 基于原始项目 [StarsTom/mobileCodexHelper](https://github.com/StarsTom/mobileCodexHelper)，保留了它原本的手机控制面板、设备审批和私网优先思路，并在此基础上补上了 macOS 的运行链路。

它保留了参考项目最核心的能力：

- 手机浏览器查看 Codex 项目、会话和消息
- 从手机继续发送提示词，让电脑上的 Codex 继续工作
- 新设备首次登录时，必须在电脑端批准
- 电脑端可以查看本地服务、远程发布状态和设备白名单

和原始 Windows 版本相比，这个 macOS 版本有两处关键变化：

1. 启停脚本改成了 `sh`
2. 本地反向代理默认改为 Caddy，并关闭了默认的 WebSocket query token 回退

## 前提条件

建议准备：

- macOS
- Python 3.11+
- Git
- 已安装 Codex 桌面端或 CLI
- Tailscale

不强制预装：

- Node.js 22
- Caddy

如果系统里没有 Node 22 或 Caddy，脚本会自动下载到仓库内的 `.runtime/tools/`，不污染全局环境。

## 第一步：准备上游面板

在仓库根目录运行：

```bash
./scripts/setup-upstream-mac.sh
```

这个脚本会做 4 件事：

1. 克隆 `siteboon/claudecodeui` 的 `v1.25.2`
2. 应用本仓库的 override 层
3. 检查是否存在 Node.js 22，没有则下载本地运行时
4. 在上游目录执行 `npm install`

## 第二步：检查运行环境

```bash
./scripts/check-mobile-codex-runtime.sh
```

重点确认：

- `UpstreamExists = True`
- `Node` 有值
- `Python` 有值
- 如果要远程手机访问，`Tailscale` 最好也有值

## 第三步：启动整套服务

```bash
./scripts/start-mobile-codex-stack.sh
```

默认会启动：

- 应用服务：`127.0.0.1:3001`
- Caddy 反向代理：`127.0.0.1:8080`

## 第四步：启动桌面控制台

```bash
python3 mobile_codex_control.py
```

如果只想在终端看状态：

```bash
python3 mobile_codex_control.py --json
```

## 第五步：在电脑端完成首次注册

用桌面浏览器打开：

```text
http://127.0.0.1:8080
```

完成账号注册。第一台注册设备会自动加入白名单。

## 第六步：开启手机远程访问

确保：

- Mac 已登录 Tailscale
- 手机也登录到同一个 tailnet

然后运行：

```bash
./scripts/enable-mobile-codex-remote.sh
```

脚本会把 Tailscale Serve 指向本地反向代理 `127.0.0.1:8080`。

## 第七步：首次手机登录审批

当新手机第一次登录时：

1. 手机端会显示等待批准
2. 电脑端 `mobile_codex_control.py` 会出现待审批设备
3. 你核对设备信息
4. 在电脑端批准
5. 手机端继续登录

## 常用命令

启动：

```bash
./scripts/start-mobile-codex-stack.sh
```

停止：

```bash
./scripts/stop-mobile-codex-stack.sh
```

输出当前状态：

```bash
python3 mobile_codex_control.py --json
```

## 日志位置

- 应用 stdout：`tmp/logs/mobile-codex-app.stdout.log`
- 应用 stderr：`tmp/logs/mobile-codex-app.stderr.log`
- Caddy stdout：`tmp/logs/mobile-codex-caddy.stdout.log`
- Caddy stderr：`tmp/logs/mobile-codex-caddy.stderr.log`
- Caddy access：`.runtime/caddy/logs/mobile-codex.access.json`

## 安全说明

这个 macOS 版本默认关闭了 WebSocket query token 回退：

- 前端默认不再把 token 拼到 `/ws?token=...`
- 后端默认也不再接受 query token WebSocket 认证

这样做的原因是避免代理访问日志把 token 落盘。

如果你确实需要兼容某些异常 WebView，可以显式设置：

```bash
export ALLOW_QUERY_TOKEN_WS_FALLBACK=true
export VITE_ENABLE_QUERY_TOKEN_WS_FALLBACK=true
```

但只有在确定日志、代理和终端历史都可控时才建议这么做。
