//
//  MapState.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class MapState: NSManagedObject {

    var center: CLLocationCoordinate2D {
        
        let clLatitude = latitude as CLLocationDegrees
        let clLongitude = longitude as CLLocationDegrees
        
        return CLLocationCoordinate2D(latitude: clLatitude, longitude: clLongitude)
        
    }
    
    var span: MKCoordinateSpan {
        
        let clLatitudeDelta = latitudeDelta as CLLocationDegrees
        let clLongitudeDelta = longitudeDelta as CLLocationDegrees
        
        return MKCoordinateSpan(latitudeDelta: clLatitudeDelta, longitudeDelta: clLongitudeDelta)
        
    }
    

    var region: MKCoordinateRegion {
        
        return MKCoordinateRegion(center: center, span: span)
        
    }
    
    
    

}
