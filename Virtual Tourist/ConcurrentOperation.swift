//
//  ConcurrentOperation.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation
import UIKit

// Abstract class for concurrent NSOperations

// MARK: - CLASS
class ConcurrentOperation: NSOperation {
    
    // NSOperation's states to be observed
    enum State: String {
        
        case Ready, Executing, Finished
        
        private var keyPath: String {
            
            return "is" + rawValue
            
        }
        
    }
    
    // Observing the states
    var state = State.Ready {
        
        willSet {
            willChangeValueForKey(newValue.keyPath)
            willChangeValueForKey(state.keyPath)
        }
        
        didSet {
            didChangeValueForKey(oldValue.keyPath)
            didChangeValueForKey(state.keyPath)
        }
    }
}


// MARK: - EXTENSIONS

// MARK: - Extension for NSOperation overrides
extension ConcurrentOperation {

    override var ready: Bool {
        return super.ready && state == .Ready
    }
    
    override var executing: Bool {
        return state == .Executing
    }
    
    override var finished: Bool {
        return state == .Finished
    }
    
    override var asynchronous: Bool {
        return true
    }
    
    override func start() {
        if cancelled {
            state = .Finished
            return
        }
        
        main()
        state = .Executing
    }

    
}


