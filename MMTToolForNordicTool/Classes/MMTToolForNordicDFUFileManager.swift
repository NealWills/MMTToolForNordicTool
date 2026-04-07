//
//  MMTToolForNordicDFUFileManager.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 03/04/2026.
//

import Foundation

import Foundation


class MMTToolForNordicDFUFileManager: NSObject {
    
    class func removeTempDir() {
        let rootDir = MMTToolForNordicDFUFileManager.getRootDirPath()
        if FileManager.default.fileExists(atPath: rootDir) {
            do {
                try FileManager.default.removeItem(atPath: rootDir)
            } catch let error {
                
            }
        }
    }
    
    @discardableResult
    class func copyDFUFileToTempDir(originPath: String, deviceMac: String) -> String {
        let rootDir = MMTToolForNordicDFUFileManager.getRootDirPath()
        let dfuDir = rootDir + deviceMac + "/"
        let dfuPath = dfuDir  + "dfufile"
        if FileManager.default.fileExists(atPath: dfuDir) {
            do {
                try FileManager.default.removeItem(atPath: dfuDir)
                try FileManager.default.createDirectory(atPath: dfuDir, withIntermediateDirectories: true)
            } catch let error {
                
            }
        }
        do {
            try FileManager.default.copyItem(atPath: originPath, toPath: dfuPath)
        } catch let error {
            
        }
        return dfuPath
    }
    
    /// 获取根目录
    /// 这里规定根目录为 /document/rootDir/
    /// - Returns: 根目录地址
    @discardableResult
    class func getRootDirPath() -> String {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var strPath = documentsDirectory.absoluteString
        if strPath[0 ..< 7] == "file://" {
            strPath = strPath.replacingOccurrences(of: "file://", with: "")
        }
//        return strPath + ".rootDirPrivate/"
        return strPath + ".mmtTempDFUDir" + "/"
    }
    
}

fileprivate extension String {
    
    subscript(_ range: Range<Int>) -> String {
        if range.lowerBound < 0 {
            return ""
        }
        if count <= range.lowerBound {
            return ""
        }
        if count <= range.upperBound {
            return subString(start: range.lowerBound, end: count)
        }
        return subString(start: range.lowerBound, end: range.upperBound)
    }
    
    @discardableResult
    func subString(start: Int, end: Int) -> String {
        var start = start
        start = start < 0 ? 0 : start
        start = start >= count ? count : start
        var end = end
        end = end < 0 ? 0 : end
        end = end >= count ? count : end
        if start > end {
            let l = end
            start = end
            end = l
        }
        #if swift(>=5.0)
        let startIndex = String.Index(utf16Offset: start, in: self)
        let endIndex = String.Index(utf16Offset: end, in: self)
        #else
        let startIndex = String.Index(encodedOffset: start)
        let endIndex = String.Index(encodedOffset: end)
        #endif
        return String(self[startIndex ..< endIndex])
    }
}
