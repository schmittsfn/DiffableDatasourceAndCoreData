//
//  AppDelegate.swift
//  DiffableDatasourceAndCoreData
//
//  Created by Stefan Schmitt on 23/01/2023.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let videoUrls: [[String: String]] = [
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 1)",
            "type": "First half",
            "url": "https://youtu.be/ANBGkZwOX68"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 2)",
            "type": "First half",
            "url": "https://youtu.be/FP9_xIqeY04"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 3)",
            "type": "First half",
            "url": "https://youtu.be/0yHPJjrmY9M"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 4)",
            "type": "First half",
            "url": "https://youtu.be/i140FFzKwHM"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 5)",
            "type": "First half",
            "url": "https://youtu.be/-c37LBSJrA0"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 6)",
            "type": "Second half",
            "url": "https://youtu.be/RlHwBtO65GI"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 7)",
            "type": "Second half",
            "url": "https://youtu.be/ZSvNcpWSccE"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 8)",
            "type": "Second half",
            "url": "https://youtu.be/_crNfAd86bc"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 9)",
            "type": "Second half",
            "url": "https://youtu.be/DGyK0es9ZQg"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 10)",
            "type": "Second half",
            "url": "https://youtu.be/ojIhjb8J7fU"
        ],
        [
            "title": "Afternoon walk in Chamonix, France, in winter (part 11)",
            "type": "Second half",
            "url": "https://youtu.be/swI3Mp_Ofqk"
        ],
    ]
    
    private let kFirstTimeLaunch = "firsttimelaunch"
    
    private func setInitialData() {
        guard !UserDefaults.standard.bool(forKey: kFirstTimeLaunch) else { return }
        
        let context = persistentContainer.viewContext
        
        for dict in videoUrls {
            let entity = NSEntityDescription.entity(forEntityName: "Memory", in: context)!
            let newMemory = NSManagedObject(entity: entity, insertInto: context)
            newMemory.setValue(URL(string: dict["url"]!)!, forKey: "photoURI")
            newMemory.setValue(dict["type"], forKey: "type")
            newMemory.setValue(dict["title"], forKey: "title")
        }
        
        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: kFirstTimeLaunch)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setInitialData()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "DiffableDatasourceAndCoreData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

