//
//  User.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class User: NSObject, DictionaryInitializable, NSCoding{
    open var id: String?
    open var createdAt: Date?
    open var username: String?
    open var email: String?
    open var imageUrl: String?
    open var online: Bool?
    open var locations: [Location]?
    open var profileDetails: [ProfileDetail]?
    open var language: String?
    open var enableNearbyNotifications: Bool?
    open var lastMobileLocationReport: Date?
    open var lastLogin: Date?
    
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
    
    open func update(_ fields: NSDictionary?){
        self.id = fields?.value(forKey: "_id") as? String
        self.createdAt = (fields?.value(forKey: "createdAt") as? NSDictionary)?.javaScriptDateFromFirstElement() as Date?
        self.username = fields?.value(forKey: "username") as? String
        
        if let emails = fields?.value(forKey: "emails") as? NSArray{
            if emails.count > 0{
                if let emailFields = emails[0] as? NSDictionary{
                    self.email = emailFields.value(forKey: "address") as? String
                }
            }
        }
        
        self.online = fields?.value(forKey: "online") as? Bool
        self.lastLogin = (fields?.value(forKey: PropertyKeys.lastLogin) as? NSDictionary)?.javaScriptDateFromFirstElement() as Date?
        self.lastMobileLocationReport = (fields?.value(forKey: PropertyKeys.lastMobileLocationReport) as? NSDictionary)?.javaScriptDateFromFirstElement() as Date?
        
        if let images = fields?.value(forKey: "image") as? NSArray{
            for image in images{
                self.imageUrl = (image as AnyObject).value(forKey: "imageUrl") as? String
                break
            }
        } else if let image = fields?.value(forKey: "image") as? NSDictionary {
            self.imageUrl = image.value(forKey: "imageUrl") as? String
        }
        
        if let locations = fields?.value(forKey: "locations") as? NSArray {
            self.locations = [Location]()
            
            for location in locations {
                if let fields = location as? NSDictionary{
                    self.locations?.append(Location(fields: fields))
                }
            }
        }
        
        if let profileDetails = fields?.value(forKey: "profileDetails") as? NSArray{
            self.profileDetails = [ProfileDetail]()
            for profileDetail in profileDetails {
                if let fields = profileDetail as? NSDictionary{
                    self.profileDetails?.append(ProfileDetail(fields: fields))
                }
            }
        }
        self.language = fields?.value(forKey: "language") as? String
        self.enableNearbyNotifications = fields?.value(forKey: PropertyKeys.enableNearbyNotifications) as? Bool
    }
    
    open func isOnline() -> Bool{
        if let online = self.online{
            if let lastMobileLocationReport = self.lastMobileLocationReport{
                return online || Date().timeIntervalSince(lastMobileLocationReport) <= 20 * 60
            } else {
                return online
            }
        }
        return false
    }
    
    open func getProfileDetailValue(_ key: ProfileDetail.Key) -> String? {
        return self.getProfileDetail(key)?.value;
    }
    
    open func getFullName() -> String? {
        if let firstName = self.getProfileDetailValue(.FirstName), let lastName = self.getProfileDetailValue(.LastName){
            return (firstName + " " + lastName).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    
    open func getProfileDetail(_ key: ProfileDetail.Key) -> ProfileDetail?{
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
    
    open func setProfileDetail(_ key: ProfileDetail.Key, value: String?) -> Void{
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
    
    open func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        
        dict["email"] = self.email as AnyObject?
        dict["imageUrl"] = self.imageUrl as AnyObject?
        if let profileDetails = self.profileDetails{
            var profileDetailsDict = Array<Dictionary<String, AnyObject>>()
            for profileDetail in profileDetails{
                profileDetailsDict.append(profileDetail.toDictionary())
            }
            dict["profileDetails"] = profileDetailsDict as AnyObject?
        }
        dict[PropertyKeys.enableNearbyNotifications] = self.enableNearbyNotifications as AnyObject?
        
        return dict
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init()
        
        self.id = aDecoder.decodeObject(forKey: PropertyKeys.id) as? String
        self.createdAt = aDecoder.decodeObject(forKey: PropertyKeys.createdAt) as? Date
        self.username = aDecoder.decodeObject(forKey: PropertyKeys.username) as? String
        self.email = aDecoder.decodeObject(forKey: PropertyKeys.email) as? String
        self.imageUrl = aDecoder.decodeObject(forKey: PropertyKeys.imageUrl) as? String
        if aDecoder.containsValue(forKey: PropertyKeys.online){
            self.online = aDecoder.decodeBool(forKey: PropertyKeys.online)
        }
        if aDecoder.containsValue(forKey: PropertyKeys.enableNearbyNotifications){
            self.enableNearbyNotifications = aDecoder.decodeBool(forKey: PropertyKeys.enableNearbyNotifications)
        }
        self.locations = aDecoder.decodeObject(forKey: PropertyKeys.locations) as? [Location]
        self.profileDetails = aDecoder.decodeObject(forKey: PropertyKeys.profileDetails) as? [ProfileDetail]
        self.language = aDecoder.decodeObject(forKey: PropertyKeys.language) as? String
        self.lastMobileLocationReport = aDecoder.decodeObject(forKey: PropertyKeys.lastMobileLocationReport) as? Date
        self.lastLogin = aDecoder.decodeObject(forKey: PropertyKeys.lastLogin) as? Date
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKeys.id)
        aCoder.encode(self.createdAt, forKey: PropertyKeys.createdAt)
        aCoder.encode(self.username, forKey: PropertyKeys.username)
        aCoder.encode(self.email, forKey: PropertyKeys.email)
        aCoder.encode(self.imageUrl, forKey: PropertyKeys.imageUrl)
        if let online = self.online{
            aCoder.encode(online, forKey: PropertyKeys.online)
        }
        aCoder.encode(self.locations, forKey: PropertyKeys.locations)
        aCoder.encode(self.profileDetails, forKey: PropertyKeys.profileDetails)
        aCoder.encode(self.language, forKey: PropertyKeys.language)
        if let enableNearbyNotifications = self.enableNearbyNotifications{
            aCoder.encode(enableNearbyNotifications, forKey: PropertyKeys.enableNearbyNotifications)
        }
        aCoder.encode(self.lastMobileLocationReport, forKey: PropertyKeys.lastMobileLocationReport)
        aCoder.encode(self.lastLogin, forKey: PropertyKeys.lastLogin)
    }
    
    fileprivate struct PropertyKeys{
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
        static let lastMobileLocationReport = "lastMobileLocationReport"
        static let lastLogin = "lastLogin"
    }
}
