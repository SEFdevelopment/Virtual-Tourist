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
        
        let photoDeleteUrl = virtualTouristPhotosDirectoryUrl.URLByAppendingPathComponent(photoUrlComponent)
        
        guard let photoDeletePath = photoDeleteUrl.path else { return }
        
        let fileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(photoDeletePath) {
            
            do {
                
                try fileManager.removeItemAtPath(photoDeletePath)
                
            } catch {
                
                // Should happen extremely rarelly.
                // Do nothing. 
                
            }
            

        }
        
        
        
    }

}
