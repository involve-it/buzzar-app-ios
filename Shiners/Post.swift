//
//  Post.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
public class Post: DictionaryInitializable{
    public var id: String?;
    public var title: String?;
    public var imageIds: [String]?;
    public var description: String?;
    public var price: String?;
    public var seenTotal: String?;
    public var seenToday: String?;
    
    init(id: String, fields: NSDictionary?){
        self.id = id;
        
        self.update(fields);
    }
    
    public required init(fields: NSDictionary?){
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
                self.description = description;
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
}