//
//  PhotoCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit
import CoreData


// MARK: - PROTOCOLS
protocol PhotoCollectionViewControllerDelegate: class {
    
    func photoControllerDidDeleteAllPhotos()
    
    func addNewCollection()
    
}


// MARK: - CLASS
class PhotoCollectionViewController: UICollectionViewController {
    
    // MARK: - PROPERTIES
    
    // MARK: - Collection cell reuse identifier
    private let cellReuseIdentifier = "photoCell"
    
    // MARK: - Core data
    var selectedPin: Pin!
    var coreDataManager: CoreDataManager!
    var fetchedResultsController: NSFetchedResultsController!
    var photoEntityName = "Photo"
    
    // MARK: - UICollectionView performance
    let photoCache = NSCache()
    
    
    // MARK: - Manage collection button
    var manageCollectionButton: UIBarButtonItem!
    let removeSelectedPicturesString = "Remove selected pictures"
    let newCollectionString = "New Collection"
    var collectionViewInSelectionMode = false
    
    // MARK: - Selections
    var selectedPhotos = [Photo]()
    
    // MARK: - Delegate
    weak var delegate: PhotoCollectionViewControllerDelegate?
    
    
    // MARK: - METHODS
    
    // MARK: - View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure collection view selections
        collectionView!.allowsMultipleSelection = true
        
        // Target-action
        manageCollectionButton.target = self
        manageCollectionButton.action = "manageCollectionButtonTapped"

        // Fetched results controller
        initializeFetchedResultsController()
        
    }
    

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Configure collection view layout
        configureFlowLayout()
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        cacheAllPhotos()
        
    }

    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController.delegate = nil
        fetchedResultsController = nil
        
    }
    

    
    // MARK: - @IBActions
    func manageCollectionButtonTapped() {
        
        // Delete
        if collectionViewInSelectionMode {
            
            for selectedPhoto in selectedPhotos {
                
                coreDataManager.deletePhotoFromManagedContext(selectedPhoto)
                
            }
            
            manageCollectionButton.enabled = true
            manageCollectionButton.title = newCollectionString
            collectionViewInSelectionMode = false
            
            // If all photos have been deleted change the selection state to false and update the button.
            guard let numberOfPhotosAfterDelete = fetchedResultsController.fetchedObjects?.count else { return }
            
            if numberOfPhotosAfterDelete == 0 {
                
                delegate?.photoControllerDidDeleteAllPhotos()
                
            }
            
            
        // Add new collection
        } else {
            
            // Check if there is internet and notify user if it is absent
           guard Reachability.isConnectedToNetwork() else { presentViewController(AlertControllers.noInternetAlert(), animated: true, completion: nil); return }
            
            // Disable button
            manageCollectionButton.enabled = false
            
            // Download photos
            delegate?.addNewCollection()
            
            
        }
        
    }
    


    // MARK: - Configure flow layout
    func configureFlowLayout() {
        
        let width = CGRectGetWidth(collectionView!.frame) / 3
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
        
    }
    

    // MARK: - UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let sections = fetchedResultsController.sections {
            
            let currentSection = sections[section]
            
            return currentSection.numberOfObjects
            
        }
        
        return 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
    
        guard let photo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo else { return cell }
        
        // Photo not saved yet to disk: show loading view and animating activity indicator.
        guard photo.savedToDisk else {
            
            cell.loadingView.hidden = false
            cell.activityIndicator.startAnimating()
            
            return cell
            
        }
        
        
        // Load photo from cache if it is cached already
        if let photoImage = photoCache.objectForKey(photo.photoUniqueId) as? UIImage {
            
            cell.activityIndicator.stopAnimating()
            cell.loadingView.hidden = true
            
            cell.imageView.hidden = false
            cell.imageView.image = photoImage
            
            cell.imageIsLoaded = true
            
            return cell
            
        }
            
        // If photo is not cached try to open it from disk and cache it, otherwise show loading view and animating activity indicator
        let photoUrlComponent = photo.photoUniqueId + ".jpg"
        let photoPath = virtualTouristPhotosDirectoryUrl.URLByAppendingPathComponent(photoUrlComponent).path!
        
        if let photoImage = UIImage(contentsOfFile: photoPath) {
            
            photoCache.setObject(photoImage, forKey: photo.photoUniqueId)
            
            cell.activityIndicator.stopAnimating()
            cell.loadingView.hidden = true
            
            cell.imageView.hidden = false
            cell.imageView.image = photoImage
            
            cell.imageIsLoaded = true
            
            return cell
            
        } else {
            
            cell.loadingView.hidden = false
            cell.activityIndicator.startAnimating()
            
            return cell
            
        }
        
    }
    
    // MARK: - UICollectionView delegate
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoCollectionViewCell else { return false }
        
        let downloadAndSaveStatus = selectedPin.downloadAndSaveStatus
        
        let photosSaved = (downloadAndSaveStatus == DownloadAndSaveStatus.AllPhotosHaveBeenDownloadedAndSaved.rawValue)
        let noPhotosFound = (downloadAndSaveStatus == DownloadAndSaveStatus.NoPhotosForSelectedLocation.rawValue)
        let downloadPhotosError = (downloadAndSaveStatus == DownloadAndSaveStatus.UrlsLoadingError.rawValue)

        if (cell.imageIsLoaded) && (photosSaved || noPhotosFound || downloadPhotosError) {
            
            return true
            
        }
        
        return false
        
    }
    
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        manageCollectionButton.title = removeSelectedPicturesString
        
        collectionViewInSelectionMode = true
        
        guard let selectedPhoto = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo else { return }
        
        selectedPhotos.append(selectedPhoto)
        
    }
    
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView.indexPathsForSelectedItems()?.count == 0 {
        
            manageCollectionButton.title = newCollectionString
            
            collectionViewInSelectionMode = false
        
        }
        
        guard let deselectedPhoto = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo else { return }
        
        guard let deselectedPhotoIndex = selectedPhotos.indexOf(deselectedPhoto) else { return }
        
        selectedPhotos.removeAtIndex(deselectedPhotoIndex)
        
    }
    
    
    // MARK - Photo caching
    func cachePhoto(photoUniqueId: String) {
        
        let photoUrlComponent = photoUniqueId + ".jpg"
        
        let photoPath = virtualTouristPhotosDirectoryUrl.URLByAppendingPathComponent(photoUrlComponent).path!
        
        if let photoImage = UIImage(contentsOfFile: photoPath) {
            
            photoCache.setObject(photoImage, forKey: photoUniqueId)
            
        }
        
    }
    
    
    func cacheAllPhotos() {
        
        guard selectedPin.downloadAndSaveStatus == DownloadAndSaveStatus.AllPhotosHaveBeenDownloadedAndSaved.rawValue else { return }
        
        guard let photos = fetchedResultsController.fetchedObjects as? [Photo] else { return }
        
        for photo in photos {
            
            cachePhoto(photo.photoUniqueId)
            
        }
        
    }
    

}


