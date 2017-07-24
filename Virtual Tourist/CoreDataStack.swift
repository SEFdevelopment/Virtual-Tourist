//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import CoreData

class CoreDataStack {
    
    // MARK: - Model name
    let modelName = "Virtual Tourist"
    
    // MARK: - Managed object model
    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd")!
        
        return NSManagedObjectModel(contentsOf: modelURL)!
        
    }()
    
    
    // MARK: - Managed object context
    lazy var managedObjectContext: NSManagedObjectContext = {
        
        var context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return context
        
    }()
    
    
    // MARK: - Persistent store coordinator
    fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let url = self.applicationDocumentsDirectory.appendingPathComponent(self.modelName)
        
        do {
            
            let options = [NSMigratePersistentStoresAutomaticallyOption : true]
            
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
            
        } catch  {
            
            fatalError("Error adding persistent store.")
            
        }
        
        return coordinator
    }()
    
    
    
    // MARK: - Documents directory
    fileprivate lazy var applicationDocumentsDirectory: URL = {
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return urls[urls.count-1]
        
    }()
    
}
















