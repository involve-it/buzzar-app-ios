//
//  PostDetails.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class PostDetails: NSObject, NSCoding{
    open var id: String?
    open var anonymousPost: Bool?
    open var locations: [Location]?
    open var url: String?
    open var title: String?
    open var descr: String?
    open var price: String?
    open var photos: [Photo]?
    
    public required init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: PropertyKey.id) as? String
        if aDecoder.containsValue(forKey: PropertyKey.anonymousPost){
            self.anonymousPost = aDecoder.decodeObject(forKey: PropertyKey.anonymousPost) as? Bool
        }
        self.locations = aDecoder.decodeObject(forKey: PropertyKey.locations) as? [Location]
        self.photos = aDecoder.decodeObject(forKey: PropertyKey.photos) as? [Photo]
        self.url = aDecoder.decodeObject(forKey: PropertyKey.url) as? String
        self.title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String
        self.descr = aDecoder.decodeObject(forKey: PropertyKey.description) as? String
        self.price = aDecoder.decodeObject(forKey: PropertyKey.price) as? String
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: PropertyKey.id)
        if let anonymousPost = self.anonymousPost {
            aCoder.encode(anonymousPost, forKey: PropertyKey.anonymousPost)
        }
        aCoder.encode(locations, forKey: PropertyKey.locations)
        aCoder.encode(url, forKey: PropertyKey.url)
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(photos, forKey: PropertyKey.photos)
        aCoder.encode(descr, forKey: PropertyKey.description)
        aCoder.encode(price, forKey: PropertyKey.price)
        
    }
    
    fileprivate struct PropertyKey{
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
