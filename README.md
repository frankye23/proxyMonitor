# ProxyGlass

macOS 菜单栏代理监控工具，基于 Liquid Glass 设计语言，帮助你快速判断代理是否生效。

<!-- TODO: 添加截图 -->
<!-- ![ProxyGlass Screenshot](docs/screenshot.png) -->

## 功能

- **实时状态检测** — 自动识别系统代理（HTTP/SOCKS5/Shadowsocks/V2Ray/Clash/Surge）和 VPN 连接
- **流量可视化** — 通过 Clash/Surge API 获取实时流量分布，区分代理、直连和未知流量
- **出口 IP 与地理位置** — 检测出口 IP，自动解析地理位置
- **延迟探测** — 本地代理延迟 + 出口节点延迟
- **DNS 泄漏检测** — 验证 DNS 请求是否通过代理
- **IPv6 泄漏检测** — 检查 IPv6 流量是否暴露
- **活跃连接概览** — 显示 Top 连接的服务名、路由方式和实时速率
- **Liquid Glass 界面** — macOS 26 原生玻璃效果，菜单栏一键查看

## 系统要求

- macOS 26 (Tahoe) 或更高版本
- Xcode 26+
- Swift 6.0

## 构建

```bash
# 克隆仓库
git clone https://github.com/frankye23/proxyMonitor.git
cd ProxyGlass

# 使用构建脚本
./scripts/build-and-run.sh

# 或手动构建
xcodebuild -scheme ProxyGlass -configuration Release -derivedDataPath build build
open build/Build/Products/Release/ProxyGlass.app
```

## 使用

1. 启动 ProxyGlass 后，菜单栏会出现状态图标
2. 点击图标查看代理状态面板
3. 状态说明：
   - **全部代理** (绿色) — 所有活跃流量均通过代理
   - **混合流量** (黄色) — 部分流量走了直连
   - **全部直连** (红色) — 流量未经过代理
   - **无活动流量** — 当前无活跃连接

### Clash/Surge API（可选）

开启 Clash 或 Surge 的 RESTful API 后，ProxyGlass 可获取更详细的流量数据，包括实时速率、流量占比和活跃连接列表。

在设置中配置 API 地址即可启用。

## 项目结构

```
ProxyGlass/
├── App/              # 应用入口与配置
├── Models/           # 数据模型
├── ViewModel/        # 视图模型
├── Services/
│   ├── Network/      # 网络监测、延迟探测、地理定位
│   ├── Proxy/        # 代理检测（系统代理、VPN、Clash/Surge API）
│   ├── Security/     # DNS/IPv6 泄漏检测
│   └── Traffic/      # 流量聚合
└── UI/
    ├── Components/   # 通用 UI 组件
    ├── MenuBar/      # 菜单栏图标与弹窗
    ├── Panel/        # 状态面板
    └── Settings/     # 设置界面
```

## 技术栈

- Swift 6 + SwiftUI
- Liquid Glass (NSGlassEffectView)
- MVVM + @Observable
- AppKit 集成（NSStatusItem / NSPopover）

## License

[MIT](LICENSE)
