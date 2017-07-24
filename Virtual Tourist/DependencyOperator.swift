//
//  DependancyOperator.swift
//  Virtual Tourist
//
//  Created by Andrei Sadovnicov on 27/02/16.
//  Copyright © 2016 Andrei Sadovnicov. All rights reserved.
//

import Foundation

// Operator overload for adding dependencies between NSOperations in a more clear way. This tip was taken from http://www.raywenderlich.com/123996/video-tutorial-introducing-concurrency-part-4-dependencies

infix operator |> { associativity left precedence 160 }

func |>(lhs: Operation, rhs: Operation) -> Operation {
    
    rhs.addDependency(lhs)
    
    return rhs
}
