//
//  User.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class User{
    public var id: String?;
    public var createdAt: NSDate?;
    public var username: String?;
    public var email: String?;
    public var imageUrl: String?;
    
    init(id: String, fields: NSDictionary?){
        self.id = id;
        
        self.update(fields);
    }
    
    public func update(fields: NSDictionary?){
        if let createdAt = fields?.valueForKey("createdAt") as? NSDate{
            self.createdAt = createdAt;
        }
        if let username = fields?.valueForKey("username") as? String{
            self.username = username;
        }
        if let emails = fields?.valueForKey("emails") as? NSArray{
            if emails.count > 0{
                self.email = emails[0] as? String;
            }
        }
        if let profile = fields?.valueForKey("profile") as? NSDictionary?,
            let image = profile?.valueForKey("image") as? NSDictionary?,
            let data = image?.valueForKey("data") as? String{
            self.imageUrl = data;
        }
    }
}