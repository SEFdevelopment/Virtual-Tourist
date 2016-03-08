//
//  DownloadPhotoUrlsOperation.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

class DownloadPhotoUrlsOperation: ConcurrentOperation {
    
    // MARK: - PROPERTIES
    
    // MARK: - Input variables
    var uniqueId: String
    var coreDataManager: CoreDataManager
    var coordinate: CLLocationCoordinate2D
    var downloadAndSaveStatus: DownloadAndSaveStatusTracker
    
    
    // MARK: - Output variables
    var photoUrlsList: [PhotoUrlInfo]?
    
    
    // MARK: - Network
    lazy var session = NSURLSession.sharedSession()
    
    
    
    // MARK: - INITIALIZERS
    init(uniqueId: String, coreDataManager: CoreDataManager, coordinate: CLLocationCoordinate2D, downloadAndSaveStatus: DownloadAndSaveStatusTracker) {
        
        self.uniqueId = uniqueId
        self.coreDataManager = coreDataManager
        self.coordinate = coordinate
        self.downloadAndSaveStatus = downloadAndSaveStatus
        
        super.init()
        
        qualityOfService = NSQualityOfService.UserInteractive
        
    }
    
    
    // MARK: - METHODS
    
    // main() override
    override func main() {
        
        if cancelled { cancelOperation(); return }
        
        var photoBatchNumber: Int = 1
        
        dispatch_sync(dispatch_get_main_queue()) {
            
            if let pin = self.coreDataManager.fetchPinForId(self.uniqueId) {
                
                photoBatchNumber = pin.photoBatchNumber.integerValue
                
            }
            
        }
        
        downloadPhotoUrlsList(photoBatchNumber: photoBatchNumber)
        
    }
    
    
    // MARK: - URL request
    func getPhotoUrlsListRequest(coordinate: CLLocationCoordinate2D, photoBatchNumber: Int) -> NSMutableURLRequest {
        
        // Flickr constants
        let baseUrl = "https://api.flickr.com/services/rest/"
        
        let method = "flickr.photos.search"
        let api_key = "d32b2bd51470fcfffa677b01758c2c1b"
        let min_upload_date = "946684800" // Unix timestamp of 01/01/2000. We use it as a limiting parameter in the geoquery to Flickr.
        let per_page = "21" // We will query for 21 photos at once as in the official Udacity's Virtual Tourist app.
        let radius = "5" // We will search photos 5 km around the location.
        let format = "json"
        let nojsoncallback = "1"
        
        
        // Convert values
        let lat = String(coordinate.latitude)
        let lon = String(coordinate.longitude)
        let page = String(photoBatchNumber)
        
        // Request
        let requestURLComponents = NSURLComponents(string: baseUrl)!
        
        let methodItem = NSURLQueryItem(name: "method", value: method)
        let api_keyItem = NSURLQueryItem(name: "api_key", value: api_key)
        let min_upload_dateItem = NSURLQueryItem(name: "min_upload_date", value: min_upload_date)
        let latItem = NSURLQueryItem(name: "lat", value: lat)
        let lonItem = NSURLQueryItem(name: "lon", value: lon)
        let radiusItem = NSURLQueryItem(name: "radius", value: radius)
        let per_pageItem = NSURLQueryItem(name: "per_page", value: per_page)
        let pageItem = NSURLQueryItem(name: "page", value: page)
        let formatItem = NSURLQueryItem(name: "format", value: format)
        let nojsoncallbackItem = NSURLQueryItem(name: "nojsoncallback", value: nojsoncallback)
        
        requestURLComponents.queryItems = [methodItem, api_keyItem, min_upload_dateItem, latItem, lonItem, radiusItem, per_pageItem, pageItem, formatItem, nojsoncallbackItem]
        
        let requestURL = requestURLComponents.URL!
        
        let request = NSMutableURLRequest(URL: requestURL)
        
        return request
        
    }
    
    
    // MARK: - Get image list from Flickr
    func downloadPhotoUrlsList(photoBatchNumber photoBatchNumber: Int) {
        
        if cancelled { cancelOperation(); return }
        
        
        let request = getPhotoUrlsListRequest(coordinate, photoBatchNumber: photoBatchNumber)
        
        if cancelled { cancelOperation(); return }
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
                        
            
            if self.cancelled { self.cancelOperation(); return }
            
            
            // Check for errors
            guard error == nil else { self.couldNotGetPhotoUrls(); return }
            
            // Check for status code of the response
            guard let httpResponse = response as? NSHTTPURLResponse  else { self.couldNotGetPhotoUrls(); return }
            let statusCode = httpResponse.statusCode
            guard (statusCode >= 200) && (statusCode <= 299)  else { self.couldNotGetPhotoUrls(); return }
            
            // Check that data is not nil
            guard let data = data else { self.couldNotGetPhotoUrls(); return }
            
            // Parse data
            if self.cancelled { self.cancelOperation(); return }
            
            do {
                
                let parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                
                guard let photosDictionary = parsedJSON["photos"] as? [String: AnyObject] else { self.couldNotGetPhotoUrls(); return }
                
                guard let photoArray = photosDictionary["photo"] as? [NSDictionary] else { self.couldNotGetPhotoUrls(); return }
                
                if self.cancelled { self.cancelOperation(); return }
                
                self.photoUrlsList = [PhotoUrlInfo]()
                
                for photo in photoArray {
                    
                    if self.cancelled { self.cancelOperation(); return }
                    
                    guard let photoId = photo["id"] as? String else { continue }
                    guard let serverId = photo["server"] as? String else { continue }
                    guard let farmId =  photo["farm"] as? Int else { continue }
                    guard let secret = photo["secret"] as? String else { continue }
                    
                    let photoUrl = "https://farm\(String(farmId)).staticflickr.com/\(serverId)/\(photoId)_\(secret).jpg"
                    
                    let photoUrlInfo = PhotoUrlInfo(photoId: photoId, photoUrl: photoUrl)
                    
                    self.photoUrlsList?.append(photoUrlInfo)
                    
                }
                
                if self.photoUrlsList!.isEmpty {
                    
                    self.downloadAndSaveStatus.status = .NoPhotosForSelectedLocation
                    
                    self.updatePinStatus()
                    
                }
                
                
                self.state = .Finished
                
            } catch {
                
                self.photoUrlsList = nil
                
                self.downloadAndSaveStatus.status = .UrlsLoadingError
                
                self.updatePinStatus()
                
                self.state = .Finished
                
                
            }
            
            self.state = .Finished
            
            
            
        }
        
        task.resume()
        
        
    }
    
    
    // MARK: - Getting photo urls error
    func couldNotGetPhotoUrls() {
        
        photoUrlsList = nil
        
        downloadAndSaveStatus.status = .UrlsLoadingError
        
        self.updatePinStatus()
        
        state = .Finished
        
    }
    
    
    
    // MARK: - Update pin status
    func updatePinStatus() {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.coreDataManager.updateDownloadAndSaveStatusForPin(self.uniqueId, downloadAndSaveStatus: self.downloadAndSaveStatus.status.rawValue)
        }
        
        
    }
    
    // MARK: - Cancel operation
    func cancelOperation() {
        
        state = .Finished
        return
        
    }
    
    
    
}