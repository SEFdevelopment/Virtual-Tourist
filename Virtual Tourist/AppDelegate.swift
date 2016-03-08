//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - PROPERTIES
    
    // MARK: - Window
    var window: UIWindow?
    
    // MARK: - Core data stack
    lazy var coreDataStack = CoreDataStack()
    var coreDataManager: CoreDataManager!

    // MARK: - METHODS
    
    // MARK: - Application life cycle
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Pass the coreDataStack
        let navigationController = self.window!.rootViewController as! UINavigationController
        
        let mapViewController = navigationController.topViewController as! MapViewController
        
        coreDataManager = CoreDataManager(managedObjectContext: coreDataStack.managedObjectContext)
        
        mapViewController.coreDataManager = coreDataManager
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
        coreDataManager.saveContext()
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        
        coreDataManager.saveContext()
        
    }


}

