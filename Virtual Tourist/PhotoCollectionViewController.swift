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
    fileprivate let cellReuseIdentifier = "photoCell"
    
    // MARK: - Core data
    var selectedPin: Pin!
    var coreDataManager: CoreDataManager!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var photoEntityName = "Photo"
    
    // MARK: - UICollectionView performance
    let photoCache = NSCache<AnyObject, AnyObject>()
    
    
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
        manageCollectionButton.action = #selector(PhotoCollectionViewController.manageCollectionButtonTapped)

        // Fetched results controller
        initializeFetchedResultsController()
        
    }
    

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Configure collection view layout
        configureFlowLayout()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cacheAllPhotos()
        
    }

    
    override func viewWillDisappear(_ animated: Bool) {
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
            
            manageCollectionButton.isEnabled = true
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
           guard Reachability.isConnectedToNetwork() else { present(AlertControllers.noInternetAlert(), animated: true, completion: nil); return }
            
            // Disable button
            manageCollectionButton.isEnabled = false
            
            // Download photos
            delegate?.addNewCollection()
            
            
        }
        
    }
    


    // MARK: - Configure flow layout
    func configureFlowLayout() {
        
        let width = collectionView!.frame.width / 3
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
        
    }
    

    // MARK: - UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let sections = fetchedResultsController.sections {
            
            let currentSection = sections[section]
            
            return currentSection.numberOfObjects
            
        }
        
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
    
        guard let photo = fetchedResultsController.object(at: indexPath) as? Photo else { return cell }
        
        // Photo not saved yet to disk: show loading view and animating activity indicator.
        guard photo.savedToDisk else {
            
            cell.loadingView.isHidden = false
            cell.activityIndicator.startAnimating()
            
            return cell
            
        }
        
        
        // Load photo from cache if it is cached already
        if let photoImage = photoCache.object(forKey: photo.photoUniqueId as AnyObject) as? UIImage {
            
            cell.activityIndicator.stopAnimating()
            cell.loadingView.isHidden = true
            
            cell.imageView.isHidden = false
            cell.imageView.image = photoImage
            
            cell.imageIsLoaded = true
            
            return cell
            
        }
            
        // If photo is not cached try to open it from disk and cache it, otherwise show loading view and animating activity indicator
        let photoUrlComponent = photo.photoUniqueId + ".jpg"
        let photoPath = virtualTouristPhotosDirectoryUrl.appendingPathComponent(photoUrlComponent).path
        
        if let photoImage = UIImage(contentsOfFile: photoPath) {
            
            photoCache.setObject(photoImage, forKey: photo.photoUniqueId as AnyObject)
            
            cell.activityIndicator.stopAnimating()
            cell.loadingView.isHidden = true
            
            cell.imageView.isHidden = false
            cell.imageView.image = photoImage
            
            cell.imageIsLoaded = true
            
            return cell
            
        } else {
            
            cell.loadingView.isHidden = false
            cell.activityIndicator.startAnimating()
            
            return cell
            
        }
        
    }
    
    // MARK: - UICollectionView delegate
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else { return false }
        
        let downloadAndSaveStatus = selectedPin.downloadAndSaveStatus
        
        let photosSaved = (downloadAndSaveStatus == DownloadAndSaveStatus.AllPhotosHaveBeenDownloadedAndSaved.rawValue)
        let noPhotosFound = (downloadAndSaveStatus == DownloadAndSaveStatus.NoPhotosForSelectedLocation.rawValue)
        let downloadPhotosError = (downloadAndSaveStatus == DownloadAndSaveStatus.UrlsLoadingError.rawValue)

        if (cell.imageIsLoaded) && (photosSaved || noPhotosFound || downloadPhotosError) {
            
            return true
            
        }
        
        return false
        
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        manageCollectionButton.title = removeSelectedPicturesString
        
        collectionViewInSelectionMode = true
        
        guard let selectedPhoto = fetchedResultsController.object(at: indexPath) as? Photo else { return }
        
        selectedPhotos.append(selectedPhoto)
        
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if collectionView.indexPathsForSelectedItems?.count == 0 {
        
            manageCollectionButton.title = newCollectionString
            
            collectionViewInSelectionMode = false
        
        }
        
        guard let deselectedPhoto = fetchedResultsController.object(at: indexPath) as? Photo else { return }
        
        guard let deselectedPhotoIndex = selectedPhotos.index(of: deselectedPhoto) else { return }
        
        selectedPhotos.remove(at: deselectedPhotoIndex)
        
    }
    
    
    // MARK - Photo caching
    func cachePhoto(_ photoUniqueId: String) {
        
        let photoUrlComponent = photoUniqueId + ".jpg"
        
        let photoPath = virtualTouristPhotosDirectoryUrl.appendingPathComponent(photoUrlComponent).path
        
        if let photoImage = UIImage(contentsOfFile: photoPath) {
            
            photoCache.setObject(photoImage, forKey: photoUniqueId as AnyObject)
            
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
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: photoEntityName)
        
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

    
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            
        case .insert:
            
            photoCache.removeAllObjects()
            
            collectionView?.reloadData()
            
            
        case .update:
            
            if let indexPath = indexPath {
                
                guard let photo = anObject as? Photo else { return }
                
                cachePhoto(photo.photoUniqueId)
                
                collectionView?.reloadItems(at: [indexPath])
                
            }
            
  
        case .delete:
            
            if manageCollectionButton.title == removeSelectedPicturesString {
                
                if let indexPath = indexPath {
                    
                    if let photo = anObject as? Photo {
                        
                        photoCache.removeObject(forKey: photo.photoUniqueId as AnyObject)
                        
                    }
                    
                    collectionView?.deleteItems(at: [indexPath])
                    
                }
                
            }
            
            
        case .move:
            
            return
            
        }
        
        
    }
    
    
    
}





















