//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import SwiftUI
import WidgetKit

@main
struct DealersAppWidget: Widget {
    var widgetConfig = WidgetConfigurationProvider()
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: widgetConfig.kind(), intent: DynamicDestinationSelectionIntent.self, provider: WidgetIntentTimelineProvider()) { entry in
            DealersAppWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(widgetConfig.configurationDisplayName())
        .description(widgetConfig.description())
        .supportedFamilies(widgetConfig.supportedFamilies)
    }
}
