//
//  User.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class User: NSObject, DictionaryInitializable, NSCoding{
    public var id: String?
    public var createdAt: NSDate?
    public var username: String?
    public var email: String?
    public var imageUrl: String?
    public var online: Bool?
    public var locations: [Location]?
    public var profileDetails: [ProfileDetail]?
    public var language: String?
    public var enableNearbyNotifications: Bool?
    
    override init(){
        super.init()
    }
    
    init(id: String, fields: NSDictionary?){
        self.id = id
        
        super.init()
        
        self.update(fields);
    }
    
    required public init(fields: NSDictionary?){
        super.init()
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
        
        if let statusFields = fields?.valueForKey("status") as? NSDictionary{
            self.online = statusFields.valueForKey("online") as? Bool
        }
        if let images = fields?.valueForKey("image") as? NSArray{
            for image in images{
                self.imageUrl = image.valueForKey("imageUrl") as? String
                break
            }
        } else if let image = fields?.valueForKey("image") as? NSDictionary {
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
        self.enableNearbyNotifications = fields?.valueForKey(PropertyKeys.enableNearbyNotifications) as? Bool
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
        dict[PropertyKeys.enableNearbyNotifications] = self.enableNearbyNotifications
        
        return dict
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init()
        
        self.id = aDecoder.decodeObjectForKey(PropertyKeys.id) as? String
        self.createdAt = aDecoder.decodeObjectForKey(PropertyKeys.createdAt) as? NSDate
        self.username = aDecoder.decodeObjectForKey(PropertyKeys.username) as? String
        self.email = aDecoder.decodeObjectForKey(PropertyKeys.email) as? String
        self.imageUrl = aDecoder.decodeObjectForKey(PropertyKeys.imageUrl) as? String
        if aDecoder.containsValueForKey(PropertyKeys.online){
            self.online = aDecoder.decodeBoolForKey(PropertyKeys.online)
        }
        if aDecoder.containsValueForKey(PropertyKeys.enableNearbyNotifications){
            self.enableNearbyNotifications = aDecoder.decodeBoolForKey(PropertyKeys.enableNearbyNotifications)
        }
        self.locations = aDecoder.decodeObjectForKey(PropertyKeys.locations) as? [Location]
        self.profileDetails = aDecoder.decodeObjectForKey(PropertyKeys.profileDetails) as? [ProfileDetail]
        self.language = aDecoder.decodeObjectForKey(PropertyKeys.language) as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.id, forKey: PropertyKeys.id)
        aCoder.encodeObject(self.createdAt, forKey: PropertyKeys.createdAt)
        aCoder.encodeObject(self.username, forKey: PropertyKeys.username)
        aCoder.encodeObject(self.email, forKey: PropertyKeys.email)
        aCoder.encodeObject(self.imageUrl, forKey: PropertyKeys.imageUrl)
        if let online = self.online{
            aCoder.encodeBool(online, forKey: PropertyKeys.online)
        }
        aCoder.encodeObject(self.locations, forKey: PropertyKeys.locations)
        aCoder.encodeObject(self.profileDetails, forKey: PropertyKeys.profileDetails)
        aCoder.encodeObject(self.language, forKey: PropertyKeys.language)
        if let enableNearbyNotifications = self.enableNearbyNotifications{
            aCoder.encodeBool(enableNearbyNotifications, forKey: PropertyKeys.enableNearbyNotifications)
        }
    }
    
    private struct PropertyKeys{
        static let id = "_id"
        static let createdAt = "createdAt"
        static let username = "username"
        static let email = "email"
        static let imageUrl = "imageUrl"
        static let online = "online"
        static let locations = "locations"
        static let profileDetails = "profileDetails"
        static let language = "language"
        static let enableNearbyNotifications = "enableNearbyNotifications"
    }
}