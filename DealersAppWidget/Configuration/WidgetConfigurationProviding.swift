//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import WidgetKit

protocol WidgetConfigurationProviding {
    func kind() -> String
    func configurationDisplayName() -> String
    func description() -> String
    var supportedFamilies: [WidgetFamily] { get }
}
