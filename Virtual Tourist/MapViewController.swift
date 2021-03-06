//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - CLASS
class MapViewController: UIViewController, ContainerViewControllerDelegate {

    // MARK: - PROPERTIES
    
    // MARK: - @IBOutlets
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteView: UIView!
    
    // MARK: - Info view
    let editButtonEditTitle = "Edit"
    let editButtonDoneTitle = "Done"
    var deleteViewVisible = false
    
    // MARK: - Dragging annotation on creation
    var previousAnnotation = MKPointAnnotationWithUniqueId()
    
    // MARK: - Selected annotation
    var selectedAnnotation: MKPointAnnotationWithUniqueId!
    
    // MARK: - Storyboard segue strings
    let mapToContainerSegueString = "mapToContainerSegue"
    
    // MARK: - Core data
    var coreDataManager: CoreDataManager!
    var mapState: MapState?
    
    // MARK: - Geocoding queue
    lazy var geocodingQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Geocoding queue"
        
        return queue
        
    }()
    
    // MARK: - Download and save photos operations
    let downloadAndSavePhotosManager = DownloadAndSavePhotosManager()
    
    
    
    // MARK: - METHODS
    
    // MARK: - View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Subscribe to nofitications
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.appMovingToBackgroundOrTerminate), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.appMovingToBackgroundOrTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        
        // Load the map state
        mapState = coreDataManager.fetchMapState()
        
        if let mapState = mapState {
            
            mapView.setRegion(mapState.region, animated: false)
            
        }
        
        // Load existing pins to map
        addSavedPinsToMap()
        
        // Info view visibility and bar button title
        editButton.title = editButtonEditTitle
        deleteViewConstraint.constant = 0

        // Gesture recognizers
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addPinToMapView(_:)))
        
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    // MARK: - Application life cycle
    func appMovingToBackgroundOrTerminate() {
        
        // Save the map state
        if let mapState = mapState {
            
            coreDataManager.updateMapState(mapState, region: mapView.region)
            
        }
        
        // We will cancel all downloads when the app goes to background, in order to save user's bandwith and avoid surprising bills for mobile internet.
        downloadAndSavePhotosManager.cancelAllOperations()
        

    }
    
    

    // MARK: - @IBActions
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        
        if deleteViewConstraint.constant == 0 {
            
            editButton.title = editButtonDoneTitle
            
            adjustInfoViewsHeight(constant: 50)
            
            deleteViewVisible = true
            
        } else {
            
            editButton.title = editButtonEditTitle
            
            adjustInfoViewsHeight(constant: 0)
            
            deleteViewVisible = false
            
        }

    }
    
    func adjustInfoViewsHeight(constant: CGFloat) {
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.deleteViewConstraint.constant = constant
            self.view.layoutIfNeeded()
            
        })
        
    }
    

    // MARK: - Adding and removing pins
    
    // I want to exceed the following specifications:  "The app contains a map view that allows users to drop pins with a touch and hold gesture. When the pin drops, users can drag the pin until their finger is lifted."
    
    // After many searches I came to the following solution:
    
    // Add a pin on long press. When still pressing and moving the finger a new pin will be added with each move and at the same time the previously created pin will be removed.
    
    func addPinToMapView(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        guard deleteViewVisible == false else { return }
        
        switch longPressGestureRecognizer.state {
            
        case .possible:
            
            return
            
        case .began:
            
            let longPressLocation = longPressGestureRecognizer.location(in: mapView)
            let longPressCoordinate = mapView.convert(longPressLocation, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotationWithUniqueId()
            annotation.coordinate = longPressCoordinate
            
            mapView.addAnnotation(annotation)
            
            previousAnnotation = annotation
            
        case .changed:
            
            let longPressLocation = longPressGestureRecognizer.location(in: mapView)
            let longPressCoordinate = mapView.convert(longPressLocation, toCoordinateFrom: mapView)
            
            let currentAnnotation = MKPointAnnotationWithUniqueId()
            currentAnnotation.coordinate = longPressCoordinate
            
            mapView.removeAnnotation(previousAnnotation)
            
            mapView.addAnnotation(currentAnnotation)
            
            previousAnnotation = currentAnnotation
            
            return
            
        case .ended:
            
            let uniqueId = UUID().uuidString
            previousAnnotation.uniqueId = uniqueId
            
            coreDataManager.insertPinToMangedContext(forAnnotation: previousAnnotation)
            
            prefetchPhotosForAnnotation(previousAnnotation)
            
            return
            
        case .failed:
            
            return
            
        default:
            
            return
            
        }

    }
    
    func addSavedPinsToMap() {
        
        let savedPins = coreDataManager.fetchAllPins()
        
        var annotations = [MKPointAnnotationWithUniqueId]()
        
        for pin in savedPins {
            
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let uniqueId = pin.uniqueId
            
            let annotation = MKPointAnnotationWithUniqueId()
            annotation.coordinate = coordinate
            annotation.uniqueId = uniqueId
            
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
        
    }
    
    
    
    // MARK: - Storyboard segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == mapToContainerSegueString {
            
            let selectedPin = coreDataManager.fetchPinForAnnotation(selectedAnnotation)
            
            let containerViewController = segue.destination as! ContainerViewController
            
            containerViewController.selectedAnnotation = selectedAnnotation
            containerViewController.geocodingQueue = geocodingQueue
            containerViewController.coreDataManager = coreDataManager
            containerViewController.selectedPin = selectedPin
            containerViewController.delegate = self
            containerViewController.downloadAndSavePhotosManager = downloadAndSavePhotosManager

        }
        
    }
    
    
    // MARK: - Downloading images
    
    // We prefetch from Flickr a list of photos for the new annotation (for exceeding the project expectations :) and also for user experience, so that the user will have to wait less in order to see the photos for a given location).
    
    func prefetchPhotosForAnnotation(_ annotation: MKPointAnnotationWithUniqueId) {
        
        downloadAndSavePhotosManager.downloadAndSavePhotosForAnnotation(annotation, collectionUpdateStatus: CollectionUpdateStatus.AddNewCollection, missingPhotosUrlsList: nil, coreDataManager: coreDataManager)
        
    }
    
    
    func cancelDownloadingAndSavingPhotosForAnnotation(_ annotation: MKPointAnnotationWithUniqueId) {
        
        downloadAndSavePhotosManager.cancelDownloadingAndSavingPhotosForUniqueId(annotation.uniqueId)
        
    }
    
    
    
}


// MARK: - EXTENSIONS

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseIdentifier = "mapPin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            
            pinView!.canShowCallout = false
            
            pinView!.pinTintColor = UIColor.red
            

        }
            
        else {
            
            pinView!.annotation = annotation
            
        }


        return pinView
        
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        selectedAnnotation = view.annotation as! MKPointAnnotationWithUniqueId
        
        if deleteViewVisible {
            
            if view.annotation != nil {
                
                coreDataManager.deletePinFromManagedContext(forAnnotation: view.annotation!)
                
                mapView.removeAnnotation(view.annotation!)
                
                cancelDownloadingAndSavingPhotosForAnnotation(selectedAnnotation)
                
            }

        } else {
            
            performSegue(withIdentifier: mapToContainerSegueString, sender: nil)
            
            mapView.deselectAnnotation(view.annotation, animated: false)
            
        }

    }
    
    
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        
        if mapState == nil {
            
            coreDataManager.insertMapState(mapView.region)
        
        } else {
            
            coreDataManager.updateMapState(mapState!, region: mapView.region)
            
        }
        
    }
}



















