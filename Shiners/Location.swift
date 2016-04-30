//
//  Location.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class Location{
    public var id: String?
    public var userId: String?
    public var name: String?
    public var lat: Double?
    public var lng: Double?
    public var placeType: String?
    public var isPublic: Bool?
    
    public init (fields: NSDictionary?){
        
        self.id = fields?.valueForKey("_id") as? String
        self.userId = fields?.valueForKey("userId") as? String
        self.name = fields?.valueForKey("name") as? String
        
        if let coords = fields?.valueForKey("coords") as? NSDictionary{
            self.lat = coords.valueForKey("lat") as? Double
            self.lng = coords.valueForKey("lng") as? Double
        }
        
        self.placeType = fields?.valueForKey("placeType") as? String
        self.isPublic = fields?.valueForKey("public") as? Bool
    }
}