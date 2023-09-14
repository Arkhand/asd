//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import ProxyServiceFmwk
import SAPCommon
import SAPFiori
import SAPFioriFlows
import SAPFoundation
import SAPOData
import SharedFmwk
import WidgetKit

class ShipCloseDetailViewController: FUIFormTableViewController, SAPFioriLoadingIndicator {
    var dataService: ProxyService!
    private var validity = [String: Bool]()
    var allowsEditableCells = false

    private var _entity: ProxyServiceFmwk.ShipClose?
    var entity: ProxyServiceFmwk.ShipClose {
        get {
            if _entity == nil {
                _entity = createEntityWithDefaultValues()
            }
            return _entity!
        }
        set {
            _entity = newValue
        }
    }

    private let logger = Logger.shared(named: "ShipCloseMasterViewControllerLogger")
    var loadingIndicator: FUILoadingIndicatorView?
    var entityUpdater: ProxyServiceEntityUpdaterDelegate?
    var tableUpdater: ProxyServiceEntitySetUpdaterDelegate?
    private let okTitle = NSLocalizedString("keyOkButtonTitle",
                                            value: "OK",
                                            comment: "XBUT: Title of OK button.")
    var preventNavigationLoop = false
    var entitySetName: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        tableView.register(FUIDatePickerFormCell.self, forCellReuseIdentifier: FUIDatePickerFormCell.reuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "updateEntity" {
            // Show the Detail view with the current entity, where the properties scan be edited and updated
            logger.info("Showing a view to update the selected entity.")
            let dest = segue.destination as! UINavigationController
            let detailViewController = dest.viewControllers[0] as! ShipCloseDetailViewController
            detailViewController.title = NSLocalizedString("keyUpdateEntityTitle", value: "Update Entity", comment: "XTIT: Title of update selected entity screen.")
            detailViewController.dataService = dataService
            detailViewController.entity = entity
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: detailViewController, action: #selector(detailViewController.updateEntity))
            detailViewController.navigationItem.rightBarButtonItem = doneButton
            let cancelButton = UIBarButtonItem(title: NSLocalizedString("keyCancelButtonToGoPreviousScreen", value: "Cancel", comment: "XBUT: Title of Cancel button."), style: .plain, target: detailViewController, action: #selector(detailViewController.cancel))
            detailViewController.navigationItem.leftBarButtonItem = cancelButton
            detailViewController.allowsEditableCells = true
            detailViewController.entityUpdater = self
            detailViewController.tableUpdater = tableUpdater
            detailViewController.entitySetName = entitySetName
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return cellForMatnr(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.matnr)
        case 1:
            return cellForVbeln(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.vbeln)
        case 2:
            return cellForPosnr(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.posnr)
        case 3:
            return cellForKunnr(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.kunnr)
        case 4:
            return cellForName1(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.name1)
        case 5:
            return cellForKwmeng(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.kwmeng)
        case 6:
            return cellForKbmeng(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.kbmeng)
        case 7:
            return cellForTimeoutDate(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.timeoutDate)
        case 8:
            return cellForStatus(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.status)
        case 9:
            return cellForKdmat(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.kdmat)
        case 10:
            return cellForTrackingNo(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.trackingNo)
        case 11:
            return cellForFedex(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.fedex)
        case 12:
            return cellForWillcall(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.willcall)
        case 13:
            return cellForDispPacklist(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.dispPacklist)
        case 14:
            return cellForDispFedexLabel(tableView: tableView, indexPath: indexPath, currentEntity: entity, property: ShipClose.dispFedexLabel)
        default:
            return UITableViewCell()
        }
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 15
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        if preventNavigationLoop {
            AlertHelper.displayAlert(with: NSLocalizedString("keyAlertNavigationLoop", value: "No further navigation is possible.", comment: "XTIT: Title of alert message about preventing navigation loop."), error: nil, viewController: self)
            return
        }
        switch indexPath.row {
        default:
            return
        }
    }

    // MARK: - OData property specific cell creators

    private func cellForMatnr(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.matnr {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.matnr = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.matnr.isOptional || newValue != "" {
                        currentEntity.matnr = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForVbeln(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.vbeln {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.vbeln = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.vbeln.isOptional || newValue != "" {
                        currentEntity.vbeln = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForPosnr(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.posnr {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.posnr = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.posnr.isOptional || newValue != "" {
                        currentEntity.posnr = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForKunnr(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.kunnr {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.kunnr = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.kunnr.isOptional || newValue != "" {
                        currentEntity.kunnr = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForName1(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.name1 {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.name1 = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.name1.isOptional || newValue != "" {
                        currentEntity.name1 = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForKwmeng(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.kwmeng {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.kwmeng = nil
                    isNewValueValid = true
                } else {
                    if let validValue = BigDecimal.parse(newValue) {
                        currentEntity.kwmeng = validValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForKbmeng(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.kbmeng {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.kbmeng = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.kbmeng.isOptional || newValue != "" {
                        currentEntity.kbmeng = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForTimeoutDate(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.timeoutDate {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.timeoutDate = nil
                    isNewValueValid = true
                } else {
                    if let validValue = GlobalDateTime.parse(newValue) { // This is just a simple solution to handle UTC only
                        currentEntity.timeoutDate = validValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForStatus(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.status {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.status = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.status.isOptional || newValue != "" {
                        currentEntity.status = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForKdmat(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.kdmat {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.kdmat = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.kdmat.isOptional || newValue != "" {
                        currentEntity.kdmat = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForTrackingNo(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.trackingNo {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.trackingNo = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.trackingNo.isOptional || newValue != "" {
                        currentEntity.trackingNo = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForFedex(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.fedex {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.fedex = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.fedex.isOptional || newValue != "" {
                        currentEntity.fedex = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForWillcall(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.willcall {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.willcall = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.willcall.isOptional || newValue != "" {
                        currentEntity.willcall = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForDispPacklist(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.dispPacklist {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.dispPacklist = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.dispPacklist.isOptional || newValue != "" {
                        currentEntity.dispPacklist = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    private func cellForDispFedexLabel(tableView: UITableView, indexPath: IndexPath, currentEntity: ProxyServiceFmwk.ShipClose, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.dispFedexLabel {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: entity, property: property, value: value, editingIsAllowed: allowsEditableCells, changeHandler:
            { (newValue: String) -> Bool in
                var isNewValueValid = false
                // The property is optional, so nil value can be accepted
                if newValue.isEmpty {
                    currentEntity.dispFedexLabel = nil
                    isNewValueValid = true
                } else {
                    if ShipClose.dispFedexLabel.isOptional || newValue != "" {
                        currentEntity.dispFedexLabel = newValue
                        isNewValueValid = true
                    }
                }
                self.validity[property.name] = isNewValueValid
                self.barButtonShouldBeEnabled()
                return isNewValueValid
            })
    }

    // MARK: - OData functionalities

    @objc func createEntity() {
        showFioriLoadingIndicator()
        view.endEditing(true)
        logger.info("Creating entity in backend.")
        Task.init {
            do {
                try await self.dataService.createEntity(self.entity)
                self.hideFioriLoadingIndicator()
            } catch {
                self.logger.error("Create entry failed. Error: \(error)", error: error)
                AlertHelper.displayAlert(with: NSLocalizedString("keyErrorEntityCreationTitle", value: "Create entry failed", comment: "XTIT: Title of alert message about entity creation error."), error: error, viewController: self)
                return
            }
            self.reloadWidget()
            self.logger.info("Create entry finished successfully.")
            await MainActor.run {
                self.dismiss(animated: true) {
                    FUIToastMessage.show(message: NSLocalizedString("keyEntityCreationBody", value: "Created", comment: "XMSG: Title of alert message about successful entity creation."))
                    self.tableUpdater?.entitySetHasChanged()
                }
            }
        }
    }

    func createEntityWithDefaultValues() -> ProxyServiceFmwk.ShipClose {
        let newEntity = ProxyServiceFmwk.ShipClose()

        // Key properties without default value should be invalid by default for Create scenario
        if newEntity.matnr == nil || newEntity.matnr!.isEmpty {
            validity["Matnr"] = false
        }
        if newEntity.vbeln == nil || newEntity.vbeln!.isEmpty {
            validity["Vbeln"] = false
        }
        if newEntity.posnr == nil || newEntity.posnr!.isEmpty {
            validity["Posnr"] = false
        }
        if newEntity.kunnr == nil || newEntity.kunnr!.isEmpty {
            validity["Kunnr"] = false
        }

        barButtonShouldBeEnabled()
        return newEntity
    }

    @objc func updateEntity(_: AnyObject) {
        showFioriLoadingIndicator()
        view.endEditing(true)
        logger.info("Updating entity in backend.")
        Task.init {
            do {
                try await self.dataService.updateEntity(self.entity)
                self.hideFioriLoadingIndicator()
            } catch {
                self.logger.error("Update entry failed. Error: \(error)", error: error)
                AlertHelper.displayAlert(with: NSLocalizedString("keyErrorEntityUpdateTitle", value: "Update entry failed", comment: "XTIT: Title of alert message about entity update failure."), error: error, viewController: self)
                return
            }
            self.reloadWidget()
            self.logger.info("Update entry finished successfully.")
            await MainActor.run {
                self.dismiss(animated: true) {
                    FUIToastMessage.show(message: NSLocalizedString("keyUpdateEntityFinishedTitle", value: "Updated", comment: "XTIT: Title of alert message about successful entity update."))
                    self.entityUpdater?.entityHasChanged(self.entity)
                }
            }
        }
    }

    // MARK: - other logic, helper

    @objc func cancel() {
        showFioriLoadingIndicator()
        view.endEditing(true)
        Task.init {
            do {
                try await dataService.loadEntity(entity)
            } catch {
                self.logger.warn("Load entity failed on cancel. Shown cached data may not be reflective of the backend.")
            }
            self.hideFioriLoadingIndicator()
            await MainActor.run {
                self.dismiss(animated: true)
            }
        }
    }

    // Check if all text fields are valid
    private func barButtonShouldBeEnabled() {
        let anyFieldInvalid = validity.values.first { field in
            field == false
        }
        navigationItem.rightBarButtonItem?.isEnabled = anyFieldInvalid == nil
    }

    func reloadWidget() {
        var cipher: Ciphering
        do {
            let auxDataEncryptionKey = try SecurityManager().getAuxiliaryDataEncryptionKey()
            cipher = CryptoProvider(with: auxDataEncryptionKey, tag: AuxiliaryConfiguration.cryptoProviderTag)
        } catch {
            fatalError("No auxiliary data encryption key found!")
        }

        guard let odataController = OnboardingSessionManager.shared.onboardingSession?.odataControllers[ODataContainerType.proxyService.description] as? ProxyServiceOnlineODataController,
              let widgetDataLoader = ProxyServiceWidgetDataLoader(controller: odataController, with: cipher),
              let entitySetName = entitySetName
        else {
            return
        }

        Task.detached {
            let status = await widgetDataLoader.loadEntitySet(for: entitySetName)
            if status {
                WidgetCenter.shared.reloadTimelines(ofKind: AuxiliaryConfiguration.widgetKind)
            }
        }
    }
}

extension ShipCloseDetailViewController: ProxyServiceEntityUpdaterDelegate {
    func entityHasChanged(_ entityValue: EntityValue?) {
        if let entity = entityValue {
            let currentEntity = entity as! ProxyServiceFmwk.ShipClose
            self.entity = currentEntity
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
}
