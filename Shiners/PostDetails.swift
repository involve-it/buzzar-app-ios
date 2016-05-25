//
//  PostDetails.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class PostDetails: NSObject, NSCoding{
    public var id: String?
    public var anonymousPost: Bool?
    public var locations: [Location]?
    public var url: String?
    public var title: String?
    public var descr: String?
    public var price: String?
    public var photos: [Photo]?
    
    public required init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObjectForKey(PropertyKey.id) as? String
        if aDecoder.containsValueForKey(PropertyKey.anonymousPost){
            self.anonymousPost = aDecoder.decodeObjectForKey(PropertyKey.anonymousPost) as? Bool
        }
        self.locations = aDecoder.decodeObjectForKey(PropertyKey.locations) as? [Location]
        self.photos = aDecoder.decodeObjectForKey(PropertyKey.photos) as? [Photo]
        self.url = aDecoder.decodeObjectForKey(PropertyKey.url) as? String
        self.title = aDecoder.decodeObjectForKey(PropertyKey.title) as? String
        self.descr = aDecoder.decodeObjectForKey(PropertyKey.description) as? String
        self.price = aDecoder.decodeObjectForKey(PropertyKey.price) as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey: PropertyKey.id)
        if let anonymousPost = self.anonymousPost {
            aCoder.encodeBool(anonymousPost, forKey: PropertyKey.anonymousPost)
        }
        aCoder.encodeObject(locations, forKey: PropertyKey.locations)
        aCoder.encodeObject(url, forKey: PropertyKey.url)
        aCoder.encodeObject(title, forKey: PropertyKey.title)
        aCoder.encodeObject(photos, forKey: PropertyKey.photos)
        aCoder.encodeObject(descr, forKey: PropertyKey.description)
        aCoder.encodeObject(price, forKey: PropertyKey.price)
        
    }
    
    private struct PropertyKey{
        static let id = "_id"
        static let anonymousPost = "anonymousPost"
        static let locations = "locations"
        static let url = "url"
        static let title = "title"
        static let description = "description"
        static let price = "price"
        static let photos = "photos"
    }
}