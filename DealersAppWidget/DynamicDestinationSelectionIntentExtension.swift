//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SharedFmwk

public extension DynamicDestinationSelectionIntent {
    var selectedDestination: String {
        switch destination {
        case .proxyService:
            return ODataContainerType.proxyService.description
        default:
            return "NA"
        }
    }

    var selectedEntity: String {
        switch destination {
        case .proxyService:
            if let validDestination = ProxyService,
               let value = ProxyServiceCollectionType(rawValue: validDestination.displayString)
            {
                return value.description
            } else {
                return "NA"
            }
        case .unknown:
            return "NA"
        }
    }
}
