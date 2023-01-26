//
//  ViewController.swift
//  DiffableDatasourceAndCoreData
//
//  Created by Stefan Schmitt on 23/01/2023.
//

import CoreData
import UIKit


final class SingleEntitySingleSectionViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case main
        case secondary
    }
    
    private enum ListItemType: Hashable {
        case memory(id: NSManagedObjectID)
    }

    private typealias SectionItem = Section
    private typealias ListItemID = ListItemType
    private typealias DataSource = UICollectionViewDiffableDataSource<SectionItem, ListItemID>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionItem, ListItemID>
    
    private var dataSource: UICollectionViewDiffableDataSource<SectionItem, ListItemID>! = nil
    private weak var collectionView: UICollectionView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureDataSource()
        setInitialData()
    }

}

extension SingleEntitySingleSectionViewController {
    private func configureHierarchy() {
        let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        self.collectionView = collectionView
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func configureDataSource() {
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, NSManagedObjectID> { cell, _, id in
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { assertionFailure(); return; }
            let managedContext = appDelegate.persistentContainer.viewContext
            let request = Memory.fetchRequest()
            request.predicate = NSPredicate(format: "SELF == %@", id)
            request.fetchLimit = 1
            do {
                guard let result = try managedContext.fetch(request).first else { assertionFailure(); return; }
                
                var configuration = cell.defaultContentConfiguration()
                configuration.text = result.title
                cell.contentConfiguration = configuration
            } catch let error as NSError {
                print("Failed to fetch entity: \(error). \(error.userInfo)")
            }
        }
        
        dataSource = DataSource(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, itemID: ListItemID) -> UICollectionViewCell? in
            switch itemID {
            case .memory(let id):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: id)
            }
        }
        
    }
    
    private func setInitialData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = Memory.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "type", ascending: true)
        ]

        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: managedContext,
                                             sectionNameKeyPath: "type",
                                             cacheName: nil)
        frc.delegate = self
        do {
            try frc.performFetch()
        } catch let error as NSError {
            print("Failed to fetch entities: \(error). \(error.userInfo)")
        }
    }
}

extension SingleEntitySingleSectionViewController: UICollectionViewDelegate {
    
}

extension SingleEntitySingleSectionViewController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
        let databaseSnapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        
        var newSnapshot = Snapshot()
        for sectionIdentifier in databaseSnapshot.sectionIdentifiers {
            let items = databaseSnapshot.itemIdentifiers(inSection: sectionIdentifier)
            let section: Section
            switch sectionIdentifier {
            case "0":
                section = .main
                
            case "1":
                section = .secondary
                
            default:
                assertionFailure()
                return
            }
            newSnapshot.appendSections([section])
            newSnapshot.appendItems(items.compactMap(convertToListItemID(using:)), toSection: section)
        }
        
        dataSource.apply(newSnapshot, animatingDifferences: true, completion: nil)
    }
    
    private func convertToListItemID(using id: NSManagedObjectID) -> ListItemID {
        return ListItemType.memory(id: id)
    }
}
