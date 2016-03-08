//
//  DownloadAndSavePhotoBatchOperation.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - CLASS
class DownloadAndSavePhotoBatchOperation: ConcurrentOperation {
    
    // MARK: - PROPERTIES
    
    // MARK: - Input variables
    var uniqueId: String
    var coreDataManager: CoreDataManager
    var photoUrlsList: [PhotoUrlInfo]?
    var downloadAndSavePhotoBatchQueue: NSOperationQueue!
    
    var collectionUpdateStatus: CollectionUpdateStatus
    var missingPhotosUrlsList: [PhotoUrlInfo]?
    
    
    // MARK: - INITIALIZERS
    init(uniqueId: String, coreDataManager: CoreDataManager, downloadAndSavePhotoBatchQueue: NSOperationQueue, collectionUpdateStatus: CollectionUpdateStatus, missingPhotosUrlsList: [PhotoUrlInfo]?) {
        
        self.uniqueId = uniqueId
        self.coreDataManager = coreDataManager
        self.downloadAndSavePhotoBatchQueue = downloadAndSavePhotoBatchQueue
        self.collectionUpdateStatus = collectionUpdateStatus
        self.missingPhotosUrlsList = missingPhotosUrlsList
        
        super.init()
        

    }
    
    
    
    // MARK: - METHODS
    override func main() {
        
        if cancelled { cancelOperation(); return }
        
        if collectionUpdateStatus == .DownloadMissingPhotos {
            
            photoUrlsList = missingPhotosUrlsList
            
        } else {
            
            guard let insertPhotosForUrlsListOperation = dependencies.last as? InsertPhotosForUrlsListOperation else { state = .Finished; return }
            
            photoUrlsList = insertPhotosForUrlsListOperation.photoUrlsList
            
        }
        
        guard let photoUrlsList = photoUrlsList else { state = .Finished; return }
        
        if photoUrlsList.isEmpty {
            
            state = .Finished
            
        } else {
            
            for photoUrlInfo in photoUrlsList {
                
                if cancelled { cancelOperation(); return }
                
                let downloadAndSavePhotoToDiskOperation = DownloadAndSavePhotoToDiskOperation(uniqueId: uniqueId, photoUrlInfo: photoUrlInfo, coreDataManager: coreDataManager)
                
                if cancelled { cancelOperation(); return }
                
                downloadAndSavePhotoBatchQueue.addOperation(downloadAndSavePhotoToDiskOperation)
                
                
            }
            
            state = .Finished
            
        }
        
    }
    
   
    
    func cancelOperation() {
        
        state = .Finished
        
        return
        
    }
    
    
}