// MARK: - EXTENSIONS

// MARK: - NSFetchedResults controller
extension PhotoCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func initializeFetchedResultsController() {
        
        let request = NSFetchRequest(entityName: photoEntityName)
        
        let predicate = NSPredicate(format: "pin = %@", selectedPin)
        
        request.predicate = predicate
        
        let photoIdSortDescriptor = NSSortDescriptor(key: "photoId", ascending: false)
        
        request.sortDescriptors = [photoIdSortDescriptor]
        
        let managedObjectContext = coreDataManager.managedObjectContext
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            
            try fetchedResultsController.performFetch()
            
        } catch {
            
            fatalError("Failed to initialize FetchedResultsController: \(error)")
            
        }
        
    }

    
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
        case .Insert:
            
            photoCache.removeAllObjects()
            
            collectionView?.reloadData()
            
            
        case .Update:
            
            if let indexPath = indexPath {
                
                guard let photo = anObject as? Photo else { return }
                
                cachePhoto(photo.photoUniqueId)
                
                collectionView?.reloadItemsAtIndexPaths([indexPath])
                
            }
            
  
        case .Delete:
            
            if manageCollectionButton.title == removeSelectedPicturesString {
                
                if let indexPath = indexPath {
                    
                    if let photo = anObject as? Photo {
                        
                        photoCache.removeObjectForKey(photo.photoUniqueId)
                        
                    }
                    
                    collectionView?.deleteItemsAtIndexPaths([indexPath])
                    
                }
                
            }
            
            
        case .Move:
            
            return
            
        }
        
        
    }
    
    
    
}





















