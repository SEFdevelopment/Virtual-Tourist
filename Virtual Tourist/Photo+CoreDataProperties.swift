//
//  Photo+CoreDataProperties.swift
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

extension Photo {

    @NSManaged var savedToDisk: Bool
    @NSManaged var photoId: String
    @NSManaged var photoUrl: String
    @NSManaged var photoUniqueId: String
    @NSManaged var pin: Pin

}
