//
//  MMTToolForNordicLog.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 07/04/2026.
//

import Foundation

// MARK: - 日志级别

/// 日志级别枚举
public enum MMTLogLevel: Int, Comparable {
    case error = 0     // 错误
    case warning = 1   // 警告
    case info = 2      // 信息
    case debug = 3     // 调试
    case verbose = 4   // 详细
    
    /// 级别名称
    public var name: String {
        switch self {
        case .error:    return "ERROR"
        case .warning:  return "WARN"
        case .info:     return "INFO"
        case .debug:    return "DEBUG"
        case .verbose:  return "VERBOSE"
        }
    }
    
    /// 级别图标
    public var emoji: String {
        switch self {
        case .error:    return "❌"
        case .warning:  return "⚠️"
        case .info:     return "ℹ️"
        case .debug:    return "🔍"
        case .verbose:  return "📝"
        }
    }
    
    /// 颜色代码（用于终端输出）
    public var colorCode: String {
        switch self {
        case .error:    return "\u{001B}[0;31m"    // 红色
        case .warning:  return "\u{001B}[0;33m"    // 黄色
        case .info:     return "\u{001B}[0;36m"    // 青色
        case .debug:    return "\u{001B}[0;32m"    // 绿色
        case .verbose:  return "\u{001B}[0;37m"    // 白色
        }
    }
    
