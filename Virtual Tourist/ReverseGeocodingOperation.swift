//
//  ReverseGeocodingOperation.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

class ReverseGeocodingOperation: ConcurrentOperation {
    
    // MARK: - PROPERTIES
    
    // MARK: - Input variables
    var coordinate: CLLocationCoordinate2D
    var uniqueId: String
    var coreDataManager: CoreDataManager
    
    // MARK: - Geocoder
    lazy var geocoder = CLGeocoder()
    
    // MARK: - Address string
    var addressString = reverseGeocodingErrorString
    
    
    // MARK: - INITIALIZERS
    init(coordinate: CLLocationCoordinate2D, uniqueId: String, coreDataManager: CoreDataManager) {
        
        self.coordinate = coordinate
        self.uniqueId = uniqueId
        self.coreDataManager = coreDataManager
        
        super.init()
        
        qualityOfService = NSQualityOfService.UserInteractive
        
    }
    
    
    
    // MARK: - METHODS
    
    // main() override
    override func main() {
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        if self.cancelled { self.cancelOperation(); return }
        
        
        geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            
            
            if self.cancelled { self.cancelOperation(); return }
            
            guard error == nil else { self.updateLocationInfo(); return }
            
            // Convert CLPlacemark to String (http://stackoverflow.com/questions/33379114/clplacemark-to-string-in-ios-9)
            
            guard let placemarks = placemarks where placemarks.count > 0 else { self.updateLocationInfo(); return }
            guard let placemark = placemarks.last else { self.updateLocationInfo(); return }
            
            guard let addressDictionary = placemark.addressDictionary else { self.updateLocationInfo(); return }
            guard let addressStringArray = addressDictionary["FormattedAddressLines"] as? [String] else { self.updateLocationInfo(); return }
            
            self.addressString = ""
            
            for addressLine in addressStringArray {
                
                if self.cancelled { self.cancelOperation(); return }
                
                self.addressString = self.addressString + addressLine + "\n"
                
            }
            
            if self.cancelled { self.cancelOperation(); return }
            
            self.updateLocationInfo()


        })
        
    }
    
    func updateLocationInfo() {
        
        if self.cancelled { self.cancelOperation(); return }
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.coreDataManager.updateLocationInfo(self.uniqueId, addressString: self.addressString)
            
            self.state = .Finished
            
        }
        
    }
    
    
    func cancelOperation() {
        
        state = .Finished
        return
        
    }
    
    
}