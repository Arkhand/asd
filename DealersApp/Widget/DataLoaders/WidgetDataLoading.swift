//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SAPCommon
import SharedFmwk

/// Types which can provide data for widget
protocol WidgetDataLoading {
    init?(controller: ODataControlling, with cipher: Ciphering)
    func loadAllEntitySets() async -> Bool
    func loadEntitySet(for entity: String) async -> Bool
}
