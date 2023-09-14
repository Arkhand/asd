//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SAPCommon
import SAPOData

import ProxyServiceFmwk
import SharedFmwk

class ProxyServiceWidgetDataLoader: WidgetDataLoading {
    private let dataService: ProxyService!
    private let widgetController: ProxyServiceWidgetController
    private let logger = Logger.shared(named: "ProxyServiceWidgetDataLoader")

    required init?(controller: ODataControlling, with cipher: Ciphering) {
        dataService = (controller as! ProxyServiceOnlineODataController).dataService
        widgetController = ProxyServiceWidgetController()
        do {
            try widgetController.configure(with: cipher)
            logger.info("ESPMContainerWidgetDataLoader initialised successfully!")
        } catch {
            logger.info("ESPMContainerWidgetDataLoader initialisation failed due to error: \(error)")
            return nil
        }
    }

    func loadAllEntitySets() async -> Bool {
        for entity in ProxyServiceCollectionType.allCases {
            let result = await loadEntitySet(for: entity.description)
            switch result {
            case true:
                logger.info("EntitySet \(entity) loaded successfully")
            case false:
                logger.info("EntitySet \(entity) load failed")
            }
        }
        return true
    }

    func loadEntitySet(for entity: String) async -> Bool {
        guard let entityEnum = ProxyServiceCollectionType(rawValue: entity) else {
            logger.info("Cannot convert \(entity) to ProxyServiceCollectionType type")
            return false
        }

        switch entityEnum {
        case .rejectionCodes:
            let query = DataQuery().selectAll().top(AuxiliaryConfiguration.numberOfRecords)
            do {
                let result = try await dataService.fetchRejectionCodes(matching: query)

                if (try? widgetController.put(list: result, forKey: entityEnum.description)) != nil {
                    logger.info("EntitySet \(entityEnum.description) loaded successfully")
                    return true
                } else {
                    logger.error("EntitySet \(entityEnum.description) storing failed")
                    return false
                }
            } catch {
                logger.error("EntitySet \(entityEnum.description) retrieval failed.", error: error)
                return false
            }

        case .material:
            let query = DataQuery().selectAll().top(AuxiliaryConfiguration.numberOfRecords)
            do {
                let result = try await dataService.fetchMaterial(matching: query)

                if (try? widgetController.put(list: result, forKey: entityEnum.description)) != nil {
                    logger.info("EntitySet \(entityEnum.description) loaded successfully")
                    return true
                } else {
                    logger.error("EntitySet \(entityEnum.description) storing failed")
                    return false
                }
            } catch {
                logger.error("EntitySet \(entityEnum.description) retrieval failed.", error: error)
                return false
            }

        case .shipClose:
            let query = DataQuery().selectAll().top(AuxiliaryConfiguration.numberOfRecords)
            do {
                let result = try await dataService.fetchShipClose(matching: query)

                if (try? widgetController.put(list: result, forKey: entityEnum.description)) != nil {
                    logger.info("EntitySet \(entityEnum.description) loaded successfully")
                    return true
                } else {
                    logger.error("EntitySet \(entityEnum.description) storing failed")
                    return false
                }
            } catch {
                logger.error("EntitySet \(entityEnum.description) retrieval failed.", error: error)
                return false
            }

        case .currentSolicitations:
            let query = DataQuery().selectAll().top(AuxiliaryConfiguration.numberOfRecords)
            do {
                let result = try await dataService.fetchCurrentSolicitations(matching: query)

                if (try? widgetController.put(list: result, forKey: entityEnum.description)) != nil {
                    logger.info("EntitySet \(entityEnum.description) loaded successfully")
                    return true
                } else {
                    logger.error("EntitySet \(entityEnum.description) storing failed")
                    return false
                }
            } catch {
                logger.error("EntitySet \(entityEnum.description) retrieval failed.", error: error)
                return false
            }

        default:
            return false
        }
    }
}
