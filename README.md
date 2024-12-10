# SDCP 3D打印机控制应用

基于SDCP(Smart Device Control Protocol)协议开发的iOS应用，用于控制和监控3D打印机。

## 功能特性

### 1. 设备发现与连接
- UDP广播自动发现设备
- WebSocket实时连接
- 设备状态管理
- 心跳保活机制

### 2. 设备信息管理
- 基本信息显示(设备名称、型号、版本等)
- 实时状态监控
  - 打印状态
  - 温度监控
  - 设备自检状态
  - 错误状态
- 设备配置管理

### 3. 打印任务控制
- 打印状态实时监控
  - 当前层数/总层数
  - 打印时间
  - 打印进度
- 打印控制功能
  - 开始打印
  - 暂停打印
  - 停止打印
- 错误处理与提示

### 4. 文件管理
- 支持分片上传文件
- 文件列表管理
- MD5文件完整性校验
- 支持CTB格式文件

### 5. 视频监控
- RTSP视频流实时显示
- 延时摄影控制
- 视频流连接管理

### 6. 系统监控
- 温度监控(UVLED、箱体)
- 设备状态监控
- 故障报警
- 系统通知

## 技术架构

### 网络通信
- UDP广播(端口3000)
- WebSocket连接(端口3030)
- HTTP文件传输服务
- RTSP视频流

### 数据格式
- JSON消息格式
- 二进制文件传输
- RTSP视频流

## 开发环境要求

- Xcode 14.0+
- iOS 13.0+
- Swift 5.0+

## 项目结构

```
SDCP/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Network/
│   ├── WebSocketManager.swift
│   ├── UDPDiscovery.swift
│   ├── HTTPFileUploader.swift
│   └── RTSPPlayer.swift
├── Models/
│   ├── PrinterDevice.swift
│   ├── PrintStatus.swift
│   └── FileManager.swift
├── ViewControllers/
│   ├── DeviceListViewController.swift
│   ├── PrintControlViewController.swift
│   ├── FileManagerViewController.swift
│   └── MonitorViewController.swift
├── Views/
│   ├── StatusView.swift
│   ├── ControlPanel.swift
│   └── VideoPlayerView.swift
└── Utils/
    ├── Constants.swift
    └── Extensions.swift
```

## 安装说明

1. 克隆项目到本地
```bash
git clone https://github.com/yourusername/SDCP.git
```

2. 安装依赖
```bash
pod install
```

3. 打开工程文件
```bash
open SDCP.xcworkspace
```

## 使用说明

1. 启动应用后，会自动搜索局域网内的3D打印机设备
2. 选择要连接的设备，建立WebSocket连���
3. 连接成功后可以进行以下操作：
   - 查看设备状态
   - 上传打印文件
   - 控制打印任务
   - 查看实时视频监控
   - 监控温度等系统状态

## 注意事项

1. 确保设备和手机在同一局域网内
2. 文件上传时注意检查文件格式是否支持
3. 视频监控功能需要设备支持RTSP协议
4. 建议在稳定的网络环境下使用

## 贡献指南

欢迎提交问题和改进建议。如果您想贡献代码：

1. Fork 项目
2. 创建新的分支
3. 提交更改
4. 发起 Pull Request

## 许可证

[MIT License](LICENSE)

## 联系方式

- 邮箱：support@example.com
- 网站：www.example.com

## 版本历史

- v1.0.0 (2024-03-20)
  - 初始版本发布
  - 实现基本功能 