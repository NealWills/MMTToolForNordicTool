//
//  MMTToolForNordicLog.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 07/04/2026.
//

import Foundation

public class MMTToolForNordicLog: NSObject {
    
    static let share = MMTToolForNordicLog()
    
    public enum Level {
        case error
        case warning
        case info
        case debug
        case verbose
        
        public var strValue: String {
            switch self {
            case .error:
                return "Error"
            case .warning:
                return "Warning"
            case .info:
                return "Info"
            case .debug:
                return "Debug"
            case .verbose:
                return "Verbose"
            }
        }
        
    }
    
    var logAction: ((_ msg: Any?, _ level: MMTToolForNordicLog.Level, _ fileName: StaticString, _ lineCount: Int, _ functionName: StaticString)->())?
    
    public class func config(logAction: ((_ msg: Any?, _ level: MMTToolForNordicLog.Level, _ fileName: StaticString, _ lineCount: Int, _ functionName: StaticString)->())?) {
        MMTToolForNordicLog.share.logAction = logAction
    }
    
    class func log(_ msg: Any?, level: MMTToolForNordicLog.Level = .debug, fileName: StaticString = #file, lineNumber: Int = #line, functionName: StaticString = #function) {
        MMTToolForNordicLog.share.logAction?(msg, level, fileName, lineNumber, functionName)
    }
    
}

public enum MMTNordicLog {
    
    case error
    case warning
    case info
    case debug
    case verbose
    
    public func log(_ msg: Any?, fileName: StaticString = #file, lineNumber: Int = #line, functionName: StaticString = #function) {
        switch self {
        case .error:
            MMTToolForNordicLog.log(msg, level: .error, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .warning:
            MMTToolForNordicLog.log(msg, level: .warning, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .info:
            MMTToolForNordicLog.log(msg, level: .info, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .debug:
            MMTToolForNordicLog.log(msg, level: .debug, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .verbose:
            MMTToolForNordicLog.log(msg, level: .verbose, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        }
    }
    
}
