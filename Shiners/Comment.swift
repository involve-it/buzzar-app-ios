//
//  Comment.swift
//  Shiners
//
//  Created by Yury Dorofeev on 11/27/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class Comment: NSObject, DictionaryInitializable, NSCoding {
    var id: String?
    var text: String?
    var userId: String?
    var timestamp: NSDate?
    var username: String?
    var entityId: String?
    var user: User?
    
    override init() {
        super.init()
    }
    
    init(id: String, fields: NSDictionary?){
        super.init()
        
        self.update(fields)
        self.id = id
    }
    
    required init (fields: NSDictionary?){
        super.init()
        self.update(fields)
    }
    
    func update(fields: NSDictionary?){
        self.id = fields?.valueForKey(PropertyKeys.id) as? String
        self.text = fields?.valueForKey(PropertyKeys.text) as? String
        self.userId = fields?.valueForKey(PropertyKeys.userId) as? String
        self.username = fields?.valueForKey(PropertyKeys.username) as? String
        self.entityId = fields?.valueForKey(PropertyKeys.entityId) as? String
        
        if let timestamp = fields?.valueForKey(PropertyKeys.timestamp) as? Double {
            self.timestamp = NSDate(timeIntervalSince1970: timestamp / 1000)
        }
        
        if let userFields = fields?.valueForKey("user") as? NSDictionary {
            self.user = User(fields: userFields)
            if let user = self.user {
                self.username = user.username
            }
        }
    }
    
    required init(coder aDecoder: NSCoder){
        super.init()
        
        self.id = aDecoder.decodeObjectForKey(PropertyKeys.id) as? String
        self.text = aDecoder.decodeObjectForKey(PropertyKeys.text) as? String
        self.userId = aDecoder.decodeObjectForKey(PropertyKeys.userId) as? String
        self.timestamp = aDecoder.decodeObjectForKey(PropertyKeys.timestamp) as? NSDate
        self.username = aDecoder.decodeObjectForKey(PropertyKeys.username) as? String
        self.entityId = aDecoder.decodeObjectForKey(PropertyKeys.entityId) as? String
        self.user = aDecoder.decodeObjectForKey(PropertyKeys.user) as? User
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.id, forKey: PropertyKeys.id)
        aCoder.encodeObject(self.text, forKey: PropertyKeys.text)
        aCoder.encodeObject(self.userId, forKey: PropertyKeys.userId)
        aCoder.encodeObject(self.timestamp, forKey: PropertyKeys.timestamp)
        aCoder.encodeObject(self.username, forKey: PropertyKeys.username)
        aCoder.encodeObject(self.entityId, forKey: PropertyKeys.entityId)
        aCoder.encodeObject(self.user, forKey: PropertyKeys.user)
    }
    
    private struct PropertyKeys{
        static let id = "_id"
        static let text = "text"
        static let userId = "userId"
        static let timestamp = "dateTime"
        static let username = "username"
        static let entityId = "entityId"
        static let user = "user"
    }
    
    func toDictionary() -> Dictionary<String, AnyObject> {
        var dict = Dictionary<String, AnyObject>()
        dict["comment"] = self.text
        dict["postId"] = self.entityId
        
        return dict
    }
}