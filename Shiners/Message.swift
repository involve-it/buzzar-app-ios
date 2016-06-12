//
//  Message.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class Message: NSObject, DictionaryInitializable, NSCoding {
    var id: String?
    var userId: String?
    var toUserId: String?
    var chatId: String?
    var text: String?
    var timestamp: NSDate?
    var keyMessage: String?
    var seen: Bool?
    
    override init() {
        super.init()
    }
    
    convenience init(id: String, fields: NSDictionary?){
        self.init(fields: fields)
        self.id = id
    }
    
    required init(fields: NSDictionary?){
        super.init()
        self.update(fields)
    }
    
    func update(fields: NSDictionary?){
        self.id = fields?.objectForKey(PropertyKeys.id) as? String
        self.userId = fields?.objectForKey(PropertyKeys.userId) as? String
        self.toUserId = fields?.objectForKey(PropertyKeys.toUserId) as? String
        self.chatId = fields?.objectForKey(PropertyKeys.chatId) as? String
        self.text = fields?.objectForKey(PropertyKeys.text) as? String
        if let timestampMilliseconds = fields?.objectForKey(PropertyKeys.timestamp) as? Double {
            self.timestamp = NSDate(timeIntervalSince1970: timestampMilliseconds / 1000)
        }
        self.keyMessage = fields?.objectForKey(PropertyKeys.keyMessage) as? String
        self.seen = fields?.objectForKey(PropertyKeys.seen) as? Bool
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObjectForKey(PropertyKeys.id) as? String
        self.userId = aDecoder.decodeObjectForKey(PropertyKeys.userId) as? String
        self.toUserId = aDecoder.decodeObjectForKey(PropertyKeys.toUserId) as? String
        self.chatId = aDecoder.decodeObjectForKey(PropertyKeys.chatId) as? String
        self.text = aDecoder.decodeObjectForKey(PropertyKeys.text) as? String
        self.timestamp = aDecoder.decodeObjectForKey(PropertyKeys.timestamp) as? NSDate
        self.keyMessage = aDecoder.decodeObjectForKey(PropertyKeys.keyMessage) as? String
        if aDecoder.containsValueForKey(PropertyKeys.seen){
            self.seen = aDecoder.decodeBoolForKey(PropertyKeys.seen)
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.id, forKey: PropertyKeys.id)
        aCoder.encodeObject(self.userId, forKey: PropertyKeys.userId)
        aCoder.encodeObject(self.toUserId, forKey: PropertyKeys.toUserId)
        aCoder.encodeObject(self.chatId, forKey: PropertyKeys.chatId)
        aCoder.encodeObject(self.text, forKey: PropertyKeys.text)
        aCoder.encodeObject(self.timestamp, forKey: PropertyKeys.timestamp)
        aCoder.encodeObject(self.keyMessage, forKey: PropertyKeys.keyMessage)
        if let seen = self.seen{
            aCoder.encodeBool(seen, forKey: PropertyKeys.seen)
        }
    }
    
    private struct PropertyKeys {
        static let id = "_id"
        static let userId = "userId"
        static let toUserId = "toUserId"
        static let chatId = "chatId"
        static let text = "text"
        static let timestamp = "timestamp"
        static let keyMessage = "keyMessage"
        static let seen = "seen"
    }
    
    func isOwn(userId: String) -> Bool{
        if self.userId == userId {
            return true
        } else {
            return false
        }
    }
    
    func toDictionary() -> Dictionary<String, AnyObject>{
        return [:]
    }
}