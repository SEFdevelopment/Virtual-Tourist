//
//  GlobalVariables.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation

// MARK: - Geolocation
let reverseGeocodingErrorString = "reverseGeocodingError"


// MARK: - Virtual tourist photo directory in Documents directory
var virtualTouristPhotosDirectoryUrl: NSURL = {

    let documentsDirectoryUrl = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])
    
    let virtualTouristPhotosDirectoryUrl = documentsDirectoryUrl.URLByAppendingPathComponent("virtualtouristphotos")
    
    if NSFileManager.defaultManager().fileExistsAtPath(virtualTouristPhotosDirectoryUrl.path!) {
        
        return virtualTouristPhotosDirectoryUrl
        
    } else {
        
        createVirtualTouristPhotosDirectory(documentsDirectoryUrl, virtualTouristPhotosDirectoryUrl: virtualTouristPhotosDirectoryUrl)
        
        return virtualTouristPhotosDirectoryUrl
        
    }
    
}()


private func createVirtualTouristPhotosDirectory(documentsDirectoryUrl: NSURL, virtualTouristPhotosDirectoryUrl: NSURL) {
    
    do {
        
        try NSFileManager.defaultManager().createDirectoryAtURL(virtualTouristPhotosDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        
        
    } catch let error as NSError {
        
        fatalError("Unable to create directory \(error.debugDescription)")
        
    }
    
}















