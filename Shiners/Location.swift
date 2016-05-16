//
//  Location.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class Location: NSObject, NSCoding {
    public var id: String?
    public var userId: String?
    public var name: String?
    public var lat: Double?
    public var lng: Double?
    public var placeType: String?
    public var isPublic: Bool?
    
    public init (fields: NSDictionary?){
        super.init()
        
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
    
    public required init(coder aDecoder: NSCoder) {
        super.init()
        self.id = aDecoder.decodeObjectForKey(PropertyKeys.id) as? String
        self.userId = aDecoder.decodeObjectForKey(PropertyKeys.userId) as? String
        self.name = aDecoder.decodeObjectForKey(PropertyKeys.name) as? String
        if aDecoder.containsValueForKey(PropertyKeys.lat){
            self.lat = aDecoder.decodeDoubleForKey(PropertyKeys.lat)
        }
        if aDecoder.containsValueForKey(PropertyKeys.lng){
            self.lng = aDecoder.decodeDoubleForKey(PropertyKeys.lng)
        }
        self.placeType = aDecoder.decodeObjectForKey(PropertyKeys.placeType) as? String
        if aDecoder.containsValueForKey(PropertyKeys.isPublic){
            self.isPublic = aDecoder.decodeBoolForKey(PropertyKeys.isPublic)
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.id, forKey: PropertyKeys.id)
        aCoder.encodeObject(self.userId, forKey: PropertyKeys.userId)
        aCoder.encodeObject(self.name, forKey: PropertyKeys.name)
        if let lat = self.lat{
            aCoder.encodeDouble(lat, forKey: PropertyKeys.lat)
        }
        if let lng = self.lng {
            aCoder.encodeDouble(lng, forKey: PropertyKeys.lng)
        }
        aCoder.encodeObject(self.placeType, forKey: PropertyKeys.placeType)
        if let isPublic = self.isPublic {
            aCoder.encodeBool(isPublic, forKey: PropertyKeys.isPublic)
        }
    }
    
    private struct PropertyKeys {
        static let id = "id"
        static let userId = "userId"
        static let name = "name"
        static let lat = "lat"
        static let lng = "lng"
        static let placeType = "placeType"
        static let isPublic = "isPublic"
    }
}