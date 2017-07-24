//
//  ContainerViewController.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - PROTOCOLS
protocol ContainerViewControllerDelegate: class {
    
    func appMovingToBackgroundOrTerminate()
    
}


// MARK: - CLASS
class ContainerViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    // MARK: - PROPERTIES
    
    // MARK: - @IBOutlets
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var manageCollectionButton: UIBarButtonItem!
    
    // MARK: - Status view
    let noPhotosString = "No photos."
    
    // MARK: - Selected annotation
    var selectedAnnotation: MKPointAnnotationWithUniqueId!
    
    // MARK: - Storyboard segue strings
    let containerToSmallMapSegueString = "containerToSmallMapSegue"
    let containerToPhotoCollectionSegueString = "containerToPhotoCollectionSegue"
    let containerToLocationInfoSegueString = "containerToLocationInfoSegue"
    
    // MARK: - Queues and operations
    var geocodingQueue: OperationQueue!
    var downloadAndSavePhotosManager: DownloadAndSavePhotosManager!
    
    // MARK: - Core data
    var coreDataManager: CoreDataManager!
    var selectedPin: Pin!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var pinEntityName = "Pin"

    // MARK: - Delegate
    weak var delegate: ContainerViewControllerDelegate?

    
    // MARK: - METHODS
    
    // MARK: - View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Subscribe to nofitications
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerViewController.appMovingToBackgroundOrTerminate), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerViewController.appMovingToBackgroundOrTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerViewController.appDidEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        // Fetched results controller
        initializeFetchedResultsController()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureStatusView()
        
    }
    

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController.delegate = nil
        fetchedResultsController = nil
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    
    // MARK: - Application life cycle
    func appMovingToBackgroundOrTerminate() {
        
        delegate?.appMovingToBackgroundOrTerminate()
        
    }
    
    
    func appDidEnterForeground() {
        
        configureStatusView()
    }
    
    
    // MARK: - Storyboard segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == containerToSmallMapSegueString {
            
            let smallMapViewController = segue.destination as! SmallMapViewController
            
            smallMapViewController.selectedAnnotation = selectedAnnotation
            
        }
        
        
        if segue.identifier == containerToPhotoCollectionSegueString {
            
            let photoCollectionViewController = segue.destination as! PhotoCollectionViewController
            
            photoCollectionViewController.coreDataManager = coreDataManager
            photoCollectionViewController.selectedPin = selectedPin
            photoCollectionViewController.manageCollectionButton = manageCollectionButton
            photoCollectionViewController.delegate = self
            
            
        }
        
        
        if segue.identifier == containerToLocationInfoSegueString {
            
            let locationInfoViewController = segue.destination as! LocationInfoViewController
            
            locationInfoViewController.selectedAnnotation = selectedAnnotation
            locationInfoViewController.selectedPin = selectedPin
            locationInfoViewController.coreDataManager = coreDataManager
            
            locationInfoViewController.geocodingQueue = geocodingQueue
            
            // This view controller will be shown as a popover, even on iPhones
            locationInfoViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            locationInfoViewController.popoverPresentationController?.delegate = self
            locationInfoViewController.preferredContentSize = CGSize(width: 300, height: 370)
            
            
        }
        
    }
    
    // MARK: - Popovers
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
        
    }
    
    
}


// MARK: - EXTENSIONS

// MARK: - Manage statusView
extension ContainerViewController {
    
    func configureStatusView() {
        
        var downloadIsOngoing: Bool
        
        let activeOperationForSelectedPin = downloadAndSavePhotosManager.activeOperationForUniqueId(selectedPin.uniqueId)
        
        if (activeOperationForSelectedPin == nil) || (activeOperationForSelectedPin!.isFinished) {
            
            downloadIsOngoing = false
            
        } else {
            
            downloadIsOngoing = true
            
        }
        
        guard let downloadAndSaveStatus = DownloadAndSaveStatus(rawValue:selectedPin.downloadAndSaveStatus) else { return }
        
        switch downloadAndSaveStatus {
            
            case .UrlsNotLoaded:
            
                switch downloadIsOngoing {
                    
                case true:
                    
                    manageCollectionButton.isEnabled = false
                    activityIndicator.startAnimating()
                    statusView.isHidden = false
                    
                case false:
                    
                    manageCollectionButton.isEnabled = true
                    activityIndicator.stopAnimating()
                    statusView.isHidden = false
                    
                }
            
        
            case .UrlsLoadingError, .NoPhotosForSelectedLocation:
                
                if selectedPin.photos.count == 0 {
                    
                    manageCollectionButton.isEnabled = true
                    activityIndicator.stopAnimating()
                    statusView.isHidden = false
                    
                } else {
                    
                    manageCollectionButton.isEnabled = true
                    activityIndicator.stopAnimating()
                    statusView.isHidden = true
                }
                


            
            case .InsertedPhotosForUrlsList:
                
                manageCollectionButton.isEnabled = false
                activityIndicator.stopAnimating()
                statusView.isHidden = true
            
                switch downloadIsOngoing {
                    
                case true:
                    
                    return
                    

                case false:
                
                // The app was in background, we will need to restart the photo downloads for situations when not all photos in collection are loaded.
                    var photoUrlsList = [PhotoUrlInfo]()
                    
                    // Get the list of photos which have not been downloaded and saved
                    let photos = selectedPin.photos as! Set<Photo>
                    
                    for photo in photos {
                        
                        if !photo.savedToDisk {
                            
                            let photoUrlInfo = PhotoUrlInfo(photoId: photo.photoId, photoUrl: photo.photoUrl)
                            
                            photoUrlsList.append(photoUrlInfo)
                            
                        }
                        
                    }
                    
                    downloadAndSavePhotosManager.downloadAndSavePhotosForAnnotation(selectedAnnotation, collectionUpdateStatus: CollectionUpdateStatus.DownloadMissingPhotos, missingPhotosUrlsList: photoUrlsList, coreDataManager: coreDataManager)
                
                    
            }
            
            
            case .AllPhotosHaveBeenDownloadedAndSaved:
            
                manageCollectionButton.isEnabled = true
                activityIndicator.stopAnimating()
                statusView.isHidden = true
        
            
            case .AllPhotosHaveBeenDeleted:
            
                manageCollectionButton.isEnabled = true
                activityIndicator.stopAnimating()
                statusView.isHidden = false
            
            
        }
        
        
    }
    
    
    
    
    
}




