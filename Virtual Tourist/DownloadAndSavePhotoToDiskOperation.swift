//
//  DownloadAndSavePhotoToDiskOperation.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//


import Foundation
import CoreData
import UIKit
import ImageIO
import CoreGraphics

// If we successfully saved the photo to disk, we update the Pin
// If we could not save the photo to disk, we delete the Pin

// MARK: - CLASS
class DownloadAndSavePhotoToDiskOperation: ConcurrentOperation {
    
    // MARK: - PROPERTIES
    
    // MARK: - Input variables
    var uniqueId: String
    var photoUrlInfo: PhotoUrlInfo
    var coreDataManager: CoreDataManager
    
    // MARK: - Network
    lazy var session = NSURLSession.sharedSession()
    
    
    // MARK: - INITIALIZERS
    init(uniqueId: String, photoUrlInfo: PhotoUrlInfo, coreDataManager: CoreDataManager) {
        
        self.uniqueId = uniqueId
        self.photoUrlInfo = photoUrlInfo
        self.coreDataManager = coreDataManager
        
        super.init()
        
    }
    
    
    // MARK: - METHODS
    
    // main() override
    override func main() {
        
        if cancelled { cancelOperation(); return }
        
        downloadAndSavePhotoToDisk()
        
    }
    
    
    func downloadAndSavePhotoToDisk() {
        
        if cancelled { cancelOperation(); return }
    
        
        let request = NSURLRequest(URL: NSURL(string: photoUrlInfo.photoUrl)!)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
                        
            
            if self.cancelled { self.cancelOperation(); return }
            
            
            // Check for errors
            guard error == nil else { self.couldNotSavePhoto(); return }
            
            // Check for status code of the response
            guard let httpResponse = response as? NSHTTPURLResponse  else { self.couldNotSavePhoto(); return }
            let statusCode = httpResponse.statusCode
            guard (statusCode >= 200) && (statusCode <= 299)  else { self.couldNotSavePhoto(); return }
            
            // Check that data is not nil
            guard let data = data else { self.couldNotSavePhoto(); return }
            
            if self.cancelled { self.cancelOperation(); return }

            // Resize the image to 350 pixels for performance reasons (it comes 500 pixels from Flickr). Source: http://nshipster.com/image-resizing/
            guard let imageSource = CGImageSourceCreateWithData(data, nil) else { self.couldNotSavePhoto(); return }
            
            let options: [NSString: NSObject] = [
                kCGImageSourceThumbnailMaxPixelSize: 350,
                kCGImageSourceCreateThumbnailFromImageAlways: true
            ]
            
            guard let resizedCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { self.couldNotSavePhoto(); return  }
            
            let downloadedPhoto = UIImage(CGImage: resizedCGImage)
            
            
            if self.cancelled { self.cancelOperation(); return }
            
            
            // Save image to disk
            guard let jpegRepresentation = UIImageJPEGRepresentation(downloadedPhoto, 1.0) else { self.couldNotSavePhoto(); return }
            
            let photoUniqueId = self.photoUrlInfo.photoId + self.uniqueId
            
            let photoUrlComponent = photoUniqueId + ".jpg"
            
            let photoSaveUrl = virtualTouristPhotosDirectoryUrl.URLByAppendingPathComponent(photoUrlComponent)
            
            guard let photoSaveUrlPath = photoSaveUrl.path else { self.couldNotSavePhoto(); return }
            
            
            if self.cancelled { self.cancelOperation(); return }
            
            if jpegRepresentation.writeToURL(photoSaveUrl, atomically: true) {
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.coreDataManager.updateLocalPhotoUrl(photoUniqueId, localPhotoUrl: photoSaveUrlPath)
                    
                }
                
                self.state = .Finished
                
            } else {
                
                self.couldNotSavePhoto()
                
            }
            
            self.state = .Finished
            
        }
        
        task.resume()
        
    }
    
    
    func couldNotSavePhoto() {
        
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.coreDataManager.deletePhotoFromManagedContextForUniqueId(self.uniqueId, photoUrlInfo: self.photoUrlInfo)
            
        }

        
        state = .Finished

        
    }
    
    func cancelOperation() {
        
        state = .Finished
        return
        
    }
    
    
}










