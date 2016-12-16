//
//  Location.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class Location: NSObject, NSCoding {
    open var id: String?
    open var userId: String?
    open var name: String?
    open var lat: Double?
    open var lng: Double?
    open var placeType: PlaceType?
    open var isPublic: Bool?
    
    public override init (){
        super.init()
    }
    
    public init (fields: NSDictionary?){
        super.init()
        
        self.id = fields?.value(forKey: "_id") as? String
        self.userId = fields?.value(forKey: "userId") as? String
        self.name = fields?.value(forKey: "name") as? String
        
        if let coords = fields?.value(forKey: "coords") as? NSDictionary{
            self.lat = coords.value(forKey: "lat") as? Double
            self.lng = coords.value(forKey: "lng") as? Double
        }
        
        if let placeType = fields?.value(forKey: "placeType") as? String{
            self.placeType = PlaceType(rawValue: placeType)
        }
        self.isPublic = fields?.value(forKey: "public") as? Bool
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init()
        self.id = aDecoder.decodeObject(forKey: PropertyKeys.id) as? String
        self.userId = aDecoder.decodeObject(forKey: PropertyKeys.userId) as? String
        self.name = aDecoder.decodeObject(forKey: PropertyKeys.name) as? String
        if aDecoder.containsValue(forKey: PropertyKeys.lat){
            self.lat = aDecoder.decodeDouble(forKey: PropertyKeys.lat)
        }
        if aDecoder.containsValue(forKey: PropertyKeys.lng){
            self.lng = aDecoder.decodeDouble(forKey: PropertyKeys.lng)
        }
        if let placeType = aDecoder.decodeObject(forKey: PropertyKeys.placeType) as? String{
            self.placeType = PlaceType(rawValue: placeType)
        }
        if aDecoder.containsValue(forKey: PropertyKeys.isPublic){
            self.isPublic = aDecoder.decodeBool(forKey: PropertyKeys.isPublic)
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKeys.id)
        aCoder.encode(self.userId, forKey: PropertyKeys.userId)
        aCoder.encode(self.name, forKey: PropertyKeys.name)
        if let lat = self.lat{
            aCoder.encode(lat, forKey: PropertyKeys.lat)
        }
        if let lng = self.lng {
            aCoder.encode(lng, forKey: PropertyKeys.lng)
        }
        aCoder.encode(self.placeType?.rawValue, forKey: PropertyKeys.placeType)
        if let isPublic = self.isPublic {
            aCoder.encode(isPublic, forKey: PropertyKeys.isPublic)
        }
    }
    
    open func toDictionary() ->Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        dict[PropertyKeys.id] = self.id as AnyObject?
        dict[PropertyKeys.userId] = self.userId as AnyObject?
        dict[PropertyKeys.name] = self.name as AnyObject?
        
        var coords = Dictionary<String, AnyObject>()
        coords[PropertyKeys.lat] = self.lat as AnyObject?
        coords[PropertyKeys.lng] = self.lng as AnyObject?
        dict[PropertyKeys.coords] = coords as AnyObject?
        
        if let placeType = self.placeType {
            dict[PropertyKeys.placeType] = placeType.rawValue as AnyObject?
        }
        dict[PropertyKeys.isPublic] = self.isPublic as AnyObject?
        
        return dict
    }
    
    public enum PlaceType: String{
        case Static = "static"
        case Dynamic = "dynamic"
    }
    
    fileprivate struct PropertyKeys {
        static let id = "_id"
        static let userId = "userId"
        static let name = "name"
        static let lat = "lat"
        static let lng = "lng"
        static let placeType = "placeType"
        static let isPublic = "isPublic"
        static let coords = "coords"
    }
}
