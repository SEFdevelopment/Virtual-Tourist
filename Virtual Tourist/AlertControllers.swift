//
//  AlertControllers.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit

class AlertControllers {
    
    // MARK: - No internet alert
    class func noInternetAlert() -> UIAlertController {
        
        let title = NSLocalizedString("No internet", comment: "")
        let message = NSLocalizedString("There seem to be no internet connection. Please turn on the internet on your device and try again.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Dismiss", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        return alertController
    }
    
    
    // MARK: - No more photos found alert
    class func noMorePhotosFoundAlert() -> UIAlertController {
        
        let title = NSLocalizedString("No more photos", comment: "")
        let message = NSLocalizedString("There seem to be no more photos for this location. You may try again later.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Dismiss", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        return alertController
        
        
    }
    
    
}
