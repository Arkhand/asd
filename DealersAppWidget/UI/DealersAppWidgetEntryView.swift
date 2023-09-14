//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SwiftUI

struct DealersAppWidgetEntryView: View {
    var entry: WidgetIntentTimelineProvider.Entry
    var body: some View {
        ZStack {
            Color("bgColor")
            VStack {
                WidgetEntryView(data: entry.values,
                                title: entry.title,
                                listPath: entry.listPath)
            }
        }
    }
}
