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
var virtualTouristPhotosDirectoryUrl: URL = {

    let documentsDirectoryUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    
    let virtualTouristPhotosDirectoryUrl = documentsDirectoryUrl.appendingPathComponent("virtualtouristphotos")
    
    if FileManager.default.fileExists(atPath: virtualTouristPhotosDirectoryUrl.path) {
        
        return virtualTouristPhotosDirectoryUrl
        
    } else {
        
        createVirtualTouristPhotosDirectory(documentsDirectoryUrl, virtualTouristPhotosDirectoryUrl: virtualTouristPhotosDirectoryUrl)
        
        return virtualTouristPhotosDirectoryUrl
        
    }
    
}()


private func createVirtualTouristPhotosDirectory(_ documentsDirectoryUrl: URL, virtualTouristPhotosDirectoryUrl: URL) {
    
    do {
        
        try FileManager.default.createDirectory(at: virtualTouristPhotosDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        
        
    } catch let error as NSError {
        
        fatalError("Unable to create directory \(error.debugDescription)")
        
    }
    
}















