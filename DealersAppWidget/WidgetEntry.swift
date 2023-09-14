//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import UIKit
import WidgetKit

struct WidgetEntry: TimelineEntry {
    var date: Date
    let values: [WidgetRowViewModel]
    var title: String
    var listPath = ""

    init(date: Date = Date(),
         title: String,
         values: [WidgetRowViewModel])
    {
        self.date = date
        self.values = values
        self.title = title
    }
}
