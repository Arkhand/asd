//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import BackgroundTasks
import Foundation
import SAPCommon
import SAPFiori
import SAPFioriFlows
import SAPFoundation
import SAPOData
import SharedFmwk
import UserNotifications
import WidgetKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    private var coveringView: UIView?
    var flowProvider = OnboardingFlowProvider()

    /// Delegate implementation of the application in a custom class
    var onboardingErrorHandler: OnboardingErrorHandler?

    /// Application controller instance for the application
    var sessionManager: OnboardingSessionManager<ApplicationOnboardingSession>!

    /// Logger instance initialization
    private let logger = Logger.shared(named: "AppDelegateLogger")

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initializeLogUploader()
        initializeUsageCollection()

        // Set a FUIInfoViewController as the rootViewController, since there it is none set in the Main.storyboard
        // Also, hide potentially sensitive data of the real application screen during onboarding
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = FUIInfoViewController.createSplashScreenInstanceFromStoryboard()
        window!.makeKey()

        // Read more about Logging: https://help.sap.com/viewer/fc1a59c210d848babfb3f758a6f55cb1/Latest/en-US/879aaebaa8e6401dac100ea9bb8b817d.html
        Logger.root.logLevel = .debug

        // Customize the UI to align SAP style
        // Read more: https://help.sap.com/doc/978e4f6c968c4cc5a30f9d324aa4b1d7/Latest/en-US/Documents/Frameworks/SAPFiori/Extensions/UINavigationBar.html
        UIFont.registerFioriFonts()
        UINavigationBar.applyFioriStyle()
        UINavigationBar.appearance().isTranslucent = true

        initializeOnboarding()

        // MARK: - Widget feature

        registerBackgroundStepsTask()

        return true
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Hides the application UI by presenting a splash screen, @see: ApplicationUIManager.hideApplicationScreen
        OnboardingSessionManager.shared.lock { _ in }
        scheduleBackgroundStepsTask()
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Triggers to show the passcode screen
        OnboardingSessionManager.shared.unlock { error in
            guard let error = error else {
                return
            }

            self.onboardingErrorHandler?.handleUnlockingError(error)
        }
    }

    func applicationWillResignActive(_: UIApplication) {
        hideAppScreen()
    }

    func applicationDidBecomeActive(_: UIApplication) {
        showAppScreen()
    }

    func hideAppScreen() {
        guard coveringView == nil else {
            return
        }
        let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "LaunchScreen")
        coveringView = vc.view
        coveringView!.frame = window!.bounds
        coveringView!.alpha = 0
        window!.addSubview(coveringView!)
        window!.bringSubviewToFront(coveringView!)

        UIView.animate(withDuration: 0.3) {
            self.coveringView?.alpha = 1.0
        }
    }

    func showAppScreen() {
        UIView.animate(withDuration: 0.3) {
            self.coveringView?.alpha = 0
        } completion: { _ in
            self.coveringView?.removeFromSuperview()
            self.coveringView = nil
        }
    }

    // MARK: - UISplitViewControllerDelegate

    func splitViewController(_: UISplitViewController, collapseSecondary _: UIViewController, onto _: UIViewController) -> Bool {
        // The first Collection will be selected automatically, so we never discard showing the secondary ViewController
        return false
    }

    func application(_: UIApplication, supportedInterfaceOrientationsFor _: UIWindow?) -> UIInterfaceOrientationMask {
        // Onboarding is only supported in portrait orientation
        switch OnboardingFlowController.presentationState {
        case .onboarding, .restoring:
            return .portrait
        default:
            return .allButUpsideDown
        }
    }
}

// Convenience accessor for the AppDelegate
extension AppDelegate {
    static var shared: AppDelegate {
        return (UIApplication.shared.delegate as! AppDelegate)
    }
}

// MARK: – Onboarding related functionality

// MARK: OnboardingSessionManager helper extension

extension OnboardingSessionManager {
    static var shared: OnboardingSessionManager<ApplicationOnboardingSession>! {
        return AppDelegate.shared.sessionManager
    }
}