// MARK: - PhotoCollectionViewControllerDelegate
extension ContainerViewController: PhotoCollectionViewControllerDelegate {
    
    func addNewCollection() {
        
        if statusView.isHidden == true {
            
            activityIndicator.startAnimating()
            statusLabel.text = ""
            statusView.alpha = 0.0
            statusView.isHidden = false
            
            UIView.animate(withDuration: 1.5, delay: 0.0, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
                
                    self.statusView.alpha = 1.0
                
                }, completion: nil)
            
            
        } else {
            
            UIView.animate(withDuration: 1.5, animations: {
                
                    self.statusLabel.text = ""
                
                }, completion: { _ in
                    
                    self.activityIndicator.startAnimating()
            })
            
        }
        
        downloadAndSavePhotosManager.downloadAndSavePhotosForAnnotation(selectedAnnotation, collectionUpdateStatus: CollectionUpdateStatus.AddNewCollection, missingPhotosUrlsList: nil, coreDataManager: coreDataManager)
        
    }
    
    
    func photoControllerDidDeleteAllPhotos() {
        
        coreDataManager.updateDownloadAndSaveStatusForPin(selectedPin.uniqueId, downloadAndSaveStatus: DownloadAndSaveStatus.AllPhotosHaveBeenDeleted.rawValue)
        
    }
    

    
    
}



// MARK: - NSFetchedResults controller
extension ContainerViewController: NSFetchedResultsControllerDelegate {
    
    func initializeFetchedResultsController() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: pinEntityName)
        
        let predicate = NSPredicate(format: "uniqueId = %@", selectedPin.uniqueId)
        
        request.predicate = predicate
        
        let uniqueIdSortDescriptor = NSSortDescriptor(key: "uniqueId", ascending: true)
        
        request.sortDescriptors = [uniqueIdSortDescriptor]
        
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
        
        switch type {
            
        case .update:

            guard let pin = anObject as? Pin else { return }
            
            // We do not want to react here when the changes to the pin's photo property is happening. We are interested just in the downloadAndSaveStatus.
            
            let changedValues = pin.changedValuesForCurrentEvent()
            
            guard changedValues["photos"] == nil else { return }

            
            guard let downloadAndSaveStatus = DownloadAndSaveStatus(rawValue: pin.downloadAndSaveStatus) else { return }
            
            
            switch downloadAndSaveStatus {
                
            case .UrlsLoadingError, .NoPhotosForSelectedLocation:
                
                // If there have been photos for the selected pin, we present the alert and keep showing the existing photos, otherwise we show the status view.
                
                if selectedPin.photos.count == 0 {
                    
                    // Show the statusView
                    activityIndicator.stopAnimating()
                    statusLabel.text = noPhotosString
                    manageCollectionButton.isEnabled = true
                    
                    
                } else {
                    
                    // Reset the status of the pin back to AllPhotosHaveBeenDownloadedAndSaved state
                    coreDataManager.updateDownloadAndSaveStatusForPin(selectedPin.uniqueId, downloadAndSaveStatus: DownloadAndSaveStatus.AllPhotosHaveBeenDownloadedAndSaved.rawValue)
                    
                    // Present the alert
                    let noMorePhotosAlert = AlertControllers.noMorePhotosFoundAlert()
                    present(noMorePhotosAlert, animated: true, completion: nil)
                    
                    // Hide the statusView
                    manageCollectionButton.isEnabled = true
                    
                    UIView.animate(withDuration: 1.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        
                        self.statusView.alpha = 0.0
                        
                        }, completion: { _ in
                            
                            self.activityIndicator.stopAnimating()
                            self.statusView.isHidden = true
                            self.statusView.alpha = 1.0
                            
                    })
                    
                }
                
                
            
            case .InsertedPhotosForUrlsList:
                
                manageCollectionButton.isEnabled = false
                
                if statusView.isHidden == false {
                    
                    UIView.animate(withDuration: 1.5, delay: 1.7, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        
                            self.statusView.alpha = 0.0
                        
                        }, completion: { _ in
                            
                            self.activityIndicator.stopAnimating()
                            self.statusView.isHidden = true
                            self.statusView.alpha = 1.0
                            
                    })
                    
                    
                }
                
                
                
            case .AllPhotosHaveBeenDownloadedAndSaved:
                
                manageCollectionButton.isEnabled = true
                
                
                
            case .AllPhotosHaveBeenDeleted:
                
                manageCollectionButton.isEnabled = true
                activityIndicator.stopAnimating()
                statusLabel.text = noPhotosString
                
                statusView.alpha = 0.0
                statusView.isHidden = false
                
                UIView.animate(withDuration: 1.0, delay: 0.0, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
                    
                        self.statusView.alpha = 1.0
                    
                    }, completion: nil)
                
  
                
            default:
                
                return
            
            }
            
            
        default:
            
            return
            
            
        }
        
        
    }
  
    
}









