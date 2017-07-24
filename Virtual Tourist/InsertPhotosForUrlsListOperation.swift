//
//  InsertPhotosForUrlsListOperation.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//


import Foundation
import CoreData

class InsertPhotosForUrlsListOperation: ConcurrentOperation {
    
    // MARK: - PROPERTIES
    
    // MARK: - Input variables
    var uniqueId: String
    var coreDataManager: CoreDataManager
    var photoUrlsList: [PhotoUrlInfo]?
    var collectionUpdateStatus: CollectionUpdateStatus
    var downloadAndSaveStatus: DownloadAndSaveStatusTracker
    
    
    // MARK: - INITIALIZERS
    init(uniqueId: String, coreDataManager: CoreDataManager, collectionUpdateStatus: CollectionUpdateStatus, downloadAndSaveStatus: DownloadAndSaveStatusTracker) {
        
        self.uniqueId = uniqueId
        self.coreDataManager = coreDataManager
        self.collectionUpdateStatus = collectionUpdateStatus
        self.downloadAndSaveStatus = downloadAndSaveStatus
        
        super.init()
        
    }
    
    
    // MARK: - METHODS
    
    // main() override
    override func main() {
        
        if isCancelled { cancelOperation(); return }
        
        if let downloadPhotoUrlsOperation = dependencies.last as? DownloadPhotoUrlsOperation {
            
            photoUrlsList = downloadPhotoUrlsOperation.photoUrlsList
            
        }
        
        if downloadAndSaveStatus.status == .UrlsLoadingError {
            
            state = .Finished
            
        } else if downloadAndSaveStatus.status == .NoPhotosForSelectedLocation {
            
            state = .Finished
            
        } else {
            
            if collectionUpdateStatus == CollectionUpdateStatus.AddNewCollection {
                
                // We will delete the existing Photo objects and then insert new Photo objects
                deleteAllPhotosForPinFromCoreData()
                
                insertPhotosToCoreData()
                
            } else {
                
                // We will insert new Photo objects
                insertPhotosToCoreData()
                
            }
            
            
        }
        
    }
    
    // MARK: - Inserting and deleting photos
    func insertPhotosToCoreData() {
        
        downloadAndSaveStatus.status = .InsertedPhotosForUrlsList
        
        DispatchQueue.main.async {
            
            self.coreDataManager.insertPhotosForUrlsList(self.uniqueId, photoUrlList: self.photoUrlsList!)
            self.coreDataManager.updateDownloadAndSaveStatusForPin(self.uniqueId, downloadAndSaveStatus: self.downloadAndSaveStatus.status.rawValue)
            
        }
        
        state = .Finished
        
    }
    
    func deleteAllPhotosForPinFromCoreData() {
        
        DispatchQueue.main.async {
            
            self.coreDataManager.deleteAllPhotosForPinFromCoreData(self.uniqueId)
            
        }
        
    }
    
    
    // MARK: - Cancel operation
    
    func cancelOperation() {
        
        state = .Finished
        return
        
    }
    
}