extension AppDelegate {
    /// Setup an onboarding session instance
    func initializeOnboarding() {
        let presentationDelegate = ApplicationUIManager(window: window!)
        onboardingErrorHandler = OnboardingErrorHandler()
        sessionManager = OnboardingSessionManager(presentationDelegate: presentationDelegate, flowProvider: flowProvider, delegate: onboardingErrorHandler)
        presentationDelegate.isOnboarding = true
        presentationDelegate.showSplashScreenForOnboarding { _ in }

        onboardUser()
    }

    /// Start demo mode
    func startDemoMode() {
        let alertController = UIAlertController(
            title: LocalizedStrings.AppDelegate.startDemoModeTitle,
            message: LocalizedStrings.AppDelegate.startDemoModeMessage,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: LocalizedStrings.AppDelegate.startDemoModeRestartTitle, style: .default) { _ in
                self.onboardUser()
            })

        DispatchQueue.main.async {
            guard let topViewController = ModalUIViewControllerPresenter.topPresentedViewController() else {
                fatalError("Invalid UI state")
            }
            topViewController.present(alertController, animated: true)
        }
    }

    /// Application specific code after successful onboard
    func afterOnboard() {
        guard let _ = sessionManager.onboardingSession else {
            fatalError("Invalid state")
        }

        WidgetCenter.shared.reloadTimelines(ofKind: AuxiliaryConfiguration.widgetKind)
        initializeRemoteNotification()
        uploadLogs()
        uploadUsageReport()
        uploadCrashReport()
    }

    /// Start onboarding a user
    func onboardUser() {
        sessionManager.open { error in
            if let error = error {
                self.onboardingErrorHandler?.handleOnboardingError(error)
                return
            }
            self.afterOnboard()
        }
    }
}

// MARK: - Background refresh task management and Widget data handler methods

extension AppDelegate {
    private func registerBackgroundStepsTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AuxiliaryConfiguration.backgroundStepsTaskId, using: nil) { task in
            // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
            self.initiateBackgroundStepsTask(task: task as! BGAppRefreshTask)
        }
    }

    private func initiateBackgroundStepsTask(task: BGAppRefreshTask) {
        // lets schedule a task first.
        scheduleBackgroundStepsTask()
        // lets process the steps
        let sessionManager = getBackgroundSessionManager()
        sessionManager.open(inBackground: true, completionHandler: { error in
            if let errorNotNil = error {
                self.logger.error("Error occured during background flow : ", error: errorNotNil)
                task.setTaskCompleted(success: false)

            } else {
                self.logger.info("Background flow completed successfully.")
                task.setTaskCompleted(success: true)
            }
        })

        task.expirationHandler = {
            task.setTaskCompleted(success: true)
        }
    }

    private func getBackgroundSessionManager() -> OnboardingSessionManager<OnboardingSession> {
        let onboardingManager = SingleUserOnboardingIDManager(backgroundMode: true)
        let controller: OnboardingControlling = OnboardingController(flowProvider: OnboardingFlowProvider(), onboardingIDManager: onboardingManager)
        let presentationDelegate = ApplicationUIManager(window: window!)
        return OnboardingSessionManager(onboardingController: controller, presentationDelegate: presentationDelegate)
    }

    func scheduleBackgroundStepsTask() {
        let request = BGAppRefreshTaskRequest(identifier: AuxiliaryConfiguration.backgroundStepsTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}

// MARK: - Remote notification handling

extension AppDelegate {
    // Read more about Remote Notifications on mobile services: https://help.sap.com/doc/978e4f6c968c4cc5a30f9d324aa4b1d7/Latest/en-US/Documents/Frameworks/SAPFoundation/Remote%20Notifications.html

    func initializeRemoteNotification() {
        // Registering for remote notifications
        UIApplication.shared.registerForRemoteNotifications()
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            // Enable or disable features based on authorization.
        }
        center.delegate = self
    }

    func uploadDeviceTokenForRemoteNotification(_ deviceToken: Data) {
        guard let session = sessionManager.onboardingSession else {
            // Onboarding not yet performed
            return
        }
        let parameters = SAPcpmsRemoteNotificationParameters(deviceType: "iOS")
        session.registerDeviceToken(deviceToken: deviceToken, withParameters: parameters) { error in
            if let error = error {
                self.logger.error("Register DeviceToken failed", error: error)
                return
            }
            self.logger.info("Register DeviceToken succeeded")
        }
    }

    // MARK: AppDelegate method implementations for remote notification handling

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        uploadDeviceTokenForRemoteNotification(deviceToken)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("Failed to register for Remote Notification", error: error)
    }

    // Called to let your app know which action was selected by the user for a given notification.
    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        logger.info("App opened via user selecting notification: \(response.notification.request.content.body)")
        // Here is where you want to take action to handle the notification, maybe navigate the user to a given screen.
        completionHandler()
    }

    // Called when a notification is delivered to a foreground app.
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.info("Remote Notification arrived while app was in foreground: \(notification.request.content.body)")
        // Currently we are presenting the notification alert as the application were in the background.
        // If you have handled the notification and do not want to display an alert, call the completionHandler with empty options: completionHandler([])
        completionHandler([.banner, .sound])
    }
}

