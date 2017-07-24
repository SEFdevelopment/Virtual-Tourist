//
//  DownloadAndSavePhotosOperation.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//


import Foundation
import CoreData
import CoreLocation

// MARK: - GLOBAL VARIABLES

// Global context variable for KVO
private var downloadAndSavePhotosContext = 0


// MARK: - CLASS
class DownloadAndSavePhotosOperation: ConcurrentOperation {
    
    // MARK: - PROPERTIES
    
    // MARK: - Input variables
    var uniqueId: String
    var coordinate: CLLocationCoordinate2D
    var coreDataManager: CoreDataManager
    var collectionUpdateStatus: CollectionUpdateStatus
    var missingPhotosUrlsList: [PhotoUrlInfo]?
    
    
    // MARK: - Internal queue
    dynamic let downloadAndSaveQueue = OperationQueue()
    
    
    // MARK: - Download and save status
    var downloadAndSaveStatus = DownloadAndSaveStatusTracker()
    
    
    // MARK: - NSOperations
    var downloadPhotoUrlsOperation: DownloadPhotoUrlsOperation!
    var insertPhotosForUrlsListOperation: InsertPhotosForUrlsListOperation!
    var downloadAndSavePhotoBatchOperation: DownloadAndSavePhotoBatchOperation!
    
    
    // MARK: - INITIALIZERS
    init(coordinate: CLLocationCoordinate2D, uniqueId: String, coreDataManager: CoreDataManager, collectionUpdateStatus: CollectionUpdateStatus, missingPhotosUrlsList: [PhotoUrlInfo]?) {
        
        self.coordinate = coordinate
        self.uniqueId = uniqueId
        self.coreDataManager = coreDataManager
        self.collectionUpdateStatus = collectionUpdateStatus
        self.missingPhotosUrlsList = missingPhotosUrlsList
        
        super.init()
        
        downloadAndSaveQueue.addObserver(self, forKeyPath: "operationCount", options: .new, context: &downloadAndSavePhotosContext)
        
    }
    
    
    // MARK: - METHODS
    
    // main() override
    override func main() {
        
        if isCancelled { cancelOperation(); return }
        
        
        // Initialize the operations
        switch collectionUpdateStatus {
            
        case .AddNewCollection:
            
            downloadPhotoUrlsOperation = DownloadPhotoUrlsOperation(uniqueId: uniqueId, coreDataManager: coreDataManager, coordinate: coordinate, downloadAndSaveStatus: downloadAndSaveStatus)
            
            insertPhotosForUrlsListOperation = InsertPhotosForUrlsListOperation(uniqueId: uniqueId, coreDataManager: coreDataManager, collectionUpdateStatus: collectionUpdateStatus, downloadAndSaveStatus: downloadAndSaveStatus)
            
            downloadAndSavePhotoBatchOperation = DownloadAndSavePhotoBatchOperation(uniqueId: uniqueId, coreDataManager: coreDataManager, downloadAndSavePhotoBatchQueue: downloadAndSaveQueue, collectionUpdateStatus: collectionUpdateStatus, missingPhotosUrlsList: nil)
            
            
            // Set dependencies among operations and add them to the queue
            insertPhotosForUrlsListOperation.addDependency(downloadPhotoUrlsOperation)
            downloadAndSavePhotoBatchOperation.addDependency(insertPhotosForUrlsListOperation)
            
            
            downloadAndSaveQueue.addOperations([downloadPhotoUrlsOperation, insertPhotosForUrlsListOperation, downloadAndSavePhotoBatchOperation], waitUntilFinished: false)
            
            
            
        case .DownloadMissingPhotos:
            
            downloadAndSaveStatus.status = DownloadAndSaveStatus.InsertedPhotosForUrlsList
            
            updatePinStatus()
            
            downloadAndSavePhotoBatchOperation = DownloadAndSavePhotoBatchOperation(uniqueId: uniqueId, coreDataManager: coreDataManager, downloadAndSavePhotoBatchQueue: downloadAndSaveQueue, collectionUpdateStatus: collectionUpdateStatus, missingPhotosUrlsList: missingPhotosUrlsList)
            

            downloadAndSaveQueue.addOperation(downloadAndSavePhotoBatchOperation)
            
        }
        
        
    }
    
    
    // MARK: - Key value observing
    
    // We mark the DownloadAndSavePhotos operation as finished when the operationsCount property of the privateQueue becomes equal to 0.
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &downloadAndSavePhotosContext {
            
            if let newOperationCountValue = change?[NSKeyValueChangeKey.newKey] as? Int {
                
                if newOperationCountValue == 0 {
                    
                    // Completion handler for downloading and saving photos
                    
                    if downloadAndSaveStatus.status == DownloadAndSaveStatus.InsertedPhotosForUrlsList {
                        
                        var allPhotosDownloadedAndSaved = false
                        
                        DispatchQueue.main.sync {
                            
                            allPhotosDownloadedAndSaved = self.coreDataManager.allPhotosForPinWereDownloadedAndSaved(self.uniqueId)
                            
                        }
                        
                        if allPhotosDownloadedAndSaved {
                            
                            downloadAndSaveStatus.status = .AllPhotosHaveBeenDownloadedAndSaved
                            
                            updatePinStatus()
                            
                        }
                        
                    }
                    
                    
                    state = .Finished

                    
                }
                
            }
            
        } else {
            
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            
        }
    }
    
    deinit {
        
        downloadAndSaveQueue.removeObserver(self, forKeyPath: "operationCount", context: &downloadAndSavePhotosContext)
        
    }
    
    
    // MARK: - Cancel operation
    func cancelOperation() {
        
        downloadAndSaveQueue.cancelAllOperations()
        
        state = .Finished
        
        return
        
    }
    
    
    // MARK: - Update pin status
    func updatePinStatus() {
        
        DispatchQueue.main.async {
            
            self.coreDataManager.updateDownloadAndSaveStatusForPin(self.uniqueId, downloadAndSaveStatus: self.downloadAndSaveStatus.status.rawValue)
        }
        
    }

    
}









