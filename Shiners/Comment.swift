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
    var timestamp: Date?
    var username: String?
    var entityId: String?
    var likes: Int?
    var liked: Bool?
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
    
    func update(_ fields: NSDictionary?){
        self.id = fields?.value(forKey: PropertyKeys.id) as? String
        self.text = fields?.value(forKey: PropertyKeys.text) as? String
        self.userId = fields?.value(forKey: PropertyKeys.userId) as? String
        self.username = fields?.value(forKey: PropertyKeys.username) as? String
        self.entityId = fields?.value(forKey: PropertyKeys.entityId) as? String
        self.likes = fields?.value(forKey: PropertyKeys.likes) as? Int
        self.liked = fields?.value(forKey: PropertyKeys.liked) as? Bool
        
        if let timestamp = fields?.value(forKey: PropertyKeys.timestamp) as? Double {
            self.timestamp = Date(timeIntervalSince1970: timestamp / 1000)
        }
        
        if let userFields = fields?.value(forKey: "user") as? NSDictionary {
            self.user = User(fields: userFields)
            if let user = self.user {
                self.username = user.username
            }
        }
    }
    
    required init(coder aDecoder: NSCoder){
        super.init()
        
        self.id = aDecoder.decodeObject(forKey: PropertyKeys.id) as? String
        self.text = aDecoder.decodeObject(forKey: PropertyKeys.text) as? String
        self.userId = aDecoder.decodeObject(forKey: PropertyKeys.userId) as? String
        self.timestamp = aDecoder.decodeObject(forKey: PropertyKeys.timestamp) as? Date
        self.username = aDecoder.decodeObject(forKey: PropertyKeys.username) as? String
        self.entityId = aDecoder.decodeObject(forKey: PropertyKeys.entityId) as? String
        self.user = aDecoder.decodeObject(forKey: PropertyKeys.user) as? User
        if aDecoder.containsValue(forKey: PropertyKeys.likes){
            self.likes = aDecoder.decodeObject(forKey: PropertyKeys.likes) as? Int
        }
        if aDecoder.containsValue(forKey: PropertyKeys.liked) {
            self.liked = aDecoder.decodeBool(forKey: PropertyKeys.liked)
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKeys.id)
        aCoder.encode(self.text, forKey: PropertyKeys.text)
        aCoder.encode(self.userId, forKey: PropertyKeys.userId)
        aCoder.encode(self.timestamp, forKey: PropertyKeys.timestamp)
        aCoder.encode(self.username, forKey: PropertyKeys.username)
        aCoder.encode(self.entityId, forKey: PropertyKeys.entityId)
        aCoder.encode(self.user, forKey: PropertyKeys.user)
        aCoder.encode(self.likes, forKey: PropertyKeys.likes)
        if let liked = self.liked {
            aCoder.encode(liked, forKey: PropertyKeys.liked)
        }
    }
    
    fileprivate struct PropertyKeys{
        static let id = "_id"
        static let text = "text"
        static let userId = "userId"
        static let timestamp = "dateTime"
        static let username = "username"
        static let entityId = "entityId"
        static let user = "user"
        static let likes = "likes"
        static let liked = "liked"
    }
    
    func toDictionary() -> Dictionary<String, AnyObject> {
        var dict = Dictionary<String, AnyObject>()
        dict["comment"] = self.text as AnyObject?
        dict["postId"] = self.entityId as AnyObject?
        
        return dict
    }
}
