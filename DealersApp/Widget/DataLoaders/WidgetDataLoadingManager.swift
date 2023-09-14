//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SAPCommon
import SAPOData
import SharedFmwk

public class WidgetDataLoadingManager {
    private let logger = Logger.shared(named: "WidgetDataLoadingManager")
    private let widgetDataLoaders: [String: WidgetDataLoading]

    init(widgetDataLoaders: [String: WidgetDataLoading]) {
        self.widgetDataLoaders = widgetDataLoaders
    }

    func loadEntitySet(from destinationName: String, entityName: String) async -> Bool {
        guard !destinationName.isEmpty, !entityName.isEmpty, !widgetDataLoaders.isEmpty else {
            logger.info("Cannot load empty values!")
            return false
        }

        if let dataProvider = widgetDataLoaders[destinationName] {
            let result = await dataProvider.loadEntitySet(for: entityName)
            switch result {
            case true:
                logger.info("EntitySet \(entityName) loaded successfully")
            case false:
                logger.info("EntitySet \(entityName) load failed")
            }
            return result
        } else {
            logger.info("No widget data loader found for: \(destinationName)")
            return false
        }
    }

    func loadAllEntitySets() -> Bool {
        guard !widgetDataLoaders.isEmpty else {
            logger.info("Cannot load empty values!")
            return false
        }

        let workerQ = DispatchQueue(label: "com.sap.WidgetDataLoadingManager-getAllDataQueue")
        workerQ.async {
            print("Starting fetch for all WidgetDataProviders")
            for (_, dataLoader) in self.widgetDataLoaders {
                Task.init {
                    let result = await dataLoader.loadAllEntitySets()
                    switch result {
                    case true:
                        print("leave called for: \(dataLoader)")
                    case false:
                        // Do nothing, since we're not passing failure from widget data loaders
                        break
                    }
                }
            }
        }
        return true
    }
}
