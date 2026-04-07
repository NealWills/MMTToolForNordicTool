# MMTToolForNordicTool 日志系统

## 概述

重构后的日志系统提供了统一的、功能完善的日志框架，支持多种输出方式和灵活的配置。

## 特性

- ✅ **分级日志** - 支持 Error, Warning, Info, Debug, Verbose 五个级别
- ✅ **多种输出** - 控制台、文件、自定义处理器
- ✅ **日志缓存** - 内存缓存日志，方便查看历史
- ✅ **颜色输出** - 控制台支持颜色区分
- ✅ **日志过滤** - 根据级别过滤日志
- ✅ **线程安全** - 支持多线程日志记录
- ✅ **易于使用** - 提供便捷的全局函数

## 快速开始

### 1. 基本配置

```swift
// 在 AppDelegate 或 viewDidLoad 中配置
MMTToolForNordicLog.configure { config in
    config.minimumLevel = .debug      // 最低日志级别
    config.enableConsole = true       // 启用控制台输出
    config.cacheEnabled = true        // 启用日志缓存
    config.cacheLimit = 500           // 缓存数量限制
    config.enableColors = true        // 启用颜色输出
}
```

### 2. 记录日志

```swift
// 方式1: 使用全局函数（推荐）
MMTLogError("这是一个错误")
MMTLogWarning("这是一个警告")
MMTLogInfo("这是一条信息")
MMTLogDebug("这是调试信息")
MMTLogVerbose("这是详细信息")

// 方式2: 使用 MMTToolForNordicLog 类
MMTToolForNordicLog.log("消息", level: .info)

// 方式3: 使用枚举方式（兼容旧代码）
MMTNordicLog.info.log("消息")
```

### 3. 自定义处理器

```swift
// 设置自定义处理器，例如输出到 UI
MMTToolForNordicLog.setCustomHandler { entry in
    print(entry.formattedMessage)
}
```

## 日志级别

| 级别 | 图标 | 用途 | 颜色 |
|------|------|------|------|
| `.error` | ❌ | 错误信息 | 红色 |
| `.warning` | ⚠️ | 警告信息 | 黄色 |
| `.info` | ℹ️ | 一般信息 | 青色 |
| `.debug` | 🔍 | 调试信息 | 绿色 |
| `.verbose` | 📝 | 详细信息 | 白色 |

## 日志格式

### 完整格式
```
[HH:mm:ss.SSS] [图标] [级别] [文件名:行号] 消息
```

### 简化格式
```
[HH:mm:ss.SSS] [图标] 消息
```

### 示例输出

```
[20:14:32.123] ❌ [ERROR] [DFUServiceInitiator.swift:450] Connection failed
[20:14:32.456] ⚠️ [WARN] [BluetoothManager.swift:123] Device timeout
[20:14:33.789] ℹ️ [INFO] [ViewController.swift:89] 开始扫描设备
[20:14:34.012] 🔍 [DEBUG] [DeviceScanner.swift:45] 找到设备: Nordic_123
[20:14:34.345] 📝 [VERBOSE] [PacketParser.swift:67] 解析数据包: 0x01 0x02 0x03
```

## 高级功能

### 1. 日志缓存

```swift
// 获取所有缓存的日志
let logs = MMTToolForNordicLog.getCachedLogs()

// 获取缓存的日志字符串
let logStrings = MMTToolForNordicLog.getCachedLogStrings()

// 清空缓存
MMTToolForNordicLog.clearCache()
```

### 2. 日志文件

```swift
// 配置日志文件
MMTToolForNordicLog.configure { config in
    config.enableFile = true
    config.logFilePath = "/path/to/log.txt"
    config.maxFileSize = 10 * 1024 * 1024  // 10MB
}

// 导出日志到文件
MMTToolForNordicLog.exportLogs(to: "/path/to/export.txt")
```

### 3. 日志过滤

```swift
// 只记录 Warning 及以上级别的日志
MMTToolForNordicLog.setMinimumLevel(.warning)
```

## 在 DFU 中的使用

### 自动日志捕获

日志系统已集成到 DFU 流程中，所有 DFU 相关的日志会自动输出：

```swift
// 在 ViewController 中配置
private func setupLogger() {
    MMTToolForNordicLog.configure { config in
        config.minimumLevel = .debug
        config.enableConsole = true
        config.cacheEnabled = true
    }
    
    // 将日志输出到 UI
    MMTToolForNordicLog.setCustomHandler { [weak self] entry in
        self?.addLogToUI(entry.simplifiedMessage)
    }
}
```

### DFU 流程日志示例

```
[20:14:32.123] ℹ️ 开始 DFU 升级
[20:14:32.456] ℹ️ 设备: NordicDevice
[20:14:32.789] ℹ️ MAC: XX:XX:XX:XX:XX:XX
[20:14:33.012] ℹ️ 文件: firmware.zip
[20:14:33.345] 🔍 DFU step01 [0x44, 0x4f, 0x4f, 0x47] send
[20:14:33.678] 🔍 DFU step01 device scan success
[20:14:34.901] 🔍 DFU step02 start DFU selector
[20:14:35.234] ℹ️ DFU State: Connecting
[20:14:35.567] ℹ️ DFU State: Uploading
[20:14:36.890] ℹ️ DFU 进度: 50%
[20:14:37.123] ✅ DFU 完成，进度: 100%
```

## 最佳实践

### 1. 使用合适的日志级别

```swift
// ❌ 不推荐
MMTLogInfo("连接失败")  // 应该用 Error

// ✅ 推荐
MMTLogError("连接失败: \(error.localizedDescription)")
```

### 2. 提供上下文信息

```swift
// ❌ 不推荐
MMTLogDebug("扫描设备")

// ✅ 推荐
MMTLogDebug("扫描设备: 发现 \(devices.count) 个设备")
```

### 3. 在 Release 版本调整日志级别

```swift
#if DEBUG
    config.minimumLevel = .debug
#else
    config.minimumLevel = .warning
#endif
```

## API 参考

### MMTToolForNordicLog

```swift
// 配置
class func configure(_ block: (MMTLogConfiguration) -> Void)

// 日志记录
class func log(_ message: Any?, level: MMTLogLevel, file: String, line: Int, function: String)

// 自定义处理器
class func setCustomHandler(_ handler: @escaping (MMTLogEntry) -> Void)

// 日志级别
class func setMinimumLevel(_ level: MMTLogLevel)

// 缓存管理
class func getCachedLogs() -> [MMTLogEntry]
class func getCachedLogStrings() -> [String]
class func clearCache()

// 导出
class func exportLogs(to path: String) -> Bool
```

### 全局函数

```swift
MMTLogError(_ message: Any?)
MMTLogWarning(_ message: Any?)
MMTLogInfo(_ message: Any?)
MMTLogDebug(_ message: Any?)
MMTLogVerbose(_ message: Any?)
```

## 迁移指南

### 从旧 API 迁移

```swift
// 旧代码
MMTToolForNordicLog.log("消息", level: .info)

// 新代码（推荐）
MMTLogInfo("消息")

// 或者（兼容）
MMTToolForNordicLog.log("消息", level: .info)
```

## 故障排除

### 日志不显示

1. 检查是否调用了 `setupLogger()`
2. 确认 `minimumLevel` 设置正确
3. 确保 `enableConsole` 或 `customHandler` 已配置

### 日志丢失

1. 检查 `cacheLimit` 设置
2. 使用 `exportLogs()` 导出日志

### 性能问题

1. 在 Release 版本提高 `minimumLevel`
2. 减少 `cacheLimit`
3. 禁用 `enableFile`
