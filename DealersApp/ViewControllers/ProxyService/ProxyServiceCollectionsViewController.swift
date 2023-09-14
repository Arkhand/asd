//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import SAPFiori
import SAPFioriFlows
import SAPFoundation
import SAPOData

import ProxyServiceFmwk
import SharedFmwk

protocol ProxyServiceEntityUpdaterDelegate {
    func entityHasChanged(_ entity: EntityValue?)
}

protocol ProxyServiceEntityMediaUpdaterDelegate {
    func entityMediaHasChanged(_ changedMedia: Data?)
}

protocol ProxyServiceEntitySetUpdaterDelegate {
    func entitySetHasChanged()
}

protocol ProxyServiceEntitySetMediaUpdaterDelegate {
    func entitySetMediaHasChanged(for entity: EntityValue?, to media: Data?)
}

class ProxyServiceCollectionsViewController: FUIFormTableViewController {
    private var collections = ProxyServiceCollectionType.allCases

    // Variable to store the selected index path
    private var selectedIndex: IndexPath?

    private let okTitle = NSLocalizedString("keyOkButtonTitle",
                                            value: "OK",
                                            comment: "XBUT: Title of OK button.")

    var isPresentedInSplitView: Bool {
        return !(self.splitViewController?.isCollapsed ?? true)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 320, height: 480)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        makeSelection()

