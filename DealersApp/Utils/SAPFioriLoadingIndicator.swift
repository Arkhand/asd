
//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SAPFiori

protocol SAPFioriLoadingIndicator: AnyObject {
    var loadingIndicator: FUILoadingIndicatorView? { get set }
}

extension SAPFioriLoadingIndicator where Self: UIViewController {
    func showFioriLoadingIndicator(_ message: String = "") {
        DispatchQueue.main.async {
            if let loadingIndicator = self.loadingIndicator, loadingIndicator.isAnimating {
                return
            }
            let window = self.view.window
            let indicator = FUILoadingIndicatorView(frame: self.view.frame)
            indicator.text = message
            window?.addSubview(indicator)
            indicator.show()
            self.loadingIndicator = indicator
        }
    }

    func hideFioriLoadingIndicator() {
        DispatchQueue.main.async {
            guard let loadingIndicator = self.loadingIndicator, loadingIndicator.isAnimating else {
                return
            }
            loadingIndicator.dismiss()
        }
    }
}
