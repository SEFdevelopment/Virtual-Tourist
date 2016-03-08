//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var uniqueId: String
    @NSManaged var downloadAndSaveStatus: String
    @NSManaged var photoBatchNumber: NSNumber
    @NSManaged var locationInfo: LocationInfo?
    @NSManaged var photos: NSSet

}
