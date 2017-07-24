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
class ConcurrentOperation: Operation {
    
    // NSOperation's states to be observed
    enum State: String {
        
        case Ready, Executing, Finished
        
        fileprivate var keyPath: String {
            
            return "is" + rawValue
            
        }
        
    }
    
    // Observing the states
    var state = State.Ready {
        
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
}


// MARK: - EXTENSIONS

// MARK: - Extension for NSOperation overrides
extension ConcurrentOperation {

    override var isReady: Bool {
        return super.isReady && state == .Ready
    }
    
    override var isExecuting: Bool {
        return state == .Executing
    }
    
    override var isFinished: Bool {
        return state == .Finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        if isCancelled {
            state = .Finished
            return
        }
        
        main()
        state = .Executing
    }

    
}


