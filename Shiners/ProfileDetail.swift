//
//  ProfileDetail.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class ProfileDetail: NSObject, NSCoding {
    public var id: String?
    public var userId: String?
    public var key: String?
    public var value: String?
    public var policy: String?
    
    public init (key: String, value: String?){
        self.key = key
        self.value = value
    }
    
    public init (fields: NSDictionary){
        self.id = fields.valueForKey("_id") as? String
        self.userId = fields.valueForKey("userId") as? String
        self.key = fields.valueForKey("key") as? String
        self.value = fields.valueForKey("value") as? String
        self.policy = fields.valueForKey("policy") as? String
    }
    
    public enum Key: String{
        case LastName = "lastName"
        case FirstName = "firstName"
        case City = "city"
        case Phone = "phone"
        case Skype = "skype"
        case Vk = "vk"
        case Twitter = "twitter"
        case Facebook = "facebook"
    }
    
    public func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        
        dict["key"] = self.key
        dict["value"] = self.value
        dict["policy"] = self.policy
        
        return dict;
    }
    
    public required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObjectForKey(PropertyKeys.id) as? String
        self.userId = aDecoder.decodeObjectForKey(PropertyKeys.userId) as? String
        self.key = aDecoder.decodeObjectForKey(PropertyKeys.key) as? String
        self.value = aDecoder.decodeObjectForKey(PropertyKeys.value) as? String
        self.policy = aDecoder.decodeObjectForKey(PropertyKeys.policy) as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.id, forKey: PropertyKeys.id)
        aCoder.encodeObject(self.userId, forKey: PropertyKeys.userId)
        aCoder.encodeObject(self.key, forKey: PropertyKeys.key)
        aCoder.encodeObject(self.value, forKey: PropertyKeys.value)
        aCoder.encodeObject(self.policy, forKey: PropertyKeys.policy)
    }
    
    private struct PropertyKeys{
        static let id = "id"
        static let userId = "userId"
        static let key = "key"
        static let value = "value"
        static let policy = "policy"
    }
}

extension ProfileDetail.Key: Equatable{}

public func == (l: ProfileDetail.Key, r: ProfileDetail.Key) -> Bool{
    return l.rawValue == r.rawValue;
}
