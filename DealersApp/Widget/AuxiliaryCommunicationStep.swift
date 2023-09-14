//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SAPCommon
import SAPFioriFlows
import SAPFoundation
import SharedFmwk
import WidgetKit

open class AuxiliaryCommunicationStep: OnboardingStep {
    let logger = Logger.shared(named: "AuxiliaryCommunicationStep")
    var odataControllers = [String: ODataControlling]()

    // MARK: – OnboardingStep methods with context

    public func onboard(context: OnboardingContext, completionHandler: @escaping (OnboardingResult) -> Void) {
        prefetchDataForWidget(using: context, completionHandler: completionHandler)
    }

    public func restore(context: OnboardingContext, completionHandler: @escaping (OnboardingResult) -> Void) {
        completionHandler(.success(context))
    }

    public func reset(context _: OnboardingContext, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    public func background(context: OnboardingContext, completionHandler: @escaping (OnboardingResult) -> Void) {
        loadDataForWidget(using: context, completionHandler: completionHandler)
    }

    // MARK: – Widget data loading entry points

    private func prefetchDataForWidget(using context: OnboardingContext, completionHandler: @escaping (OnboardingResult) -> Void) {
        getConfiguredODataControllers(context: context) { odataControllers in
            let widgetDataLoaders = self.getConfiguredWidgetDataLoaders(odataControllers: odataControllers)
            let dataLoadingManager = WidgetDataLoadingManager(widgetDataLoaders: widgetDataLoaders)
            // Let's try to prefetch all entitysets required for the widget.
            Task.init {
                let result = await dataLoadingManager.loadAllEntitySets()
                if result {
                    self.logger.info("dataLoadingManager.loadAllEntitySets() successful.")
                    WidgetCenter.shared.reloadTimelines(ofKind: AuxiliaryConfiguration.widgetKind)
                    completionHandler(.success(context))
                    return
                } else {
                    self.logger.info("dataLoadingManager.loadAllEntitySets() failed.")
                    // lets not fail the flow. prefetch is an optional processing operation.
                    WidgetCenter.shared.reloadTimelines(ofKind: AuxiliaryConfiguration.widgetKind)
                    completionHandler(.success(context))
                    return
                }
            }
        }
    }

    private func loadDataForWidget(using context: OnboardingContext, completionHandler: @escaping (OnboardingResult) -> Void) {
        // Let's identify the pending request
        guard let pendingRequest = identifyPendingDataRequest() else {
            logger.info("There is no widget data load request to process at this moment.")
            completionHandler(.success(context))
            return
        }
        // Let's load the entityset required for the widget.
        let dataKey: WidgetDataKey = pendingRequest.get()
        getConfiguredODataControllers(context: context) { odataControllers in
            let widgetDataLoaders = self.getConfiguredWidgetDataLoaders(odataControllers: odataControllers)
            let dataLoadingManager = WidgetDataLoadingManager(widgetDataLoaders: widgetDataLoaders)
            Task.init {
                let result = await dataLoadingManager.loadEntitySet(from: dataKey.destinationName, entityName: dataKey.entityName)
                if result {
                    self.logger.info("dataLoadingManager.loadEntitySet() successful.")
                    WidgetCenter.shared.reloadTimelines(ofKind: pendingRequest.kind)
                    completionHandler(.success(context))
                    return
                } else {
                    self.logger.info("dataLoadingManager.loadEntitySet() failed.")
                    completionHandler(.failed(OnboardingError.missingArgument(dataKey.entityName, source: dataKey.destinationName)))
                    return
                }
            }
        }
    }

    private func identifyPendingDataRequest() -> AuxiliaryDataRequest<WidgetDataKey>? {
        do {
            let dataStore = try AuxiliaryConfiguration.getSharedStore()
            let auxDataRequestManager: AuxiliaryDataRequestManager = try AuxiliaryDataRequestManager(dataStore: dataStore)
            let dataRequest: AuxiliaryDataRequest<WidgetDataKey>? = try auxDataRequestManager.getDataRequest()
            guard let dataRequestNotNil = dataRequest else {
                logger.info("There is no widget data load request to process at this moment.")
                return nil
            }
            return dataRequestNotNil
        } catch {
            logger.error("Error occured while processing data request - Error: \(error)")
            return nil
        }
    }

    private func getConfiguredODataControllers(context: OnboardingContext,
                                               completion: @escaping ([String: ODataControlling]) -> Void)
    {
        let destinations = FileConfigurationProvider("AppParameters").provideConfiguration().configuration["Destinations"] as! NSDictionary

        odataControllers[ODataContainerType.proxyService.description] = ProxyServiceOnlineODataController()

        for (odataServiceName, odataController) in odataControllers {
            let destinationId = destinations[odataServiceName] as! String
            let configurationURL = URL(string: (context.info[.sapcpmsSettingsParameters] as! SAPcpmsSettingsParameters).backendURL.appendingPathComponent(destinationId).absoluteString)!
            do {
                try odataController.configureOData(sapURLSession: context.sapURLSession, serviceRoot: configurationURL)
                odataControllers[odataServiceName] = odataController
            } catch {
                logger.error("Error occured while configuring odataService: \(odataServiceName)")
            }
        }
        completion(odataControllers)
    }

    private func getConfiguredWidgetDataLoaders(odataControllers: [String: ODataControlling]) -> [String: WidgetDataLoading] {
        var widgetDataLoaders: [String: WidgetDataLoading] = [:]
        var key = ""
        var cipher: Ciphering

        do {
            let auxDataEncryptionKey = try SecurityManager().getAuxiliaryDataEncryptionKey()
            cipher = CryptoProvider(with: auxDataEncryptionKey, tag: AuxiliaryConfiguration.cryptoProviderTag)
        } catch {
            fatalError("No auxiliary data encryption key found!")
        }

        key = ODataContainerType.proxyService.description
        if let controller = odataControllers[key], let loader = ProxyServiceWidgetDataLoader(controller: controller, with: cipher) {
            widgetDataLoaders[key] = loader
        }
        return widgetDataLoaders
    }
}
