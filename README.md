<div align=center>
<img src="icon.png" style="width:100px;" width="100"/>
<h2>LightingSend 雷霆送</h2>
</div>

### 一、产品概述

- 安全的、开源免费的局域网文件传输工具，让同一网络内的设备免流量互传文件、目录与文本。
- 基于 LocalSend Protocol v2 与 HTTPS 加密，TLS 证书在每台设备本地即时生成，数据只在局域网内流动，不经过任何第三方服务器。
- 支持 Windows、macOS、Linux、Android 与 iOS 等主流平台，桌面端、移动端与命令行客户端体验一致。

核心价值：

- 零账号、零云端中转，传输全程只在本地网络完成。
- 桌面端、移动端与命令行客户端共享同一套传输协议与加密模型。
- 一条发布流水线产出全平台、多架构安装包，用户下载即可使用。
- 保持协议兼容，继续跟随 LocalSend Protocol v2 演进。

### 二、功能说明

#### 设备发现

- 通过局域网自动发现附近设备，支持设备别名、IP 直连与手动发送，离线也能定位目标设备。

#### 安全传输

- 设备间通信使用 REST API 与 HTTPS 加密，TLS 证书在每台设备上即时生成，最大程度保护传输内容。

#### 文件与文本互传

- 支持发送文件、目录与剪贴板文本，接收端可查看发送进度、接收记录与历史消息。

#### 跨平台客户端

- 桌面端支持系统托盘、后台接收、开机自启与接收目录设置；移动端支持系统分享菜单集成。

#### 命令行客户端

- `lightingsend-cli send` 可从终端直接发送文件，支持交互式设备选择或 `--to` 指定别名 / IP。

### 三、安装与下载

从 [Releases](https://github.com/Mutantcat-Working-Group/LightningSend/releases) 下载对应平台的安装包，双击即可直接使用；所有安装包由 GitHub Actions 在发布时自动构建，并附带 `checksums.txt`、`checksums-md5.txt`、`checksums-sha1.txt` 校验文件。

| 平台 | 架构 | 安装包格式 |
| --- | --- | --- |
| Windows | x86_64 / arm64 | NSIS `.exe` 安装程序、便携 `.zip` |
| macOS | Apple Silicon / Intel | `.dmg`（两个架构分别提供） |
| Linux | x86_64 / arm64 | `.AppImage`、`.deb`、`.tar.gz` |
| Android | arm32v7 / arm64v8 / x64 | `.apk` |
| CLI | Linux / Windows | 独立命令行二进制 |
| Server | Linux x86_64 / arm64 | `server` 二进制 `.tar.gz`、Docker 镜像 `.tar.gz` |

### 四、快速上手

1. 在发送端和接收端分别安装 LightingSend，并连接到同一个局域网。
2. 打开应用，选择文件、目录或剪贴板文本，等待对方设备出现在设备列表中。
3. 点击目标设备发送，对方确认后即开始传输；也可以扫描二维码快速配对。
4. 命令行方式：`lightingsend-cli send <文件或目录>`，交互选择目标设备；或使用 `lightingsend-cli send --to <别名或 IP> <文件>` 直接发送。

首次使用请保持发送端与接收端处于同一局域网；如设备无法发现，请检查路由器是否开启了 AP Isolation，并允许本应用的局域网通信权限。

### 五、设计原则

- 让局域网内的文件传输真正做到零服务器、零账号、零流量经过第三方。
- 让桌面端、移动端与命令行客户端共享同一套传输协议与加密模型。
- 让安装包在一条发布流水线上产出，覆盖主流平台与架构，用户下载即可使用。

### 六、从源码构建

1. 安装 [Flutter](https://flutter.dev)（推荐配合 [fvm](https://fvm.app) 使用，版本要求见 [.fvmrc](.fvmrc)）。
2. 安装 [Rust](https://www.rust-lang.org/tools/install) 工具链。
3. 克隆仓库后进入 `app/` 目录，执行 `flutter pub get`。
4. 桌面端运行 `flutter run`；移动端按对应平台执行 `flutter build apk` / `flutter build ipa`。
5. CLI 在仓库根目录执行 `cargo build --release`，产物位于 `target/release/`。

### 七、致谢

- 本项目基于 LocalSend 二次开发，继续沿用 Apache-2.0 许可证开源，详见 [LICENSE](LICENSE)。
- 感谢 [localsend/localsend](https://github.com/localsend/localsend) 原仓库及其作者的优秀开源工作，本仓库在其基础上继续维护与改进。

### 八、开发进度

- [X] 跨平台桌面端与移动端客户端
- [X] HTTPS / 本地 TLS 加密传输与设备发现
- [X] 文件、目录、文本与剪贴板互传
- [X] 命令行客户端 `lightingsend-cli`
- [X] 多平台、多架构 CI 打包与 Release 发布流程
- [X] macOS DMG 双架构打包完善
- [X] Server / CLI 非桌面版打包与 Docker 镜像产物
- [ ] 自动更新通道
