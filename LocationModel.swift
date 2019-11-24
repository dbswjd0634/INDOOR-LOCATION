//
//  LocationModel.swift
//  AR
//
//  Copyright © 2019 M-33. All rights reserved.
//

import Foundation

class LocationModel: NSObject {
    
    //properties
    
    var major: Int?
    var minor: Int?
    var x: Int?
    var y: Int?
    var z: Int?

    //empty constructor
    
    override init()
    {
        
    }
    
    //construct with @name, @address, @latitude, and @longitude parameters
    
    init(major: Int, minor: Int, x: Int, y: Int, z: Int) {
        
        self.major = major
        self.minor = minor
        self.x = x
        self.y = y
        self.z = z
        
    }
    
    
    //prints object's current state

    override var description: String {
        return "Major: \(String(describing: major)), Minor: \(String(describing: minor)), X: \(String(describing: x)), y: \(String(describing: y)), z: \(String(describing: z))"
        
    }
    
    
}
