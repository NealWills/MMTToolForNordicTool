//
//  MMTToolForNordicDFUTool.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 03/04/2026.
//


import Foundation

class MMTToolForNordicDFUTool: NSObject {
    
    static let share = MMTToolForNordicTool()
    
    var unitList: [MMTToolForNordicToolUnit]
    
    class func createUnit() -> MMTToolForNordicToolUnit {
        
        let unionId = UUID().uuidString
        let unitId = unionId.replacingOccurrences(of: "-", with: "").lowercased()
        let unit = MMTToolForNordicToolUnit.init(unitId: unitId)
    }
    
    class func removeUnit(unitId: String?) {
        if let unit = MMTToolForNordicTool.share.unitList.first(where: {
            return $0.unitId == unit
        }) {
            unit.destroyUnit()
        }
        var list = MMTToolForNordicTool.share.unitList.filter({
            return $0.unitId == unitId
        })
        MMTToolForNordicTool.share.unitList = list
    }
     
}
