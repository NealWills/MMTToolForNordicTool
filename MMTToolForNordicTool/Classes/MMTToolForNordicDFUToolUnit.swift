//
//  MMTToolForNordicDFUToolUnit.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 03/04/2026.
//

import Foundation

class MMTToolForNordicDFUToolUnit: NSObject {
    
    var unitId: String
    
    init(unitId: String) {
        self.unitId = unitId
    }
    
    func destroyUnit() {
        
    }
    
}

extension MMTToolForNordicDFUToolUnit {
    
    func startDFUAction(
        fileData: Data?,
        mac: String?,
        macExtra: String?
    ) {
        
        guard let fileData else { return }
        do {
            let firmware = try DFUFirmware.init(zipFile: fileData)
            DFUServiceInitiator.init()
                .with(firmware: firmware)
                .start(target: <#T##CBPeripheral#>)
            
        } catch let error {
            
        }
        
    }
}


