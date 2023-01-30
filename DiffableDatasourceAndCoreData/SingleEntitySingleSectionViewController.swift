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
    
    private var sectionTitles: [Section: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureDataSource()
        setInitialData()
    }

}

extension SingleEntitySingleSectionViewController {
    private func configureHierarchy() {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
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
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 5
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .estimated(44))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [sectionHeader]

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
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



final class TitleSupplementaryView: UICollectionReusableView {
    let label = UILabel()
    static let reuseIdentifier = "title-supplementary-reuse-identifier"

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}

extension TitleSupplementaryView {
    func configure() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        let inset = CGFloat(10)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])
        label.font = UIFont.preferredFont(forTextStyle: .title3)
    }
}