        Deeplinker.Navigator.shared.check(destination: .proxyService, screen: .entitiyList, moveForwardDoing: { _, screen in
            switch screen {
            case let .named(entityName):
                if let value = ProxyServiceCollectionType(rawValue: entityName),
                   let index = self.collections.firstIndex(of: value)
                {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.collectionSelected(at: indexPath)
                }

            default: break
            }
        })
    }

    override func viewWillTransition(to _: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            let isNotInSplitView = !self.isPresentedInSplitView
            self.tableView.visibleCells.forEach { cell in
                // To refresh the disclosure indicator of each cell
                cell.accessoryType = isNotInSplitView ? .disclosureIndicator : .none
            }
            self.makeSelection()
        })
    }

    // MARK: - UITableViewDelegate

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return collections.count
    }

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FUIObjectTableViewCell.reuseIdentifier, for: indexPath) as! FUIObjectTableViewCell
        cell.headlineLabel.text = collections[indexPath.row].description
        cell.accessoryType = !isPresentedInSplitView ? .disclosureIndicator : .none
        cell.isMomentarySelection = false
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        collectionSelected(at: indexPath)
    }

    // CollectionType selection helper
    private func collectionSelected(at indexPath: IndexPath) {
        // Load the EntityType specific ViewController from the specific storyboard"
        var masterViewController: UIViewController!
        guard let odataController = OnboardingSessionManager.shared.onboardingSession?.odataControllers[ODataContainerType.proxyService.description] as? ProxyServiceOnlineODataController, let dataService = odataController.dataService else {
            AlertHelper.displayAlert(with: "OData service is not reachable, please onboard again.", error: nil, viewController: self)
            return
        }
        selectedIndex = indexPath

        switch collections[indexPath.row] {
        case .rejectionCodes:
            let rejectionCodesStoryBoard = UIStoryboard(name: "RejectionCodes", bundle: nil)
            let rejectionCodesMasterViewController = rejectionCodesStoryBoard.instantiateViewController(withIdentifier: "RejectionCodesMaster") as! RejectionCodesMasterViewController
            rejectionCodesMasterViewController.dataService = dataService
            rejectionCodesMasterViewController.entitySetName = "RejectionCodes"
            func fetchRejectionCodes() async throws -> [ProxyServiceFmwk.RejectionCodes] {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    return try await dataService.fetchRejectionCodes(matching: query)
                }
            }
            rejectionCodesMasterViewController.loadEntitiesBlock = fetchRejectionCodes
            rejectionCodesMasterViewController.navigationItem.title = "RejectionCodes"
            masterViewController = rejectionCodesMasterViewController
        case .material:
            let materialStoryBoard = UIStoryboard(name: "Material", bundle: nil)
            let materialMasterViewController = materialStoryBoard.instantiateViewController(withIdentifier: "MaterialMaster") as! MaterialMasterViewController
            materialMasterViewController.dataService = dataService
            materialMasterViewController.entitySetName = "Material"
            func fetchMaterial() async throws -> [ProxyServiceFmwk.Material] {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    return try await dataService.fetchMaterial(matching: query)
                }
            }
            materialMasterViewController.loadEntitiesBlock = fetchMaterial
            materialMasterViewController.navigationItem.title = "Material"
            masterViewController = materialMasterViewController
        case .shipClose:
            let shipCloseStoryBoard = UIStoryboard(name: "ShipClose", bundle: nil)
            let shipCloseMasterViewController = shipCloseStoryBoard.instantiateViewController(withIdentifier: "ShipCloseMaster") as! ShipCloseMasterViewController
            shipCloseMasterViewController.dataService = dataService
            shipCloseMasterViewController.entitySetName = "ShipClose"
            func fetchShipClose() async throws -> [ProxyServiceFmwk.ShipClose] {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    return try await dataService.fetchShipClose(matching: query)
                }
            }
            shipCloseMasterViewController.loadEntitiesBlock = fetchShipClose
            shipCloseMasterViewController.navigationItem.title = "ShipClose"
            masterViewController = shipCloseMasterViewController
        case .currentSolicitations:
            let currentSolicitationsStoryBoard = UIStoryboard(name: "CurrentSolicitations", bundle: nil)
            let currentSolicitationsMasterViewController = currentSolicitationsStoryBoard.instantiateViewController(withIdentifier: "CurrentSolicitationsMaster") as! CurrentSolicitationsMasterViewController
            currentSolicitationsMasterViewController.dataService = dataService
            currentSolicitationsMasterViewController.entitySetName = "CurrentSolicitations"
            func fetchCurrentSolicitations() async throws -> [ProxyServiceFmwk.CurrentSolicitations] {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    return try await dataService.fetchCurrentSolicitations(matching: query)
                }
            }
            currentSolicitationsMasterViewController.loadEntitiesBlock = fetchCurrentSolicitations
            currentSolicitationsMasterViewController.navigationItem.title = "CurrentSolicitations"
            masterViewController = currentSolicitationsMasterViewController
        @unknown default:
            masterViewController = UIViewController()
        }

        // Load the NavigationController and present with the EntityType specific ViewController
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let rightNavigationController = mainStoryBoard.instantiateViewController(withIdentifier: "RightNavigationController") as! UINavigationController
        rightNavigationController.viewControllers = [masterViewController]
        splitViewController?.showDetailViewController(rightNavigationController, sender: nil)
    }

    // MARK: - Handle highlighting of selected cell

    private func makeSelection() {
        if let selectedIndex = selectedIndex {
            tableView.selectRow(at: selectedIndex, animated: true, scrollPosition: .none)
            tableView.scrollToRow(at: selectedIndex, at: .none, animated: true)
        } else {
            selectDefault()
        }
    }

    private func selectDefault() {
        // Automatically select first element if we have two panels (iPhone plus and iPad only)
        guard let odataController = OnboardingSessionManager.shared.onboardingSession?.odataControllers[ODataContainerType.proxyService.description] as? ProxyServiceOnlineODataController else {
            AlertHelper.displayAlert(with: "OData service is not reachable, please onboard again.", error: nil, viewController: self)
            return
        }

        if splitViewController!.isCollapsed || odataController.dataService == nil {
            return
        }
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        collectionSelected(at: indexPath)
    }

    static func entitySet(withName entitySetName: String?) -> EntitySet? {
        switch entitySetName {
        case "RejectionCodes": return ProxyServiceMetadata.EntitySets.rejectionCodes
        case "Material": return ProxyServiceMetadata.EntitySets.material
        case "ShipClose": return ProxyServiceMetadata.EntitySets.shipClose
        case "CurrentSolicitations": return ProxyServiceMetadata.EntitySets.currentSolicitations
        default: return nil
        }
    }
}
