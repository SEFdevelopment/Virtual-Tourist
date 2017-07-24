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
    lazy var session = URLSession.shared
    
    
    
    // MARK: - INITIALIZERS
    init(uniqueId: String, coreDataManager: CoreDataManager, coordinate: CLLocationCoordinate2D, downloadAndSaveStatus: DownloadAndSaveStatusTracker) {
        
        self.uniqueId = uniqueId
        self.coreDataManager = coreDataManager
        self.coordinate = coordinate
        self.downloadAndSaveStatus = downloadAndSaveStatus
        
        super.init()
        
        qualityOfService = QualityOfService.userInteractive
        
    }
    
    
    // MARK: - METHODS
    
    // main() override
    override func main() {
        
        if isCancelled { cancelOperation(); return }
        
        var photoBatchNumber: Int = 1
        
        DispatchQueue.main.sync {
            
            if let pin = self.coreDataManager.fetchPinForId(self.uniqueId) {
                
                photoBatchNumber = pin.photoBatchNumber.intValue
                
            }
            
        }
        
        downloadPhotoUrlsList(photoBatchNumber: photoBatchNumber)
        
    }
    
    
    // MARK: - URL request
    func getPhotoUrlsListRequest(_ coordinate: CLLocationCoordinate2D, photoBatchNumber: Int) -> NSMutableURLRequest {
        
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
        var requestURLComponents = URLComponents(string: baseUrl)!
        
        let methodItem = URLQueryItem(name: "method", value: method)
        let api_keyItem = URLQueryItem(name: "api_key", value: api_key)
        let min_upload_dateItem = URLQueryItem(name: "min_upload_date", value: min_upload_date)
        let latItem = URLQueryItem(name: "lat", value: lat)
        let lonItem = URLQueryItem(name: "lon", value: lon)
        let radiusItem = URLQueryItem(name: "radius", value: radius)
        let per_pageItem = URLQueryItem(name: "per_page", value: per_page)
        let pageItem = URLQueryItem(name: "page", value: page)
        let formatItem = URLQueryItem(name: "format", value: format)
        let nojsoncallbackItem = URLQueryItem(name: "nojsoncallback", value: nojsoncallback)
        
        requestURLComponents.queryItems = [methodItem, api_keyItem, min_upload_dateItem, latItem, lonItem, radiusItem, per_pageItem, pageItem, formatItem, nojsoncallbackItem]
        
        let requestURL = requestURLComponents.url!
        
        let request = NSMutableURLRequest(url: requestURL)
        
        return request
        
    }
    
    
    // MARK: - Get image list from Flickr
    func downloadPhotoUrlsList(photoBatchNumber: Int) {
        
        if isCancelled { cancelOperation(); return }
        
        
        let request = getPhotoUrlsListRequest(coordinate, photoBatchNumber: photoBatchNumber) as URLRequest
        
        
        if isCancelled { cancelOperation(); return }
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
                        
            
            if self.isCancelled { self.cancelOperation(); return }
            
            
            // Check for errors
            guard error == nil else { self.couldNotGetPhotoUrls(); return }
            
            // Check for status code of the response
            guard let httpResponse = response as? HTTPURLResponse  else { self.couldNotGetPhotoUrls(); return }
            let statusCode = httpResponse.statusCode
            guard (statusCode >= 200) && (statusCode <= 299)  else { self.couldNotGetPhotoUrls(); return }
            
            // Check that data is not nil
            guard let data = data else { self.couldNotGetPhotoUrls(); return }
            
            // Parse data
            if self.isCancelled { self.cancelOperation(); return }
            
            do {
                
                guard let parsedJSON = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] else { self.couldNotGetPhotoUrls(); return }
                
                guard let photosDictionary = parsedJSON["photos"] as? [String: AnyObject] else { self.couldNotGetPhotoUrls(); return }
                
                guard let photoArray = photosDictionary["photo"] as? [NSDictionary] else { self.couldNotGetPhotoUrls(); return }
                
                if self.isCancelled { self.cancelOperation(); return }
                
                self.photoUrlsList = [PhotoUrlInfo]()
                
                for photo in photoArray {
                    
                    if self.isCancelled { self.cancelOperation(); return }
                    
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
            
            
            
        }) 
        
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
        
        DispatchQueue.main.async {
            
            self.coreDataManager.updateDownloadAndSaveStatusForPin(self.uniqueId, downloadAndSaveStatus: self.downloadAndSaveStatus.status.rawValue)
        }
        
        
    }
    
    // MARK: - Cancel operation
    func cancelOperation() {
        
        state = .Finished
        return
        
    }
    
    
    
}
