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
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, NSManagedObjectID> { ell, _, id in
            
        }
        
        dataSource = DataSource(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, itemID: ListItemID) -> UICollectionViewCell? in
            switch itemID {
            case .memory(let id):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: id)
            }
        }
        
    }
    
    private func setInitialData() {
        Memory.fetchRequest()
        
//        let frc = NSFetchedResultsController(fetchRequest: ,
//                                             managedObjectContext: ,
//                                             sectionNameKeyPath: ,
//                                             cacheName: nil)
//        do {
//            try frc.performFetch()
//        } catch let error {
//            fatalError("Failed to fetch entities: \(error.localizedDescription)")
//        }
    }
}

extension SingleEntitySingleSectionViewController: UICollectionViewDelegate {
    
}

extension SingleEntitySingleSectionViewController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
    }
}