// MARK: - Log upload initialization and handling

// Read more about Log upload: https://help.sap.com/doc/978e4f6c968c4cc5a30f9d324aa4b1d7/Latest/en-US/Documents/Frameworks/SAPFoundation/Log%20Upload.html
extension AppDelegate {
    private func initializeLogUploader() {
        do {
            // Attaches a LogUploadFileHandler instance to the root of the logging system
            try SAPcpmsLogUploader.attachToRootLogger()
        } catch {
            logger.error("Failed to attach to root logger.", error: error)
        }
    }

    private func uploadLogs() {
        guard let session = sessionManager.onboardingSession else {
            // Onboarding not yet performed
            return
        }
        // Upload logs after onboarding
        SAPcpmsLogUploader.uploadLogs(session) { error in
            if let error = error {
                self.logger.error("Error happened during log upload.", error: error)
                return
            }
            self.logger.info("Logs have been uploaded successfully.")
        }
    }
}

// MARK: - Usage collection initialization and upload

extension AppDelegate {
    private func initializeUsageCollection() {
        do {
            // Required call to configure OSlifecycle notification, specify data collection items during event triggers, and configure usage store behavior.
            try UsageBroker.shared.start()
        } catch {
            logger.error("Failed to initialize usage collection.", error: error)
        }
    }

    private func uploadUsageReport() {
        guard sessionManager.onboardingSession != nil else {
            // Onboarding not yet performed
            return
        }
        // Upload usage report after onboarding
        UsageBroker.shared.upload()
    }
}

// MARK: - Crash report upload

extension AppDelegate {
    private func uploadCrashReport() {
        guard let session = sessionManager.onboardingSession else {
            // Onboarding not yet performed
            return
        }
        guard let settingsParameters = session.settingsParameters else {
            return
        }
        // Upload crash logs after onboarding
        SAPCrashReporter.shared.uploadCrashFile(sapURLSession: session.sapURLSession, settingsParameters: settingsParameters)
    }
}

// MARK: - Deep linking

extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return decideFlow(forApplication: app, from: url)
    }

    func decideFlow(forApplication _: UIApplication, from incomingURL: URL) -> Bool {
        func showFailureAlert(title: String, message: String) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalizedStrings.AppDelegate.urlNotSupportedOKButtonTitle, style: .default, handler: nil))
            DispatchQueue.main.async {
                guard let topViewController = ModalUIViewControllerPresenter.topPresentedViewController() else {
                    fatalError("Invalid UI state")
                }
                topViewController.present(alertController, animated: true)
            }
        }

        if incomingURL.absoluteString.range(of: "/action=view") != nil ||
            incomingURL.absoluteString == "\(AuxiliaryConfiguration.scheme)://"
        {
            return Deeplinker().handle(incomingURL)
        } else {
            showFailureAlert(title: LocalizedStrings.AppDelegate.urlNotSupportedTitle, message: LocalizedStrings.AppDelegate.urlNotSupportedMessage)
            return false
        }
    }
}
