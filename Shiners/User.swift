//
//  User.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class User{
    public var id: String?
    public var createdAt: NSDate?
    public var username: String?
    public var email: String?
    public var imageUrl: String?
    public var online: Bool?
    public var locations: [Location]?
    public var profileDetails: [ProfileDetail]?
    public var language: String?
    
    init(id: String, fields: NSDictionary?){
        self.id = id;
        
        self.update(fields);
    }
    
    init(fields: NSDictionary?){
        self.update(fields)
    }
    
    public func update(fields: NSDictionary?){
        self.id = fields?.valueForKey("_id") as? String
        self.createdAt = fields?.valueForKey("createdAt") as? NSDate
        self.username = fields?.valueForKey("username") as? String
        
        if let emails = fields?.valueForKey("emails") as? NSArray{
            if emails.count > 0{
                self.email = emails[0] as? String;
            }
        }
        
        self.online = fields?.valueForKey("online") as? Bool
        self.imageUrl = fields?.valueForKey("imageUrl") as? String
        
        if let locations = fields?.valueForKey("locations") as? NSArray {
            self.locations = [Location]()
            
            for location in locations {
                if let fields = location as? NSDictionary{
                    self.locations?.append(Location(fields: fields))
                }
            }
        }
        
        if let profileDetails = fields?.valueForKey("profileDetails") as? NSArray{
            self.profileDetails = [ProfileDetail]()
            for profileDetail in profileDetails {
                if let fields = profileDetail as? NSDictionary{
                    self.profileDetails?.append(ProfileDetail(fields: fields))
                }
            }
        }
        self.language = fields?.valueForKey("language") as? String
    }
    
    public func getProfileDetail(key: ProfileDetail.Key) -> String? {
        var value: String?;
        if let profileDetails = self.profileDetails{
            for profileDetail in profileDetails {
                if (ProfileDetail.Key(rawValue: profileDetail.key!) == key){
                    value = profileDetail.value;
                    break;
                }
            }
        }
        return value;
    }
}