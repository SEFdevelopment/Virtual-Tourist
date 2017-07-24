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
    lazy var session = URLSession.shared
    
    
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
        
        if isCancelled { cancelOperation(); return }
        
        downloadAndSavePhotoToDisk()
        
    }
    
    
    func downloadAndSavePhotoToDisk() {
        
        if isCancelled { cancelOperation(); return }
    
        
        let request = URLRequest(url: URL(string: photoUrlInfo.photoUrl)!)
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
                        
            
            if self.isCancelled { self.cancelOperation(); return }
            
            
            // Check for errors
            guard error == nil else { self.couldNotSavePhoto(); return }
            
            // Check for status code of the response
            guard let httpResponse = response as? HTTPURLResponse  else { self.couldNotSavePhoto(); return }
            let statusCode = httpResponse.statusCode
            guard (statusCode >= 200) && (statusCode <= 299)  else { self.couldNotSavePhoto(); return }
            
            // Check that data is not nil
            guard let data = data else { self.couldNotSavePhoto(); return }
            
            if self.isCancelled { self.cancelOperation(); return }

            // Resize the image to 350 pixels for performance reasons (it comes 500 pixels from Flickr). Source: http://nshipster.com/image-resizing/
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { self.couldNotSavePhoto(); return }
            
            let options: [NSString: NSObject] = [
                kCGImageSourceThumbnailMaxPixelSize: 350 as NSObject,
                kCGImageSourceCreateThumbnailFromImageAlways: true as NSObject
            ]
            
            guard let resizedCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { self.couldNotSavePhoto(); return  }
            
            let downloadedPhoto = UIImage(cgImage: resizedCGImage)
            
            
            if self.isCancelled { self.cancelOperation(); return }
            
            
            // Save image to disk
            guard let jpegRepresentation = UIImageJPEGRepresentation(downloadedPhoto, 1.0) else { self.couldNotSavePhoto(); return }
            
            let photoUniqueId = self.photoUrlInfo.photoId + self.uniqueId
            
            let photoUrlComponent = photoUniqueId + ".jpg"
            
            let photoSaveUrl = virtualTouristPhotosDirectoryUrl.appendingPathComponent(photoUrlComponent)
            
            guard let photoSaveUrlPath = photoSaveUrl.path else { self.couldNotSavePhoto(); return }
            
            
            if self.isCancelled { self.cancelOperation(); return }
            
            if (try? jpegRepresentation.write(to: photoSaveUrl, options: [.atomic])) != nil {
                
                DispatchQueue.main.async {
                    
                    self.coreDataManager.updateLocalPhotoUrl(photoUniqueId, localPhotoUrl: photoSaveUrlPath)
                    
                }
                
                self.state = .Finished
                
            } else {
                
                self.couldNotSavePhoto()
                
            }
            
            self.state = .Finished
            
        }) 
        
        task.resume()
        
    }
    
    
    func couldNotSavePhoto() {
        
        
        DispatchQueue.main.async {
            
            self.coreDataManager.deletePhotoFromManagedContextForUniqueId(self.uniqueId, photoUrlInfo: self.photoUrlInfo)
            
        }

        
        state = .Finished

        
    }
    
    func cancelOperation() {
        
        state = .Finished
        return
        
    }
    
    
}










