//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import SAPCommon
import SAPFiori
import SAPFioriFlows
import SAPFoundation
import WebKit

import SharedFmwk

public class OnboardingFlowProvider: OnboardingFlowProviding {
    // MARK: – Properties

    public static let modalUIViewControllerPresenter = ModalUIViewControllerPresenter()

    // MARK: – Init

    public init() {}

    // MARK: – OnboardingFlowProvider

    public func flow(for _: OnboardingControlling, flowType: OnboardingFlow.FlowType, completionHandler: @escaping (OnboardingFlow?, Error?) -> Void) {
        switch flowType {
        case .onboard:
            completionHandler(onboardingFlow(), nil)
        case let .restore(onboardingID):
            completionHandler(restoringFlow(for: onboardingID), nil)
        case let .background(onboardingID):
            completionHandler(backgroundFlow(for: onboardingID), nil)
        case let .reset(onboardingID):
            completionHandler(resettingFlow(for: onboardingID), nil)
        case .resetPasscode:
            completionHandler(nil, nil)
        @unknown default:
            break
        }
    }

    // MARK: – Internal

    func onboardingFlow() -> OnboardingFlow {
        let steps = onboardingSteps
        let context = OnboardingContext(presentationDelegate: OnboardingFlowProvider.modalUIViewControllerPresenter)
        let flow = OnboardingFlow(flowType: .onboard, context: context, steps: steps)
        return flow
    }

    func restoringFlow(for onboardingID: UUID) -> OnboardingFlow {
        let steps = restoringSteps
        var context = OnboardingContext(onboardingID: onboardingID, presentationDelegate: OnboardingFlowProvider.modalUIViewControllerPresenter)
        context.onboardingID = onboardingID
        let flow = OnboardingFlow(flowType: .restore(onboardingID: onboardingID), context: context, steps: steps)
        return flow
    }

    func backgroundFlow(for onboardingID: UUID) -> OnboardingFlow {
        let steps = backgroundSteps
        var context = OnboardingContext(onboardingID: onboardingID, presentationDelegate: OnboardingFlowProvider.modalUIViewControllerPresenter)
        context.onboardingID = onboardingID
        let flow = OnboardingFlow(flowType: .background(onboardingID: onboardingID), context: context, steps: steps)
        return flow
    }

    func resettingFlow(for onboardingID: UUID) -> OnboardingFlow {
        let steps = resettingSteps
        var context = OnboardingContext(onboardingID: onboardingID, presentationDelegate: OnboardingFlowProvider.modalUIViewControllerPresenter)
        context.onboardingID = onboardingID
        let flow = OnboardingFlow(flowType: .reset(onboardingID: onboardingID), context: context, steps: steps)
        return flow
    }

    func getAPIKeyAuthenticationConfig() -> APIKeyAuthenticationConfig? {
        let obfuscator: Obfuscating = Obfuscator()
        let key = obfuscator.deobfuscate([85, 80, 94, 5, 67, 88, 70, 101, 76, 9, 16, 83, 82, 75, 85, 71, 94, 69, 126, 3, 89, 18, 93, 72, 4, 4, 69, 14, 21, 55, 4, 95, 67, 6, 82, 95])
        return APIKeyAuthenticationConfig(apikeys: [key], isAPIKeyAccessOnly: false, allowAnonymousAccessFlag: true)
    }

    // MARK: - Steps

    // NUIStyleSheetApplyStep() can be used after "OAuth2AuthenticationStep(presenter: FioriWKWebViewPresenter(webViewDelegate: self))" to apply theming without getAPIKeyAuthenticationConfig

    public var onboardingSteps: [OnboardingStep] {
        return [
            configuredWelcomeScreenStep(),
            CompositeStep(steps: SAPcpmsDefaultSteps.configuration),
            OAuth2AuthenticationStep(presenter: FioriWKWebViewPresenter(webViewDelegate: self)),

            CompositeStep(steps: SAPcpmsDefaultSteps.settingsDownload),
            CompositeStep(steps: SAPcpmsDefaultSteps.applyDuringOnboard),
            configuredEulaConsentStep(),
            configuredUserConsentStep(),
            configuredDataCollectionConsentStep(),
            configuredStoreManagerStep(),
            AuxiliaryCommunicationStep(),
            ODataOnboardingStep(),
        ]
    }

