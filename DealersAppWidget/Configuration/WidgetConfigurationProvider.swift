//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SAPFoundation
import SharedFmwk
import WidgetKit

class WidgetConfigurationProvider: WidgetConfigurationProviding {
    let auxStoreName: String = "AuxiliaryDataStore"
    let auxAccessGroup: String = ""
    let obfuscatedAuxiliaryKey: [UInt8] = [9, 38, 37, 11, 39, 29, 4, 33, 9, 93, 23, 33, 49, 52, 32, 29, 34, 95, 31, 35, 41, 59, 28, 21, 28, 32, 55, 13, 7, 100, 88, 89, 69, 21, 41, 12, 47, 20, 0, 7, 30, 16, 27, 73]

    func configurationDisplayName() -> String {
        "DealersApp Widget"
    }

    func description() -> String {
        "Get quick access to your entities."
    }

    func kind() -> String {
        AuxiliaryConfiguration.widgetKind
    }

    var supportedFamilies: [WidgetFamily] {
        [.systemLarge]
    }
}
