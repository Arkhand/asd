//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        guard intent is DynamicDestinationSelectionIntent else {
            fatalError("Unhandled Intent error : \(intent)")
        }
        return DynamicDestinationSelectionIntentHandler()
    }
}