    // NUIStyleSheetApplyStep() can be used after "OAuth2AuthenticationStep(presenter: FioriWKWebViewPresenter(webViewDelegate: self))" to apply theming without getAPIKeyAuthenticationConfig

    public var restoringSteps: [OnboardingStep] {
        return [
            configuredStoreManagerStep(),
            configuredWelcomeScreenStep(),
            CompositeStep(steps: SAPcpmsDefaultSteps.configuration),
            OAuth2AuthenticationStep(presenter: FioriWKWebViewPresenter(webViewDelegate: self)),

            CompositeStep(steps: SAPcpmsDefaultSteps.settingsDownload),
            CompositeStep(steps: SAPcpmsDefaultSteps.applyDuringRestore),
            configuredDataCollectionConsentStep(),
            ODataOnboardingStep(),
        ]
    }

    public var backgroundSteps: [OnboardingStep] {
        return [
            configuredStoreManagerStep(),
            configuredWelcomeScreenStep(),
            CompositeStep(steps: SAPcpmsDefaultSteps.configuration),
            OAuth2AuthenticationStep(presenter: FioriWKWebViewPresenter(webViewDelegate: self)),

            AuxiliaryCommunicationStep(),
        ]
    }

    public var offlineSyncingSteps: [OnboardingStep] {
        return [
            configuredWelcomeScreenStep(),
            CompositeStep(steps: SAPcpmsDefaultSteps.settingsDownload),
            CompositeStep(steps: SAPcpmsDefaultSteps.applyDuringRestore),
        ]
    }

    public var resettingSteps: [OnboardingStep] {
        return onboardingSteps
    }

    // MARK: – Step configuration

    private func configuredWelcomeScreenStep() -> WelcomeScreenStep {
        let appParameters = FileConfigurationProvider("AppParameters").provideConfiguration().configuration
        let destinations = appParameters["Destinations"] as! NSDictionary
        let discoveryConfigurationTransformer = DiscoveryServiceConfigurationTransformer(applicationID: appParameters["Application Identifier"] as? String, authenticationPath: destinations["ProxyService"] as? String)
        var providers: [ConfigurationProviding] = [FileConfigurationProvider()]

        let welcomeScreenStep = WelcomeScreenStep(transformer: discoveryConfigurationTransformer, providers: providers)

        welcomeScreenStep.welcomeScreenCustomizationHandler = { welcomeStepUI in
            welcomeStepUI.headlineLabel.text = "DealersApp"
            welcomeStepUI.detailLabel.text = NSLocalizedString("keyWelcomeScreenMessage", value: "This application was generated by SAP BTP SDK Assistant for iOS" + " v9.1.3", comment: "XMSG: Message on WelcomeScreen")
            welcomeStepUI.primaryActionButton.titleLabel?.text = NSLocalizedString("keyWelcomeScreenStartButton", value: "Start", comment: "XBUT: Title of start button on WelcomeScreen")

            if let welcomeScreen = welcomeStepUI as? FUIWelcomeScreen {
                // Configuring WelcomeScreen to prefill the email domain

                welcomeScreen.emailTextField.text = "user@"
            }
        }

        return welcomeScreenStep
    }

    private func configuredEulaConsentStep() -> EULAStep {
        let title = "SAP - EULA"
        let text = """
        This is a legally binding agreement (Agreement) between Company and SAP SE which provides the terms of your use of the SAP mobile application (Software). By clicking "Accept" or by installing and/or using the Software, you on behalf of the Company are agreeing to all of the terms and conditions stated in this Agreement. If you do not agree to these terms, do not click "Agree", and do not use the Software. You represent and warrant that you have the authority to bind the Company to the terms of this Agreement.
        """
        let attributes = [NSAttributedStringKey.font: UIFont.preferredFioriFont(forTextStyle: .body)]
        let content = NSAttributedString(string: text, attributes: attributes)
        let eulaContent = EULAContent(title: title, content: content, version: "1.0")
        return EULAStep(eulaContent: eulaContent)
    }

