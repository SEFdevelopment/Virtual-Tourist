//
//  LocationInfoViewController.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - CLASS
class LocationInfoViewController: UITableViewController {

    // MARK: - PROPERTIES
    
    // MARK: - @IBOutlets
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var latitudeValueLabel: UILabel!
    @IBOutlet weak var longitudeValueLabel: UILabel!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingStatusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Selected annotation
    var selectedAnnotation: MKPointAnnotationWithUniqueId!
    
    // MARK: - Core data
    var selectedPin: Pin!
    var coreDataManager: CoreDataManager!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var locationInfoEntityName = "LocationInfo"
    
    // MARK: - Geocoding queue
    var geocodingQueue: OperationQueue!
    
    // MARK: - Loading status strings
    let gettingAddressString = "Getting address..."
    let couldNotFindAddressString = "Could not find address. Please check your internet connection and try again later."
    
    // MARK: - METHODS
    
    // MARK: - View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Populate the labels for latitude and longitude
        let latitudeString = String(selectedAnnotation.coordinate.latitude)
        let longitudeString = String(selectedAnnotation.coordinate.longitude)
        
        latitudeValueLabel.text = latitudeString
        longitudeValueLabel.text = longitudeString
        
        
        // Populate the text view with address
        if (selectedPin.locationInfo) == nil || (selectedPin.locationInfo?.addressString == reverseGeocodingErrorString){
            
            showLoadingView()
            
            reverseGeocodeSelectedAnnotation()
            
        } else {
            
            addressTextView.text = selectedPin.locationInfo?.addressString
            
        }
        
        
        // Fetched results controller
        initializeFetchedResultsController()
        
    }
    
    
    
    // MARK: - Loading views
    func showLoadingView() {
        
        loadingStatusLabel.text = gettingAddressString
        loadingView.isHidden = false
        activityIndicator.startAnimating()
        
    }
    
    func hideLoadingView() {

        activityIndicator.stopAnimating()
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            
                self.loadingView.alpha = 0.0
            
            }, completion: { _ in
                
                self.loadingView.isHidden = true
                
        })
        
    }
    
    
    
    // MARK: - Geocode annotation
    func reverseGeocodeSelectedAnnotation() {
        
        let coordinate = selectedAnnotation.coordinate
        let uniqueId = selectedAnnotation.uniqueId
        
        let reverseGeocodingOperation = ReverseGeocodingOperation(coordinate: coordinate, uniqueId: uniqueId!, coreDataManager: coreDataManager)
        
        geocodingQueue.addOperation(reverseGeocodingOperation)
        
    }
    

}


// MARK: - EXTENSIONS

// MARK: - NSFetchResults controller
extension LocationInfoViewController: NSFetchedResultsControllerDelegate {
    
    func initializeFetchedResultsController() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: locationInfoEntityName)
        let addressStringSortDescriptor = NSSortDescriptor(key: "addressString", ascending: true)
        
        request.sortDescriptors = [addressStringSortDescriptor]
        
        let managedObjectContext = coreDataManager.managedObjectContext
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            
            try fetchedResultsController.performFetch()
            
        } catch {
            
            fatalError("Failed to initialize FetchedResultsController: \(error)")
            
        }

    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == .insert || type == .update || type == .move {
            
            hideLoadingView()
            
            let addressString = selectedPin.locationInfo?.addressString
            
            if addressString == reverseGeocodingErrorString {
                
                addressTextView.text = couldNotFindAddressString
                
            } else {
                
                addressTextView.text = addressString
                
            }
            
            
        }
        
    }
    
    
    
}

























