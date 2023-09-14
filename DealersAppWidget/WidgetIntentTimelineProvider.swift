//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SAPCommon
import SAPFoundation
import SharedFmwk
import WidgetKit

struct WidgetIntentTimelineProvider: IntentTimelineProvider {
    // Use this to provide snapshot for widget
    private struct WidgetData: WidgetRowViewModel {
        var value = ""
        var key = ""
        var image: String?
    }

    static var previewData: [WidgetRowViewModel] {
        let sampleData: [WidgetData] = [
            WidgetData(value: "4fa5c668-8009-4a20-8991-6e1ee15f55c1",
                       key: "ProductId", image: nil),
            WidgetData(value: "4fa5c668-8009-4a20-8991-6e1ee15f55c1",
                       key: "ProductId", image: nil),
            WidgetData(value: "0b3c8d78-46e5-4c18-96b3-f3666b3ea08e",
                       key: "ProductId", image: nil),
            WidgetData(value: "aa21b4ba-c182-4178-98fb-72c764ac916e",
                       key: "ProductId", image: nil),
        ]
        return sampleData
    }

    func placeholder(in _: Context) -> WidgetEntry {
        return WidgetEntry(date: Date(), title: "Collections", values: WidgetIntentTimelineProvider.previewData)
    }

    func getSnapshot(for _: DynamicDestinationSelectionIntent, in _: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = WidgetEntry(date: Date(), title: "Collections", values: WidgetIntentTimelineProvider.previewData)
        completion(entry)
    }

    func getTimeline(for configuration: DynamicDestinationSelectionIntent, in _: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        guard AuxiliaryOnboardingUtil().isWidgetInitialized() else {
            // User has not onboarded, show login screen
            let entry = WidgetEntry(date: Date(), title: "", values: [])
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }

        let entry = getData(forEntity: configuration.selectedEntity, inDestination: configuration.selectedDestination)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    func getData(forEntity entity: String, inDestination destination: String) -> WidgetEntry {
        guard !destination.isEmpty, !entity.isEmpty else {
            let entry = WidgetEntry(date: Date(), title: "Collections", values: [])
            return entry
        }

        let controllers = AuxiliaryConfiguration.getConfiguredWidgetControllers()

        switch destination {
        case ODataContainerType.proxyService.description:
            let widgetController = controllers[destination] as! ProxyServiceWidgetController
            var cipher: Ciphering
            do {
                let auxDataEncryptionKey = try getAuxDataEncryptionKey()
                cipher = CryptoProvider(with: auxDataEncryptionKey, tag: AuxiliaryConfiguration.cryptoProviderTag)
            } catch {
                fatalError("No auxiliary data encryption key found!")
            }

            try? widgetController.configure(with: cipher)

            do {
                let info = WidgetDataKey(destinationName: destination, entityName: entity)
                let eSPAKAuxiliary = try getESPAKAuxiliary()
                let dataRequest = AuxiliaryDataRequest<WidgetDataKey>(info: info, eSPAKAux: eSPAKAuxiliary, kind: AuxiliaryConfiguration.widgetKind)
                try widgetController.initiateDataRequest(dataRequest: dataRequest)
            } catch {
                print("Error thrown in initiateDataRequest::: \(error)")
            }
            return proxyServiceEntry(forType: entity)

        default:
            return WidgetEntry(date: Date(), title: "Collections", values: [])
        }
    }

    func getESPAKAuxiliary() throws -> Data {
        let auxSecurityManager = try AuxiliarySecurityManager(auxiliaryStoreName: WidgetConfigurationProvider().auxStoreName, auxiliaryAccessGroup: WidgetConfigurationProvider().auxAccessGroup, sharedStoreName: AuxiliaryConfiguration.sharedStoreName, sharedAccesGroup: AuxiliaryConfiguration.sharedAccessGroup)

        return try auxSecurityManager.getESPAKAuxiliary(obfuscatedAuxiliaryKey: WidgetConfigurationProvider().obfuscatedAuxiliaryKey)
    }

    func getAuxDataEncryptionKey() throws -> Data {
        let auxSecurityManager = try AuxiliarySecurityManager(auxiliaryStoreName: WidgetConfigurationProvider().auxStoreName, auxiliaryAccessGroup: WidgetConfigurationProvider().auxAccessGroup, sharedStoreName: AuxiliaryConfiguration.sharedStoreName, sharedAccesGroup: AuxiliaryConfiguration.sharedAccessGroup)

        return try auxSecurityManager.getAuxiliaryDataEncryptionKey()
    }

    func proxyServiceEntry(forType entity: String) -> WidgetEntry {
        guard let entityEnum = ProxyServiceCollectionType(rawValue: entity) else {
            let entry = WidgetEntry(date: Date(), title: "Collections", values: [])
            return entry
        }

        var entry: WidgetEntry
        let controllers = AuxiliaryConfiguration.getConfiguredWidgetControllers()
        let widgetController = controllers[ODataContainerType.proxyService.description] as! ProxyServiceWidgetController

        var cipher: Ciphering
        do {
            let auxDataEncryptionKey = try getAuxDataEncryptionKey()
            cipher = CryptoProvider(with: auxDataEncryptionKey, tag: AuxiliaryConfiguration.cryptoProviderTag)
        } catch {
            fatalError("No auxiliary data encryption key found!")
        }

        try? widgetController.configure(with: cipher)

        var values = [WidgetRowViewModel]()

        switch entityEnum {
        case .rejectionCodes:
            do {
                values = try widgetController.fetchRejectionCodes()
            } catch {
                print("Error in fetching \(entity): \(error)")
            }
        case .material:
            do {
                values = try widgetController.fetchMaterial()
            } catch {
                print("Error in fetching \(entity): \(error)")
            }
        case .shipClose:
            do {
                values = try widgetController.fetchShipClose()
            } catch {
                print("Error in fetching \(entity): \(error)")
            }
        case .currentSolicitations:
            do {
                values = try widgetController.fetchCurrentSolicitations()
            } catch {
                print("Error in fetching \(entity): \(error)")
            }
        default:
            values = []
        }

        entry = WidgetEntry(date: Date(), title: entity, values: values)
        entry.listPath = "\(ODataContainerType.proxyService.description)/\(entity)"
        return entry
    }
}
