import Foundation

class MMTToolForNordicTool: NSObject {
    
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
