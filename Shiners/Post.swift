//
//  Post.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
public class Post: NSObject, DictionaryInitializable, NSCoding{
    public var id: String?;
    public var title: String?;
    public var imageIds: [String]?;
    public var descr: String?;
    public var price: String?;
    public var seenTotal: String?;
    public var seenToday: String?;
    
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
        if let id = fields?.valueForKey("_id") as? String{
            self.id = id
        }
        
        if let details = fields?.valueForKey("details") as? NSDictionary {
            if let title = details.valueForKey("title") as? String{
                self.title = title;
            }
            if let description = details.valueForKey("description") as? String{
                self.descr = description;
            }
            if let photos = details.valueForKey("photos") as? NSArray{
                self.imageIds = photos as? [String];
            }
            if let price = details.valueForKey("price") as? String {
                //self.price = String(format: "$%.2f", price);
                self.price = price;
            }
        }
        
        if let stats = fields?.valueForKey("stats") as? NSDictionary{
            if let seenTotal = stats.valueForKey("seenAll") as? String{
                self.seenTotal = seenTotal;
            } else {
                self.seenTotal = "0"
            }
            if let seenToday = stats.valueForKey("seenToday") as? String{
                self.seenToday = seenToday;
            } else {
                self.seenToday = "0"
            }
        }
    }
    
    @objc public required init(coder aDecoder: NSCoder) {
        
        self.id = aDecoder.decodeObjectForKey(PropertyKey.id) as? String
        self.title = aDecoder.decodeObjectForKey(PropertyKey.title) as? String
        self.descr = aDecoder.decodeObjectForKey(PropertyKey.description) as? String
        self.price = aDecoder.decodeObjectForKey(PropertyKey.price) as? String
        self.seenTotal = aDecoder.decodeObjectForKey(PropertyKey.seenTotal) as? String
        self.seenToday = aDecoder.decodeObjectForKey(PropertyKey.seenToday) as? String
        
        super.init()
        //self.imageIds = aDecoder.decodeObjectForKey(PropertyKey.imageIds) as? [String]
    }
    
    @objc public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey: PropertyKey.id)
        aCoder.encodeObject(title, forKey: PropertyKey.title)
        /*if imageIds != nil{
            aCoder.encodeObject(imageIds! as NSArray, forKey: PropertyKey.imageIds)
        }*/
        aCoder.encodeObject(descr, forKey: PropertyKey.description)
        aCoder.encodeObject(price, forKey: PropertyKey.price)
        aCoder.encodeObject(seenTotal, forKey: PropertyKey.seenTotal)
        aCoder.encodeObject(seenToday, forKey: PropertyKey.seenToday)
    }
    
    private struct PropertyKey{
        static let id = "id"
        static let title = "title"
        static let imageIds = "imageIds"
        static let description = "description"
        static let price = "price"
        static let seenTotal = "seenTotal"
        static let seenToday = "seenToday"
    }
}