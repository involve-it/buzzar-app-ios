//
//  Post.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
public class Post: NSObject, DictionaryInitializable, NSCoding{
    public var id: String?
    public var title: String?
    public var photos: [Photo]?
    public var descr: String?
    public var price: String?
    public var seenTotal: String?
    public var seenToday: String?
    public var type: String?
    public var locations: [Location]?
    public var url: String?
    public var anonymousPost: Bool?
    public var endDate: NSDate?
    
    public override init(){
        super.init()
    }
    
    init(id: String, fields: NSDictionary?){
        super.init()
        self.id = id;
        
        self.update(fields);
    }
    
    public required init(fields: NSDictionary?){
        super.init()
        self.update(fields);
    }
    
    public func update(fields: NSDictionary?){
        if let id = fields?.valueForKey(PropertyKey.id) as? String {
            self.id = id
        }
        
        self.type = fields?.valueForKey(PropertyKey.type) as? String
        
        if let details = fields?.valueForKey("details") as? NSDictionary {
            self.title = details.valueForKey(PropertyKey.title) as? String
            
            self.descr = details.valueForKey(PropertyKey.description) as? String
            self.anonymousPost = details.valueForKey(PropertyKey.anonymousPost) as? Bool
            self.url = details.valueForKey(PropertyKey.url) as? String
            
            if let photos = details.valueForKey("photos") as? NSArray{
                self.photos = [Photo]()
                for photo in photos {
                    if let photoFields = photo as? NSDictionary{
                        self.photos?.append(Photo(fields: photoFields))
                    }
                }
            }
            
            if let locations = details.valueForKey(PropertyKey.locations) as? NSArray {
                self.locations = [Location]()
                for location in locations {
                    if let locationFields = location as? NSDictionary{
                        self.locations?.append(Location(fields: locationFields))
                    }
                }
            }
            
            self.price = details.valueForKey(PropertyKey.price) as? String
        }
        
        if let stats = fields?.valueForKey("stats") as? NSDictionary{
            if let seenTotal = stats.valueForKey(PropertyKey.seenTotal)as? String{
                self.seenTotal = seenTotal;
            } else {
                self.seenTotal = "0"
            }
            if let seenToday = stats.valueForKey(PropertyKey.seenToday) as? String{
                self.seenToday = seenToday;
            } else {
                self.seenToday = "0"
            }
        }
    }
    
    public func getMainPhoto() -> Photo? {
        if self.photos?.count > 0 {
            return self.photos?[0]
        }
        
        return nil
    }
    
    @objc public required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObjectForKey(PropertyKey.id) as? String
        self.title = aDecoder.decodeObjectForKey(PropertyKey.title) as? String
        self.descr = aDecoder.decodeObjectForKey(PropertyKey.description) as? String
        self.price = aDecoder.decodeObjectForKey(PropertyKey.price) as? String
        self.seenTotal = aDecoder.decodeObjectForKey(PropertyKey.seenTotal) as? String
        self.seenToday = aDecoder.decodeObjectForKey(PropertyKey.seenToday) as? String
        self.photos = aDecoder.decodeObjectForKey(PropertyKey.photos) as? [Photo]
        self.type = aDecoder.decodeObjectForKey(PropertyKey.type) as? String
        self.locations = aDecoder.decodeObjectForKey(PropertyKey.locations) as? [Location]
        self.url = aDecoder.decodeObjectForKey(PropertyKey.url) as? String
        if aDecoder.containsValueForKey(PropertyKey.anonymousPost){
            self.anonymousPost = aDecoder.decodeBoolForKey(PropertyKey.anonymousPost)
        }
        self.endDate = aDecoder.decodeObjectForKey(PropertyKey.endDate) as? NSDate
        
        super.init()
    }
    
    @objc public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey: PropertyKey.id)
        aCoder.encodeObject(title, forKey: PropertyKey.title)
        aCoder.encodeObject(photos, forKey: PropertyKey.photos)
        aCoder.encodeObject(descr, forKey: PropertyKey.description)
        aCoder.encodeObject(price, forKey: PropertyKey.price)
        aCoder.encodeObject(seenTotal, forKey: PropertyKey.seenTotal)
        aCoder.encodeObject(seenToday, forKey: PropertyKey.seenToday)
        aCoder.encodeObject(type, forKey: PropertyKey.type)
        aCoder.encodeObject(locations, forKey: PropertyKey.locations)
        aCoder.encodeObject(url, forKey: PropertyKey.url)
        aCoder.encodeObject(anonymousPost, forKey: PropertyKey.anonymousPost)
        aCoder.encodeObject(endDate, forKey: PropertyKey.endDate)
    }
    
    public func toDictionary() -> Dictionary<String, AnyObject?>{
        var dict = Dictionary<String, AnyObject?>()
        
        dict[PropertyKey.id] = self.id
        dict[PropertyKey.type] = self.type
        dict[PropertyKey.endDate] = self.endDate
        if let photos = self.photos {
            var photosArray = Array<Dictionary<String, AnyObject?>>()
            for photo in photos {
                
            }
        }
        return dict
    }
    
    private struct PropertyKey{
        static let id = "_id"
        static let title = "title"
        static let description = "description"
        static let price = "price"
        static let seenTotal = "seenAll"
        static let seenToday = "seenToday"
        static let photos = "photos"
        static let type = "type"
        static let locations = "location"
        static let url = "url"
        static let anonymousPost = "anonymousPost"
        static let endDate = "endDatePost"
    }
}