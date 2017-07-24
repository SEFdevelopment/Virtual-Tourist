//
//  SmallMapViewController.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit
import MapKit

class SmallMapViewController: UIViewController {

    // MARK: - PROPERTIES
    
    // MARK: - @IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Selected annotation
    var selectedAnnotation: MKPointAnnotationWithUniqueId!
    
    
    // MARK: - METHODS
    
    // MARK: - View controller life cycle    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let region = MKCoordinateRegionMakeWithDistance(selectedAnnotation.coordinate, 300000, 300000) //If putting smaller values, the map may not render in some areas of the globe
        
        mapView.centerCoordinate = selectedAnnotation.coordinate
        
        mapView.setRegion(region, animated: false)
        
        mapView.addAnnotation(selectedAnnotation)
        
    }
    

}
