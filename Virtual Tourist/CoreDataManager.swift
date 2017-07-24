//
//  CoreDataManager.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation
import CoreData
import MapKit

// MARK: - CLASS
class CoreDataManager: NSObject {
    
    // MARK: - PROPERTIES
    
    // MARK: - Managed object context
    var managedObjectContext: NSManagedObjectContext
    
    // MARK: - Entity names
    let mapStateEntityName = "MapState"
    let locationInfoEntityName = "LocationInfo"
    
    let pinEntityName = "Pin"
    let photoEntityName = "Photo"
    
    
    // MARK: - INITIALIZERS
    init(managedObjectContext: NSManagedObjectContext) {
        
        self.managedObjectContext = managedObjectContext
        
        super.init()
        
        
    }
    
    
    // MARK: - METHODS

    // MARK: - Save managed object context
    func saveContext () {
        
        if managedObjectContext.hasChanges {
            
            do {
                
                try managedObjectContext.save()
                
            } catch let error as NSError {
                
                // Better to crash rather than save corrupted data.
                fatalError(error.localizedDescription)
                
            }
        }
    }
    
}

// MARK: - EXTENSIONS

// MARK: - MAP STATE
extension CoreDataManager {
    
    // Managing map's state between application launches
    func insertMapState(_ region: MKCoordinateRegion) {
        
        let latitude = region.center.latitude as Double
        let longitude = region.center.longitude as Double
        let latitudeDelta = region.span.latitudeDelta as Double
        let longitudeDelta = region.span.longitudeDelta as Double
        
        let mapStateEntity = NSEntityDescription.entity(forEntityName: mapStateEntityName, in: managedObjectContext)!
        
        let mapState = MapState(entity: mapStateEntity, insertInto: managedObjectContext)
        
        mapState.latitude = NSNumber(value: latitude)
        mapState.longitude = NSNumber(value: longitude)
        mapState.latitudeDelta = NSNumber(value: latitudeDelta)
        mapState.longitudeDelta = NSNumber(value: longitudeDelta)
        
        
    }
    
    
    func updateMapState(_ mapState: MapState, region: MKCoordinateRegion) {
        
        let latitude = region.center.latitude as Double
        let longitude = region.center.longitude as Double
        let latitudeDelta = region.span.latitudeDelta as Double
        let longitudeDelta = region.span.longitudeDelta as Double
        
        mapState.latitude = NSNumber(value: latitude)
        mapState.longitude = NSNumber(value: longitude)
        mapState.latitudeDelta = NSNumber(value: latitudeDelta)
        mapState.longitudeDelta = NSNumber(value: longitudeDelta)
        
    }
    
    
    func fetchMapState() -> MapState? {
        
        var results = [MapState]()
        
        let mapStateFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: mapStateEntityName)
        
        do {
            
            results = try managedObjectContext.fetch(mapStateFetchRequest) as! [MapState]
            
            if results.isEmpty {
                
                return nil
                
            } else {
                
                return results[0]
                
            }
            
        } catch {
            
            return nil
            
        }
        
    }
    
}


// MARK: - LOCATION INFO
extension CoreDataManager {
    
    func insertLocationInfoToMangedContext(_ uniqueId: String, addressString: String) {
        
        if let pin = fetchPinForId(uniqueId) {
            
            // Create an infoLocation object and associate it with pin
            let locationInfoEntity = NSEntityDescription.entity(forEntityName: locationInfoEntityName, in: managedObjectContext)!
            
            let locationInfo = LocationInfo(entity: locationInfoEntity, insertInto: managedObjectContext)
            
            locationInfo.addressString = addressString
            
            pin.locationInfo = locationInfo
            
        }
        
    }
    
    
    func updateLocationInfo(_ uniqueId: String, addressString: String) {
        
        if let pin = fetchPinForId(uniqueId) {
            
            if pin.locationInfo == nil {
                
                insertLocationInfoToMangedContext(uniqueId, addressString: addressString)
                
            } else {
                
                pin.locationInfo?.addressString = addressString
                
                
            }
            
        }
        
    }
    
    
}



// MARK: - PINS
extension CoreDataManager {
    
    // MARK: - Insert pins to core data
    func insertPinToMangedContext(forAnnotation annotation: MKPointAnnotationWithUniqueId) {
        
        let coordinate = annotation.coordinate
        let latitude = coordinate.latitude as Double
        let longitude = coordinate.longitude as Double
        let uniqueId = annotation.uniqueId
        
        let pinEntity = NSEntityDescription.entity(forEntityName: pinEntityName, in: managedObjectContext)!
        
        let pin = Pin(entity: pinEntity, insertInto: managedObjectContext)
        pin.latitude = NSNumber(value: latitude)
        pin.longitude = NSNumber(value: longitude)
        pin.uniqueId = uniqueId!
        
        saveContext()
        
    }
    
    
    // MARK: - Delete pins
    func deletePinFromManagedContext(forAnnotation annotationToDelete: MKAnnotation) {
        
        let annotation = annotationToDelete as! MKPointAnnotationWithUniqueId
        
        let uniqueId = annotation.uniqueId
        
        deletePinFromManagedContext(forUniqueId: uniqueId!)
        
        
    }
    
    
    func deletePinFromManagedContext(forUniqueId uniqueId: String) {
        
        let deletePinFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pinEntityName)
        
        deletePinFetchRequest.predicate = NSPredicate(format: "uniqueId == %@", uniqueId)
        
