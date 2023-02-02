//
//  ViewController.swift
//  DiffableDatasourceAndCoreData
//
//  Created by Stefan Schmitt on 23/01/2023.
//

import CoreData
import UIKit


final class SingleEntitySingleSectionViewController: ListCollectionViewController {

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
    
    private var sectionTitles: [Section: String] = [:]
    private var frc: NSFetchedResultsController<Memory>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        setInitialData()
        self.collectionView.delegate = self
    }
}

extension SingleEntitySingleSectionViewController {
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
                configuration.textProperties.lineBreakMode = .byWordWrapping
                configuration.textProperties.numberOfLines = 2
                cell.contentConfiguration = configuration
            } catch let error as NSError {
                print("Failed to fetch entity: \(error). \(error.userInfo)")
            }
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<TitleSupplementaryView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] (sectionHeaderView, string, indexPath) in
            guard let section: Section = Section.allCases[safe: indexPath.section] else { assertionFailure(); return; }
            guard let sectionTitle = self?.sectionTitles[section] else { assertionFailure(); return; }
            sectionHeaderView.label.text = sectionTitle
        }
        
        dataSource = DataSource(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, itemID: ListItemID) -> UICollectionViewCell? in
            switch itemID {
            case .memory(let id):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: id)
            }
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            return self?.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
        }
    }
    
    private func setInitialData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = Memory.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "type", ascending: true)
        ]

        frc = NSFetchedResultsController(fetchRequest: fetchRequest,
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

extension SingleEntitySingleSectionViewController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
        let databaseSnapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        
        var newSnapshot = Snapshot()
        for (i, sectionIdentifier) in databaseSnapshot.sectionIdentifiers.enumerated() {
            let items = databaseSnapshot.itemIdentifiers(inSection: sectionIdentifier)
            guard let section: Section = Section.allCases[safe: i] else { assertionFailure(); continue; }
            sectionTitles[section] = sectionIdentifier
            newSnapshot.appendSections([section])
            newSnapshot.appendItems(items.compactMap(convertToListItemID(using:)), toSection: section)
        }
        
        dataSource.apply(newSnapshot, animatingDifferences: true, completion: nil)
    }
    
    private func convertToListItemID(using id: NSManagedObjectID) -> ListItemID {
        return ListItemType.memory(id: id)
    }
}

extension SingleEntitySingleSectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = frc.object(at: indexPath)
        
        let webVc = WebViewController()
        guard let url = memory.photoURI else { assertionFailure(); return; }
        webVc.urlToLoad = url
        navigationController?.pushViewController(webVc, animated: true)
    }
}
