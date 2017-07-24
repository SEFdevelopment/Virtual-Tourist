//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    // MARK: - PROPERTIES
    
    // MARK: - @IBOutlets
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Cell state
    var imageIsLoaded = false
    
    override var isSelected: Bool {
        
        didSet {
            
            if imageIsLoaded {
                
                selectionView.isHidden = !isSelected
                
            }
            
        }
        
    }
    
    
    // MARK: - Prepare for reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        
    }
    
    
    
    
}












