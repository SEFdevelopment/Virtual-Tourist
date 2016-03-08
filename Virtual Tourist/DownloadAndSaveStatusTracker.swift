//
//  DownloadAndSaveStatusTracker.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation

// MARK: - CLASS

// MARK: - Class to track the download and save status
class DownloadAndSaveStatusTracker {
    
    var status: DownloadAndSaveStatus = .UrlsNotLoaded
    
}


// MARK: - ENUMS

// MARK: - Pin's status
enum DownloadAndSaveStatus: String {
    
    case UrlsNotLoaded
    case UrlsLoadingError
    case NoPhotosForSelectedLocation
    case InsertedPhotosForUrlsList
    case AllPhotosHaveBeenDownloadedAndSaved
    case AllPhotosHaveBeenDeleted
    
}


// MARK: - Collection update status
enum CollectionUpdateStatus: String {
    
    case DownloadMissingPhotos
    case AddNewCollection
    
}