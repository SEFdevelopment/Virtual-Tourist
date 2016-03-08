//
//  DownloadAndSavePhotosManager.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit

class DownloadAndSavePhotosManager {
    
    // PROPERTIES
    
    // MARK: - List of all operations
    private var downloadAndSavePhotosOperationsList = [String: DownloadAndSavePhotosOperation]()
    
    
    // MARK: - METHODS
    
    // MARK: - Download and save photos
    func downloadAndSavePhotosForAnnotation(annotation: MKPointAnnotationWithUniqueId, collectionUpdateStatus: CollectionUpdateStatus, missingPhotosUrlsList: [PhotoUrlInfo]?, coreDataManager: CoreDataManager) {
        
        let coordinate = annotation.coordinate
        let uniqueId = annotation.uniqueId
        
        
        // Create the operation
        let downloadAndSavePhotosOperation = DownloadAndSavePhotosOperation(coordinate: coordinate, uniqueId: uniqueId, coreDataManager: coreDataManager, collectionUpdateStatus: collectionUpdateStatus, missingPhotosUrlsList: missingPhotosUrlsList)
        
        // Operation's completion block (for hiding network activity indicator)
        downloadAndSavePhotosOperation.completionBlock = {
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.hideNetworkActivityIndicator()
                
            }
            
        }
        
        // Add the operation to the list of operations and associated it with the annotation's uniqueId
        downloadAndSavePhotosOperationsList[uniqueId] = downloadAndSavePhotosOperation
        
        // Show network activity indicator
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Start the operation
        downloadAndSavePhotosOperation.start()
        
    }
    
    
    // MARK: - Active operation for uniqueId
    func activeOperationForUniqueId(uniqueId: String) -> DownloadAndSavePhotosOperation? {
        
        return downloadAndSavePhotosOperationsList[uniqueId]
        
    }
    
    
    // MARK: - Non-finished operations
    func allOperationsFinished() -> Bool {
        
        for (_, operation) in downloadAndSavePhotosOperationsList {
            
            if operation.finished == false { return false }
            
        }
        
        return true
        
    }
    
    
    // MARK: - Cancelling operations
    func cancelAllOperations() {
        
        for (uniqueId, operation) in downloadAndSavePhotosOperationsList {
            
            operation.cancelOperation()
            
            downloadAndSavePhotosOperationsList[uniqueId] = nil
            
        }
        
    }
    
    
    func cancelDownloadingAndSavingPhotosForUniqueId(uniqueId: String) {
        
        if let operationToBeCancelled = downloadAndSavePhotosOperationsList[uniqueId] {
            
            operationToBeCancelled.cancelOperation()
            
            downloadAndSavePhotosOperationsList[uniqueId] = nil
            
        }
        
    }
    
    
    
    // MARK: - Network activity indicator
    func hideNetworkActivityIndicator() {
        
        // We check if there are non-finished operations. If there is at least one we return, otherwise we hide the network activity indicator.
        
        if allOperationsFinished() {
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
        }
        
    }
    


    
}