    // Comparable 协议实现
    public static func < (lhs: MMTLogLevel, rhs: MMTLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - 日志条目

/// 日志条目结构
public struct MMTLogEntry {
    public let timestamp: Date
    public let level: MMTLogLevel
    public let message: String
    public let file: String
    public let line: Int
    public let function: String
    public let thread: String
    
    /// 格式化时间戳
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    /// 短文件名
    public var shortFileName: String {
        return (file as NSString).lastPathComponent
    }
    
    /// 格式化的日志字符串
    public var formattedMessage: String {
        return "[\(formattedTimestamp)] \(level.emoji) [\(level.name)] [\(shortFileName):\(line)] \(message)"
    }
    
    /// 简化的日志字符串（无文件信息）
    public var simplifiedMessage: String {
        return "[\(formattedTimestamp)] \(level.emoji) \(message)"
    }
}

// MARK: - 日志配置

/// 日志配置类
public class MMTLogConfiguration {
    
    /// 最低日志级别（低于此级别的日志将被过滤）
    public var minimumLevel: MMTLogLevel = .debug
    
    /// 是否输出到控制台
    public var enableConsole: Bool = true
    
    /// 是否输出到文件
    public var enableFile: Bool = false
    
    /// 日志文件路径
    public var logFilePath: String?
    
    /// 日志文件最大大小（字节）
    public var maxFileSize: UInt64 = 10 * 1024 * 1024  // 10MB
    
    /// 是否启用颜色（控制台）
    public var enableColors: Bool = true
    
    /// 自定义日志处理器
    public var customHandler: ((MMTLogEntry) -> Void)?
    
    /// 日志缓存（用于显示）
    public var cacheEnabled: Bool = true
    public var cacheLimit: Int = 1000
    
    public init() {}
}

// MARK: - 日志管理器

/// 日志管理器
public class MMTToolForNordicLog: NSObject {
    
    // MARK: - 单例
    
    public static let shared = MMTToolForNordicLog()
    
    // MARK: - 属性
    
    /// 配置
    public var configuration: MMTLogConfiguration = MMTLogConfiguration()
    
    /// 日志缓存
    private var logCache: [MMTLogEntry] = []
    private let cacheLock = NSLock()
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    /// 日期格式化器
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - 初始化
    
    private override init() {
        super.init()
        setupDefaultConfiguration()
    }
    
    private func setupDefaultConfiguration() {
        configuration.enableConsole = true
        configuration.cacheEnabled = true
        configuration.minimumLevel = .debug
    }
    
    // MARK: - 配置方法
    
    /// 配置日志系统
    public class func configure(_ block: (MMTLogConfiguration) -> Void) {
        block(shared.configuration)
    }
    
    /// 设置自定义日志处理器
    public class func setCustomHandler(_ handler: @escaping (MMTLogEntry) -> Void) {
        shared.configuration.customHandler = handler
    }
    
    /// 设置最低日志级别
    public class func setMinimumLevel(_ level: MMTLogLevel) {
        shared.configuration.minimumLevel = level
    }
    
    // MARK: - 日志记录
    
    /// 记录日志
    public class func log(
        _ message: Any?,
        level: MMTLogLevel = .debug,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        shared.writeLog(
            message: message,
            level: level,
            file: file,
            line: line,
            function: function
        )
    }
    
    private func writeLog(
        message: Any?,
        level: MMTLogLevel,
        file: String,
        line: Int,
        function: String
    ) {
        // 过滤日志级别
        guard level <= configuration.minimumLevel else { return }
        
        // 创建日志条目
        let entry = MMTLogEntry(
            timestamp: Date(),
            level: level,
            message: "\(message ?? "")",
            file: file,
            line: line,
            function: function,
            thread: Thread.current.isMainThread ? "Main" : "Background"
        )
        
        // 缓存日志
        if configuration.cacheEnabled {
            cacheLog(entry)
        }
        
        // 控制台输出
        if configuration.enableConsole {
            printToConsole(entry)
        }
        
        // 文件输出
        if configuration.enableFile {
            printToFile(entry)
        }
        
        // 自定义处理器
        configuration.customHandler?(entry)
    }
    
    // MARK: - 缓存管理
    
    private func cacheLog(_ entry: MMTLogEntry) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        logCache.append(entry)
        
        // 限制缓存大小
        if logCache.count > configuration.cacheLimit {
            logCache.removeFirst(logCache.count - configuration.cacheLimit)
        }
    }
    
    /// 获取所有缓存的日志
    public class func getCachedLogs() -> [MMTLogEntry] {
        return shared.logCache
    }
    
    /// 获取缓存的日志字符串
    public class func getCachedLogStrings() -> [String] {
        return shared.logCache.map { $0.formattedMessage }
    }
    
    /// 清空缓存
    public class func clearCache() {
        shared.cacheLock.lock()
        defer { shared.cacheLock.unlock() }
        shared.logCache.removeAll()
    }
    
    // MARK: - 输出方法
    
    private func printToConsole(_ entry: MMTLogEntry) {
        let prefix = configuration.enableColors ? entry.level.colorCode : ""
        let reset = configuration.enableColors ? "\u{001B}[0;0m" : ""
        
        print("\(prefix)\(entry.formattedMessage)\(reset)")
    }
    
    private func printToFile(_ entry: MMTLogEntry) {
        guard let path = configuration.logFilePath else { return }
        
        let logString = entry.formattedMessage + "\n"
        
        guard let data = logString.data(using: .utf8) else { return }
        
        if fileManager.fileExists(atPath: path) {
            // 检查文件大小
            if let attributes = try? fileManager.attributesOfItem(atPath: path),
               let fileSize = attributes[.size] as? UInt64,
               fileSize > configuration.maxFileSize {
                // 文件过大，删除旧日志
                try? fileManager.removeItem(atPath: path)
            }
            
            // 追加到文件
            if let fileHandle = FileHandle(forWritingAtPath: path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            // 创建新文件
            fileManager.createFile(atPath: path, contents: data, attributes: nil)
        }
    }
    
    // MARK: - 便捷方法
    
    /// 导出日志到文件
    public class func exportLogs(to path: String) -> Bool {
        let logs = shared.logCache.map { $0.formattedMessage }.joined(separator: "\n")
        
        do {
            try logs.write(toFile: path, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Failed to export logs: \(error)")
            return false
        }
    }
}

// MARK: - 便捷日志函数

/// 全局日志函数
public func MMTLogError(_ message: Any?, file: String = #file, line: Int = #line, function: String = #function) {
    MMTToolForNordicLog.log(message, level: .error, file: file, line: line, function: function)
}

public func MMTLogWarning(_ message: Any?, file: String = #file, line: Int = #line, function: String = #function) {
    MMTToolForNordicLog.log(message, level: .warning, file: file, line: line, function: function)
}

public func MMTLogInfo(_ message: Any?, file: String = #file, line: Int = #line, function: String = #function) {
    MMTToolForNordicLog.log(message, level: .info, file: file, line: line, function: function)
}

public func MMTLogDebug(_ message: Any?, file: String = #file, line: Int = #line, function: String = #function) {
    MMTToolForNordicLog.log(message, level: .debug, file: file, line: line, function: function)
}

public func MMTLogVerbose(_ message: Any?, file: String = #file, line: Int = #line, function: String = #function) {
    MMTToolForNordicLog.log(message, level: .verbose, file: file, line: line, function: function)
}

// MARK: - 枚举式日志（保留旧接口兼容性）

public enum MMTNordicLog {
    case error
    case warning
    case info
    case debug
    case verbose
    
    public func log(_ message: Any?, file: String = #file, line: Int = #line, function: String = #function) {
        let level: MMTLogLevel
        switch self {
        case .error:    level = .error
        case .warning:  level = .warning
        case .info:     level = .info
        case .debug:    level = .debug
        case .verbose:  level = .verbose
        }
        MMTToolForNordicLog.log(message, level: level, file: file, line: line, function: function)
    }
}

// MARK: - 兼容旧 API

extension MMTToolForNordicLog {
    
    /// 兼容旧的配置方法
    @available(*, deprecated, message: "Use configure(_:) instead")
    public class func config(logAction: @escaping (Any?, MMTLogLevel, StaticString, Int, StaticString) -> Void) {
        setCustomHandler { entry in
            // 将 String 转换为 StaticString（简化处理，直接传递字符串）
            // 注意：StaticString 是编译时常量，这里做简化处理
            logAction(entry.message, entry.level, "", entry.line, "")
        }
    }
}