        do {
            
            let pinsToBeDeleted = try managedObjectContext.fetch(deletePinFetchRequest) as! [Pin]
            
            for pin in pinsToBeDeleted {
                
                managedObjectContext.delete(pin)
                
                saveContext()
                
            }
            
            
        } catch {
            
            // Better to crash than to have corrupted data.
            fatalError("Error deleting pins.")
            
        }
        
        
    }
    
    
    // MARK: - Fetching pins
    func fetchPinForId(_ uniqueId: String) -> Pin? {
        
        var pin: Pin?
        
        let pinForIdFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pinEntityName)
        
        pinForIdFetchRequest.predicate = NSPredicate(format: "uniqueId == %@", uniqueId)
        
        do {
            
            let pins = try managedObjectContext.fetch(pinForIdFetchRequest) as! [Pin]
            
            guard pins.count > 0 else { return nil }
            
            pin = pins[0]
            
            
        } catch {
            
            // Better to crash than to have corrupted data.
            fatalError("Error fetching pin.")
            
        }
        
        return pin
        
    }
    
    
    func fetchPinForAnnotation(_ annotation: MKPointAnnotationWithUniqueId) -> Pin? {
        
        let uniqueId = annotation.uniqueId
        
        let pin = fetchPinForId(uniqueId!)
        
        return pin
        
    }
    
    
    func fetchAllPins() -> [Pin] {
        
        var results = [Pin]()
        
        let allPinsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pinEntityName)
        
        do {
            
            results = try managedObjectContext.fetch(allPinsFetchRequest) as! [Pin]
            
        } catch {
            
            // Better to crash than to have corrupted data.
            fatalError("Error fetching all pins.")
            
        }
        
        return results
        
    }
    
    
    func fetchNumberOfPins() -> Int? {
        
        let allPinsCountFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pinEntityName)
        
        allPinsCountFetchRequest.resultType = .countResultType
        
        var result: Int?
        
        do {
            
            let results = try managedObjectContext.fetch(allPinsCountFetchRequest) as? [NSNumber]
            
            if let results = results {
                
                result = results[0].intValue
                
            }
            
            return result
            
        } catch {
            
            // Better to crash than to have corrupted data.
            fatalError("Error fetching number of pins.")

        }
        
        
    }
    
    
    // MARK: - Update pin status
    func updateDownloadAndSaveStatusForPin(_ uniqueId: String, downloadAndSaveStatus: String) {
        
        guard let pin = fetchPinForId(uniqueId) else { return }
        
        pin.downloadAndSaveStatus = downloadAndSaveStatus
        
        saveContext()
        
    }
    
    
    
}





// MARK: - PHOTOS
extension CoreDataManager {
    
    // MARK: - Save and update photos
    func insertPhotosForUrlsList(_ uniqueId: String, photoUrlList: [PhotoUrlInfo]) {
        
        if let pin = fetchPinForId(uniqueId) {
            
            // Create a Photo object and associate it with pin
            let photoEntity = NSEntityDescription.entity(forEntityName: photoEntityName, in: managedObjectContext)!
            
            for photoUrlInfo in photoUrlList {
                
                let photo = Photo(entity: photoEntity, insertInto: managedObjectContext)
                
                photo.photoId = photoUrlInfo.photoId
                photo.photoUrl = photoUrlInfo.photoUrl
                photo.photoUniqueId = photoUrlInfo.photoId + uniqueId
                
                photo.pin = pin
                
            }
            
            // Increase the photo batch number
            pin.photoBatchNumber = NSNumber(value: (pin.photoBatchNumber.intValue + 1) as Int)
            
            // Save context
            saveContext()
            
        }
        
    }
    
    func updateLocalPhotoUrl(_ uniquePhotoId: String, localPhotoUrl: String) {
        
        if let photo = fetchPhotoForId(uniquePhotoId) {
            
            photo.savedToDisk = true
            
            saveContext()
            
        }
        
    }
    
    
    // MARK: - Fetch photos
    func fetchPhotoForId(_ uniquePhotoId: String) -> Photo? {
        
        var photo: Photo?
        
        let photoForIdFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: photoEntityName)
        
        photoForIdFetchRequest.predicate = NSPredicate(format: "photoUniqueId == %@", uniquePhotoId)
        
        do {
            
            let photos = try managedObjectContext.fetch(photoForIdFetchRequest) as! [Photo]
            
            guard photos.count > 0 else { return nil }
            
            photo = photos[0]
            
            
        } catch {
            
            // Better to crash than to have corrupted data.
            fatalError("Error fetching photo for id.")
            
        }
        
        return photo
        
    }
    
    func allPhotosForPinWereDownloadedAndSaved(_ uniqueId: String) -> Bool {
        
        guard let pin = fetchPinForId(uniqueId) else { return false }
        
        guard pin.photos.count > 0 else { return false }
        
        for photo in pin.photos {
            
            if (photo as AnyObject).savedToDisk == false {
                
                return false
                
            }
            
        }
        
        return true
        
    }
    
    
    
    // MARK: - Delete photos
    func deletePhotoFromManagedContext(_ photo: Photo) {
        
        managedObjectContext.delete(photo)
        
        saveContext()
        
        
    }
    
    
    func deletePhotoFromManagedContextForUniqueId(_ uniqueId: String, photoUrlInfo: PhotoUrlInfo) {
        
        let photoId = photoUrlInfo.photoId
        
        let uniquePhotoId = photoId + uniqueId
        
        if let photoToDelete = fetchPhotoForId(uniquePhotoId) {
            
            managedObjectContext.delete(photoToDelete)
            
        }
        
        
        
    }
    
    func deleteAllPhotosForPinFromCoreData(_ uniqueId: String) {
        
        guard let pin = fetchPinForId(uniqueId) else { return }
        
        let photos = pin.photos as! Set<Photo>
        
        for photo in photos {
            
            photo.savedToDisk = false
            
            deletePhotoFromManagedContext(photo)
            
        }
        
    }
    
    
    
}
