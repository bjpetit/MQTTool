//
//  UserSettings.swift
//  MQTTool
//
//  Created by Brent Petit on 1/11/18.
//  Copyright © 2018-2019 Brent Petit. All rights reserved.
//

import Foundation
import CoreData

// List of user settings. The head should be the active settings.
//   New settings are added to the head of the list
//   If existing settings are selected they should be moved
//    to the head of the list
//   If settings are added, the list size should be verified and
//     settings should be removed from the tail until the list size
//     is at the maxElements value
//
class UserSettings {
    
    var connection_list: [ConnectSetting]?
    var subscription_list: [SubscribeSetting]?
    var publish_list: [PublishSetting]?
    
    var MaxHistoryItems = 10
    
    /*
     // New Goo only available on iOS 10+
     
     lazy var managedObjectContext: NSManagedObjectContext = {
     let container = self.persistentContainer
     
     return container.viewContext
     }()
     
     private lazy var persistentContainer: NSPersistentContainer = {
     let container = NSPersistentContainer(name: "UserSettings")
     container.loadPersistentStores() { storeDescription, error in
     if let error = error as NSError? {
     fatalError("Unresolved error: \(error), \(error.userInfo)")
     }
     }
     }()
     */
    
    // Path to storage location
    private(set) lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let endIndex = urls.index(before: urls.endIndex)
        return urls[endIndex]
    }()
    
    private(set) lazy var managedObjectmodel: NSManagedObjectModel = {
        let modelUrl = Bundle.main.url(forResource: "UserSettings", withExtension: "momd")!
        
        return NSManagedObjectModel(contentsOf: modelUrl)!
    }()
    
    private(set) lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectmodel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("UserSettings.sqlite")
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url)
        } catch {
            print(error)
            abort() // TODO: handle this...
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = coordinator
        
        return moc
    }()

    // My Goo
    func retrieveConnections() -> Bool {
        let request: NSFetchRequest<ConnectSetting> = ConnectSetting.fetchRequest()
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sort]
        do {
            connection_list = try managedObjectContext.fetch(request)
        } catch {
            print ("Error fetching Item objects: \(error.localizedDescription)")
            return false
        }

        if (connection_list!.count > MaxHistoryItems) {
            print("Cleaning connect overflow...")
            managedObjectContext.delete(connection_list!.last!)
            connection_list!.removeLast()
        }
        managedObjectContext.saveChanges()
        return true
    }
    
    
    // Update the connect details on the head of the list
    func updateConnection(    hostname: String,
                              port: Int64,
                              sessionID: String,
                              clean: Bool,
                              username: String?,
                              password: String?   ) {
        
        // Search for a match
        var found_item: [ConnectSetting]?
        let request: NSFetchRequest<ConnectSetting> = ConnectSetting.fetchRequest()
        let hostnamePredicate = NSPredicate(format: "(hostname = %@)", hostname)
        let portPredicate = NSPredicate(format: "(port = %@)", "\(port)")
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [hostnamePredicate, portPredicate])
        
        do {
            found_item = try managedObjectContext.fetch(request)
        } catch {
            print ("Error fetching Item objects: \(error.localizedDescription)")
            return
        }
        
        if (found_item != nil &&
            found_item!.count > 0) {
            // Match, update it
            found_item!.first!.hostname = hostname
            found_item!.first!.port = port
            found_item!.first!.sessionID = sessionID
            found_item!.first!.clean = clean
            found_item!.first!.username = username
            found_item!.first!.password = password
            found_item!.first!.timestamp = NSDate()
            
            if(found_item!.count > 1) {
                managedObjectContext.delete(found_item!.last!)
            }
            
        } else {
        
            // No match, make a new one
            let connect = NSEntityDescription.insertNewObject(forEntityName: "ConnectSetting", into: managedObjectContext) as! ConnectSetting
            connect.hostname = hostname
            connect.port = port
            connect.sessionID = sessionID
            connect.clean = clean
            connect.username = username
            connect.password = password
            connect.timestamp = NSDate()
    
        }
        managedObjectContext.saveChanges()
    }
  
    func retrieveSubscriptionList() -> Bool {
        let request: NSFetchRequest<SubscribeSetting> = SubscribeSetting.fetchRequest()
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sort]
        do {
            subscription_list = try managedObjectContext.fetch(request)
        } catch {
            print ("Error fetching Item objects: \(error.localizedDescription)")
            return false
        }
        
        if (subscription_list!.count > MaxHistoryItems) {
            print("Cleaning subscribe overflow...")
            managedObjectContext.delete(subscription_list!.last!)
            subscription_list!.removeLast()
        }
        managedObjectContext.saveChanges()
        return true
    }
    
    // Update the subscribe details on the head of the list
    func updateSubscription(    topic: String,
                                qos: Int    ) {
        
        // Search for a match
        var found_item: [SubscribeSetting]?
        let request: NSFetchRequest<SubscribeSetting> = SubscribeSetting.fetchRequest()
        let topicPredicate = NSPredicate(format: "(topic = %@)", topic)
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [topicPredicate])
        
        do {
            found_item = try managedObjectContext.fetch(request)
        } catch {
            print ("Error fetching Item objects: \(error.localizedDescription)")
            return
        }
        
        if (found_item != nil &&
            found_item!.count > 0) {
            // Match, update it
            found_item!.first!.topic = topic
            found_item!.first!.qos = Int16(qos)
            found_item!.first!.timestamp = NSDate()
            
            if(found_item!.count > 1) {
                managedObjectContext.delete(found_item!.last!)
            }
            
        } else {
        
            let subscribe = NSEntityDescription.insertNewObject(forEntityName: "SubscribeSetting", into: managedObjectContext) as! SubscribeSetting
        
            subscribe.topic = topic
            subscribe.qos = Int16(qos)
            subscribe.timestamp = NSDate()
        }

        managedObjectContext.saveChanges()
    }
 
    func retrievePublishList() -> Bool {
        let request: NSFetchRequest<PublishSetting> = PublishSetting.fetchRequest()
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sort]
        do {
            publish_list = try managedObjectContext.fetch(request)
        } catch {
            print ("Error fetching Item objects: \(error.localizedDescription)")
            return false
        }
        
        if (publish_list!.count > MaxHistoryItems) {
            print("Cleaning publish overflow...")
            managedObjectContext.delete(publish_list!.last!)
            publish_list!.removeLast()
        }
        managedObjectContext.saveChanges()
        return true
    }
    
    // Update the publish details on the head of the list
    func updatePublish( topic: String,
                        message: String?,
                        qos: Int,
                        retain: Bool    ) {
        
        // Search for a match
        var found_item: [PublishSetting]?
        let request: NSFetchRequest<PublishSetting> = PublishSetting.fetchRequest()
        let topicPredicate = NSPredicate(format: "(topic = %@)", topic)
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [topicPredicate])
        
        do {
            found_item = try managedObjectContext.fetch(request)
        } catch {
            print ("Error fetching Item objects: \(error.localizedDescription)")
            return
        }
        
        if (found_item != nil &&
            found_item!.count > 0) {
            // Match, update it
            found_item!.first!.topic = topic
            found_item!.first!.message = message
            found_item!.first!.qos = Int16(qos)
            found_item!.first!.retainFlag = retain
            found_item!.first!.timestamp = NSDate()
            
            if(found_item!.count > 1) {
                managedObjectContext.delete(found_item!.last!)
            }
            
        } else {
        
            let publish = NSEntityDescription.insertNewObject(forEntityName: "PublishSetting", into: managedObjectContext) as! PublishSetting
        
            publish.topic = topic
            publish.message = message
            publish.qos = Int16(qos)
            publish.retainFlag = retain
            publish.timestamp = NSDate()
        }
        
        managedObjectContext.saveChanges()
    }
}



extension NSManagedObjectContext {
    func saveChanges() {
        if self.hasChanges {
            do {
                try save()
            } catch {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
}
