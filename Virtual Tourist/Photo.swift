//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

    override func prepareForDeletion() {
        
        let photoUrlComponent = photoUniqueId + ".jpg"
        
        let photoDeleteUrl = virtualTouristPhotosDirectoryUrl.appendingPathComponent(photoUrlComponent)
        
        let photoDeletePath = photoDeleteUrl.path
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: photoDeletePath) {
            
            do {
                
                try fileManager.removeItem(atPath: photoDeletePath)
                
            } catch {
                
                // Should happen extremely rarelly.
                // Do nothing. 
                
            }
            

        }
        
        
        
    }

}