    private func configuredUserConsentStep() -> UserConsentStep {
        let actionTitle = "Learn more about Data Privacy"
        let actionUrl = "https://www.sap.com/corporate/en/legal/privacy.html"
        let singlePageTitle = "Data Privacy"
        let singlePageText = "Detailed text about how data privacy pertains to this app and why it is important for the user to enable this functionality"

        var singlePageContent = UserConsentPageContent()
        singlePageContent.actionTitle = actionTitle
        singlePageContent.actionUrl = actionUrl
        singlePageContent.title = singlePageTitle
        singlePageContent.body = singlePageText
        let singlePageFormContent = UserConsentFormContent(version: "1.0", isRequired: true, pages: [singlePageContent])

        return UserConsentStep(userConsentFormsContent: [singlePageFormContent])
    }

    private func configuredDataCollectionConsentStep() -> DataCollectionConsentStep {
        return DataCollectionConsentStep()
    }

    private func configuredStoreManagerStep() -> StoreManagerStep {
        let step = StoreManagerStep()
        step.defaultPasscodePolicy = nil
        step.runRestoreIfStoreExists = true
        step.auxiliaryParameters = getAuxiliaryParameters()
        return step
    }

    func getAuxiliaryParameters() -> AuxiliaryParameters {
        let obfuscatedPrimaryKey: [UInt8] = [49, 21, 39, 32, 15, 61, 59, 7, 50, 22, 2, 49, 35, 39, 82, 48, 52, 50, 98, 36, 36, 38, 87, 92, 87, 36, 13, 85, 76, 9, 49, 63, 13, 46, 14, 18, 44, 47, 63, 25, 31, 38, 57, 73]
        let apiKeyAuthenticationConfig: APIKeyAuthenticationConfig? = getAPIKeyAuthenticationConfig()
        let dataStore = try! AuxiliaryConfiguration.getSharedStore()
        let auxDataRequestManager: AuxiliaryDataRequestManager? = try? AuxiliaryDataRequestManager(dataStore: dataStore)
        let dataContainer: AuxiliaryDataRequest<WidgetDataKey>? = try? auxDataRequestManager?.getDataRequest()
        let eSPAKAuxiliary: Data? = dataContainer?.eSPAKAuxiliary
        let onboardingStatusName: String = AuxiliaryConfiguration.onboardingStatusName
        return AuxiliaryParameters(sharedStoreName: AuxiliaryConfiguration.sharedStoreName, sharedAccessGroup: AuxiliaryConfiguration.sharedAccessGroup, obfuscatedPrimaryKey: obfuscatedPrimaryKey, eSPAKAuxiliary: eSPAKAuxiliary, apiKeyAuthenicationConfig: apiKeyAuthenticationConfig, onboardingStatusName: onboardingStatusName)
    }
}

// MARK: - SAPWKNavigationDelegate

// The WKWebView occasionally returns an NSURLErrorCancelled error if a redirect happens too fast.
// In case of OAuth with SAP's identity provider (IDP) we do not treat this as an error.
extension OnboardingFlowProvider: SAPWKNavigationDelegate {
    public func webView(_: WKWebView, handleFailed _: WKNavigation!, withError error: Error) -> Error? {
        if isCancelledError(error) {
            return nil
        }
        return error
    }

    public func webView(_: WKWebView, handleFailedProvisionalNavigation _: WKNavigation!, withError error: Error) -> Error? {
        if isCancelledError(error) {
            return nil
        }
        return error
    }

    private func isCancelledError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain &&
            nsError.code == NSURLErrorCancelled
    }
}
