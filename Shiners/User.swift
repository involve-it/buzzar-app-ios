//
//  User.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class User: DictionaryInitializable{
    public var id: String?
    public var createdAt: NSDate?
    public var username: String?
    public var email: String?
    public var imageUrl: String?
    public var online: Bool?
    public var locations: [Location]?
    public var profileDetails: [ProfileDetail]?
    public var language: String?
    
    init(){}
    
    init(id: String, fields: NSDictionary?){
        self.id = id;
        
        self.update(fields);
    }
    
    required public init(fields: NSDictionary?){
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
        if let image = fields?.valueForKey("image") as? NSDictionary{
            self.imageUrl = image.valueForKey("imageUrl") as? String
        }
        
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
    
    public func getProfileDetailValue(key: ProfileDetail.Key) -> String? {
        return self.getProfileDetail(key)?.value;
    }
    
    public func getProfileDetail(key: ProfileDetail.Key) -> ProfileDetail?{
        var value: ProfileDetail?;
        if let profileDetails = self.profileDetails{
            for profileDetail in profileDetails {
                if (profileDetail.key == key.rawValue){
                    value = profileDetail;
                    break;
                }
            }
        }
        return value;
    }
    
    public func setProfileDetail(key: ProfileDetail.Key, value: String?) -> Void{
        if self.profileDetails == nil{
            self.profileDetails = [ProfileDetail]()
        }
        if let profileDetail = self.getProfileDetail(key){
            profileDetail.value = value
        } else {
            let profileDetail = ProfileDetail(key: key.rawValue, value: value)
            self.profileDetails?.append(profileDetail)
        }
    }
    
    public func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        
        dict["email"] = self.email
        dict["imageUrl"] = self.imageUrl
        if let profileDetails = self.profileDetails{
            var profileDetailsDict = Array<Dictionary<String, AnyObject>>()
            for profileDetail in profileDetails{
                profileDetailsDict.append(profileDetail.toDictionary())
            }
            dict["profileDetails"] = profileDetailsDict
        }
        
        return dict
    }
}