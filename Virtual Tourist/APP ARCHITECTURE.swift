//
//  ArchitectureDocument.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

/*
APP ARCHITECTURE


* DOWNLOADING AND GEOCODING OPERATIONS

The app will use NSOperationQueue and NSOperation subclasses for downloading images and geocoding.

The NSOperations will be concurrent since they are going to deal with asynchronous tasks, therefore they will subclass a ConcurrentOperations abstract class for getting the basic functionality. More info at: http://www.raywenderlich.com/123949/video-tutorial-introducing-concurrency-part-3-asynchronous-operations


1) Downloading images from Flickr

For each pin on the map the app will create an NSOperationQueue which will contain the following operations:

"get a list of maximum 21 photos for the location from Flickr" |> "insert photos to Core Data" |> "download, resize and save the photos to documents directory"

|> - signifies the dependancies among operations.




2) Exceeding expectations

Downloading images will start as soon as the pin is dropped on the map. 



3) Geocoding

Apple recommends to geocode just one location at the same time.

As a result, geocoding operations will be added to a separate serial geocodingQueue.



4) Adding new collection

The user will keep his existing photos for the selected location if he taps the "New collection" button, but there are no more photos to fetch from Flickr. However, he will be informed that no new photos are available. (At the moment, the official Udacity Virtual Tourist app shows a blank screen in such situations).


5) UICollectionView performance

In PhotoCollectionViewController the images will be cached in memory for a smoother scrolling. The NSCache will be used for caching the images.


* CORE DATA

1) Pins

Every time the pin will be added or deleted the managed context will be saved.

Since it is very unprobable that the app will contains tens of thousands of pins, the pins will be referenced using an unique identifier string, instead of NSManagedObjectID. The NSManagedObjectID may change during the life cycle of the managed object and therefore that would complicate the code.


2) Deleting photos (when the pin is deleted)

First, the NSOperationQueue asigned to the pin will get a cancelAll() method in order to cancel all the currently active downloads and thus save the bandwidth. After that the photos will be deleted from Core Data and Documents directory.





* KNOWN ISSUES

Error in console: "Snapshotting a view that has not been rendered results in an empty snapshot. Ensure your view has been rendered at least once before snapshotting or snapshot after screen updates."

Sometimes this error appears when deleting multiple photos. This seems to be a bug in the iOS system itself (
- https://forums.developer.apple.com/thread/8629
- http://stackoverflow.com/questions/25884801/ios-8-snapshotting-a-view-that-has-not-been-rendered-results-in-an-empty-snapsho



*/
