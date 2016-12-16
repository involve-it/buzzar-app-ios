//
//  ProfileDetail.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

open class ProfileDetail: NSObject, NSCoding {
    open var id: String?
    open var userId: String?
    open var key: String?
    open var value: String?
    open var policy: String?
    
    public init (key: String, value: String?){
        self.key = key
        self.value = value
    }
    
    public init (fields: NSDictionary){
        self.id = fields.value(forKey: "_id") as? String
        self.userId = fields.value(forKey: "userId") as? String
        self.key = fields.value(forKey: "key") as? String
        self.value = fields.value(forKey: "value") as? String
        self.policy = fields.value(forKey: "policy") as? String
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
    
    open func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        
        dict["key"] = self.key as AnyObject?
        dict["value"] = self.value as AnyObject?
        dict["policy"] = self.policy as AnyObject?
        
        return dict;
    }
    
    public required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: PropertyKeys.id) as? String
        self.userId = aDecoder.decodeObject(forKey: PropertyKeys.userId) as? String
        self.key = aDecoder.decodeObject(forKey: PropertyKeys.key) as? String
        self.value = aDecoder.decodeObject(forKey: PropertyKeys.value) as? String
        self.policy = aDecoder.decodeObject(forKey: PropertyKeys.policy) as? String
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKeys.id)
        aCoder.encode(self.userId, forKey: PropertyKeys.userId)
        aCoder.encode(self.key, forKey: PropertyKeys.key)
        aCoder.encode(self.value, forKey: PropertyKeys.value)
        aCoder.encode(self.policy, forKey: PropertyKeys.policy)
    }
    
    fileprivate struct PropertyKeys{
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
