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

class RejectionCodesMasterViewController: FUIFormTableViewController, SAPFioriLoadingIndicator {
    var dataService: ProxyService!
    public var loadEntitiesBlock: (() async throws -> [ProxyServiceFmwk.RejectionCodes])?
    private var entities: [ProxyServiceFmwk.RejectionCodes] = .init()
    private let logger = Logger.shared(named: "RejectionCodesMasterViewControllerLogger")
    private let okTitle = NSLocalizedString("keyOkButtonTitle",
                                            value: "OK",
                                            comment: "XBUT: Title of OK button.")
    var loadingIndicator: FUILoadingIndicatorView?
    private let dispatchGroup = DispatchGroup()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Add refreshcontrol UI
        refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl!)
        // Cell height settings
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 98
        updateTable()
    }

    var preventNavigationLoop = false
    var entitySetName: String?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return entities.count
    }

    override func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rejectionCodes = entities[indexPath.row]

        let cell = CellCreationHelper.objectCellWithNonEditableContent(tableView: tableView, indexPath: indexPath, key: "RejectionCode", value: "\(rejectionCodes.rejectionCode!)")
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        let currentEntity = entities[indexPath.row]
        Task.init {
            do {
                try await self.dataService.deleteEntity(currentEntity)
            } catch {
                self.logger.error("Delete entry failed.", error: error)
                AlertHelper.displayAlert(with: NSLocalizedString("keyErrorDeletingEntryTitle", value: "Delete entry failed", comment: "XTIT: Title of deleting entry error pop up."), error: error, viewController: self)
                return
            }
            self.reloadWidget()
            self.entities.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
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

    // MARK: - Data accessing

    func requestEntities() async throws {
        entities = try await loadEntitiesBlock!().sorted(by: { ($0.rejectionCode!) < ($1.rejectionCode!) })
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "showDetail" {
            // Show the selected Entity on the Detail view
            guard let indexPath = tableView.indexPathForSelectedRow else {
                return
            }
            logger.info("Showing details of the chosen element.")
            let selectedEntity = entities[indexPath.row]
            let detailViewController = segue.destination as! RejectionCodesDetailViewController
            detailViewController.entity = selectedEntity
            detailViewController.navigationItem.leftItemsSupplementBackButton = true
            detailViewController.navigationItem.title = entities[(tableView.indexPathForSelectedRow?.row)!].rejectionCode ?? ""
            detailViewController.allowsEditableCells = false
            detailViewController.tableUpdater = self
            detailViewController.preventNavigationLoop = preventNavigationLoop
            detailViewController.dataService = dataService
            detailViewController.entitySetName = entitySetName
        } else if segue.identifier == "addEntity" {
            // Show the Detail view with a new Entity, which can be filled to create on the server
            logger.info("Showing view to add new entity.")
            let dest = segue.destination as! UINavigationController
            let detailViewController = dest.viewControllers[0] as! RejectionCodesDetailViewController
            detailViewController.title = NSLocalizedString("keyAddEntityTitle", value: "Add Entity", comment: "XTIT: Title of add new entity screen.")
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: detailViewController, action: #selector(detailViewController.createEntity))
            detailViewController.navigationItem.rightBarButtonItem = doneButton
            let cancelButton = UIBarButtonItem(title: NSLocalizedString("keyCancelButtonToGoPreviousScreen", value: "Cancel", comment: "XBUT: Title of Cancel button."), style: .plain, target: detailViewController, action: #selector(detailViewController.cancel))
            detailViewController.navigationItem.leftBarButtonItem = cancelButton
            detailViewController.allowsEditableCells = true
            detailViewController.tableUpdater = self
            detailViewController.dataService = dataService
            detailViewController.entitySetName = entitySetName
        }
    }

    // MARK: - Table update

    func updateTable() {
        showFioriLoadingIndicator()
        Task.detached {
            await self.loadData()
            self.hideFioriLoadingIndicator()
        }
    }

    private func loadData() async {
        do {
            try await requestEntities()
        } catch {
            AlertHelper.displayAlert(with: NSLocalizedString("keyErrorLoadingData", value: "Loading data failed!", comment: "XTIT: Title of loading data error pop up."), error: error, viewController: self)
            logger.error("Could not update table.", error: error)
            return
        }
        await MainActor.run {
            self.tableView.reloadData()
            self.logger.info("Table updated successfully!")
        }
    }

    @objc func refresh() {
        Task.detached {
            await self.loadData()
            await MainActor.run {
                self.refreshControl?.endRefreshing()
            }
        }
    }
}

extension RejectionCodesMasterViewController: ProxyServiceEntitySetUpdaterDelegate {
    func entitySetHasChanged() {
        updateTable()
    }
}
