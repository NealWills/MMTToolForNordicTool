# MMTToolForNordicTool

[![CI Status](https://img.shields.io/travis/NealWills/MMTToolForNordicTool.svg?style=flat)](https://travis-ci.org/NealWills/MMTToolForNordicTool)
[![Version](https://img.shields.io/cocoapods/v/MMTToolForNordicTool.svg?style=flat)](https://cocoapods.org/pods/MMTToolForNordicTool)
[![License](https://img.shields.io/cocoapods/l/MMTToolForNordicTool.svg?style=flat)](https://cocoapods.org/pods/MMTToolForNordicTool)
[![Platform](https://img.shields.io/cocoapods/p/MMTToolForNordicTool.svg?style=flat)](https://cocoapods.org/pods/MMTToolForNordicTool)

## 简介

MMTToolForNordicTool 是一个用于 Nordic 芯片设备的蓝牙工具库，提供了设备扫描、连接、DFU 升级等功能。示例项目演示了完整的蓝牙设备管理流程。

## 功能特性

### 核心功能

- ✅ **蓝牙设备扫描**
  - 扫描周边 BLE 设备
  - 从广播数据提取设备名称、MAC 地址
  - RSSI 信号强度实时显示
  - 自动按信号强度排序

- ✅ **智能设备管理**
  - MAC 地址去重（保留信号最强的设备）
  - 设备信息卡片展示
  - 连接状态实时更新

- ✅ **设备连接**
  - 一键连接/断开
  - 自动扫描服务和特性
  - 特性属性解析（Read/Write/Notify 等）

- ✅ **指令日志**
  - 实时操作日志记录
  - 时间戳标记
  - 支持清除日志

- ✅ **DFU 升级（预留）**
  - Nordic DFU 升级支持
  - 进度回调
  - 错误处理

### UI 特性

- 🎨 **暗黑模式完美适配**
  - 自动适配系统外观模式
  - 语义化颜色使用

- 📱 **现代化界面**
  - 卡片式设计
  - 圆角按钮和容器
  - 响应式布局

## 示例项目

### 运行示例

要运行示例项目，请执行以下步骤：

1. 克隆仓库
```bash
git clone https://github.com/NealWills/MMTToolForNordicTool.git
```

2. 进入 Example 目录
```bash
cd MMTToolForNordicTool/Example
```

3. 安装依赖
```bash
pod install
```

4. 打开 `MMTToolForNordicTool.xcworkspace` 运行项目

### 使用说明

#### 1. 扫描设备

点击"开始扫描"按钮，将自动扫描周边的蓝牙设备。设备列表会按 RSSI 信号强度从高到低排序。

#### 2. 选择设备

从列表中点击选择要连接的设备，设备信息卡片会显示选中设备的详细信息：
- 设备名称
- MAC 地址
- Extra 数据（如有）
- 连接状态

#### 3. 连接设备

点击"连接设备"按钮连接选中的设备。连接成功后：
- 按钮变为"断开连接"（红色）
- 自动扫描设备的服务和特性
- 日志区域显示扫描进度

#### 4. 查看日志

所有操作都会记录在指令日志区域，包括：
- 扫描开始/停止
- 设备连接/断开
- 服务扫描进度
- 特性发现记录

## 技术实现

### 设备信息提取

```swift
// 从广播数据提取设备名称（优先使用 kCBAdvDataLocalName）
let peripheralName = advertisementData["kCBAdvDataLocalName"] as? String ?? peripheral.name ?? ""

// 从厂商数据提取 MAC 地址
if let macData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
    let macList = macData.map({ String(format: "%02x", $0).uppercased() })
    let mac = macList[0..<6].joined(separator: ":")
}
```

### RSSI 信号强度指示

| RSSI 范围 | 颜色 | 信号强度 |
|-----------|------|---------|
| ≥ -60 dBm | 🟢 绿色 | 强 |
| -60 ~ -80 dBm | 🟠 橙色 | 中 |
| < -80 dBm | 🔴 红色 | 弱 |

### 服务特性扫描

连接成功后自动扫描所有服务和特性，并解析特性属性：
- Read - 可读
- Write - 可写
- WriteWithoutResponse - 无响应写入
- Notify - 通知
- Indicate - 指示
- Broadcast - 广播

## 系统要求

- iOS 12.0+
- Xcode 12.0+
- Swift 5.0+

## 安装

MMTToolForNordicTool 可通过 [CocoaPods](https://cocoapods.org) 安装。只需在 Podfile 中添加：

```ruby
pod 'MMTToolForNordicTool'
```

## 权限配置

在 `Info.plist` 中添加以下权限：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限来扫描和连接设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙权限来与设备通信</string>
```

## 项目结构

```
MMTToolForNordicTool/
├── Example/
│   └── MMTToolForNordicTool/
│       ├── ViewController.swift       # 示例主视图控制器
│       └── AppDelegate.swift          # 应用委托
├── MMTToolForNordicTool/
│   ├── Classes/                       # 核心功能类
│   └── MMTToolForNordicTool.h         # 主头文件
├── LICENSE
└── README.md
```

## 更新日志

### Version 1.0.0
- 实现蓝牙设备扫描功能
- 实现设备连接和断开
- 实现 MAC 地址提取和去重
- 实现 RSSI 信号强度排序
- 实现服务和特性扫描
- 实现指令日志记录
- 支持暗黑模式
- 预留 DFU 升级接口

## 作者

NealWills, Donghn@maxeye.com

## 许可证

MMTToolForNordicTool 基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。
