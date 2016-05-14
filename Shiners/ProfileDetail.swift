//
//  ProfileDetail.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP



public class ProfileDetail{
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
}

extension ProfileDetail.Key: Equatable{}

public func == (l: ProfileDetail.Key, r: ProfileDetail.Key) -> Bool{
    return l.rawValue == r.rawValue;
}
