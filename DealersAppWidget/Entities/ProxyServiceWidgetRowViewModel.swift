//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import ProxyServiceFmwk

extension ProxyServiceFmwk.CurrentSolicitations: WidgetRowViewModel {
    public var value: String { "\(matnr!), \(vbeln!), \(posnr!), \(kunnr!)" }
    public var key: String { "Matnr, Vbeln, Posnr, Kunnr" }
    public var image: String? { nil }
}

extension ProxyServiceFmwk.RejectionCodes: WidgetRowViewModel {
    public var value: String { "\(rejectionCode!)" }
    public var key: String { "RejectionCode" }
    public var image: String? { nil }
}

extension ProxyServiceFmwk.Material: WidgetRowViewModel {
    public var value: String { "\(sku!)" }
    public var key: String { "SKU" }
    public var image: String? { nil }
}

extension ProxyServiceFmwk.ShipClose: WidgetRowViewModel {
    public var value: String { "\(matnr!), \(vbeln!), \(posnr!), \(kunnr!)" }
    public var key: String { "Matnr, Vbeln, Posnr, Kunnr" }
    public var image: String? { nil }
}
