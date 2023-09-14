//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import Intents
import SharedFmwk

class DynamicDestinationSelectionIntentHandler: NSObject, DynamicDestinationSelectionIntentHandling {
    /// ProxyService
    func provideProxyServiceOptionsCollection(for _: DynamicDestinationSelectionIntent, with completion: @escaping (INObjectCollection<ProxyServiceEntities>?, Error?) -> Void) {
        completion(ProxyServiceEntities.inObjectCollection, nil)
    }

    func defaultProxyService(for _: DynamicDestinationSelectionIntent) -> ProxyServiceEntities? {
        return ProxyServiceEntities.inObjects.first!
    }
}

extension ProxyServiceEntities {
    static var inObjectCollection: INObjectCollection<ProxyServiceEntities> {
        INObjectCollection(items: ProxyServiceEntities.inObjects)
    }

    static var inObjects: [ProxyServiceEntities] {
        let values = ProxyServiceCollectionType.allCases.map {
            ProxyServiceEntities(identifier: nil, display: $0.description)
        }
        return values
    }
}
