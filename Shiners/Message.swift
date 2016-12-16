//
//  Message.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation



open class Message: NSObject, DictionaryInitializable, NSCoding {
    var id: String?
    var userId: String?
    var toUserId: String?
    var chatId: String?
    var text: String?
    var timestamp: Date?
    var keyMessage: String?
    var seen: Bool?
    var associatedPostId: String?
    
    override init() {
        super.init()
    }
    
    open func shortMessage() -> String{
        if let text = self.text {
            return text.shortMessageForNotification()
        }
        return ""
    }
    
    convenience init(id: String, fields: NSDictionary?){
        self.init(fields: fields)
        self.id = id
    }
    
    required public init(fields: NSDictionary?){
        super.init()
        self.update(fields)
    }
    
    func update(_ fields: NSDictionary?){
        self.id = fields?.object(forKey: PropertyKeys.id) as? String
        self.userId = fields?.object(forKey: PropertyKeys.userId) as? String
        self.toUserId = fields?.object(forKey: PropertyKeys.toUserId) as? String
        self.chatId = fields?.object(forKey: PropertyKeys.chatId) as? String
        self.text = fields?.object(forKey: PropertyKeys.text) as? String
        if let timestampMilliseconds = fields?.object(forKey: PropertyKeys.timestamp) as? Double {
            self.timestamp = Date(timeIntervalSince1970: timestampMilliseconds / 1000)
        }
        self.keyMessage = fields?.object(forKey: PropertyKeys.keyMessage) as? String
        self.seen = fields?.object(forKey: PropertyKeys.seen) as? Bool
        self.associatedPostId = fields?.object(forKey: PropertyKeys.associatedPostId) as? String
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: PropertyKeys.id) as? String
        self.userId = aDecoder.decodeObject(forKey: PropertyKeys.userId) as? String
        self.toUserId = aDecoder.decodeObject(forKey: PropertyKeys.toUserId) as? String
        self.chatId = aDecoder.decodeObject(forKey: PropertyKeys.chatId) as? String
        self.text = aDecoder.decodeObject(forKey: PropertyKeys.text) as? String
        self.timestamp = aDecoder.decodeObject(forKey: PropertyKeys.timestamp) as? Date
        self.keyMessage = aDecoder.decodeObject(forKey: PropertyKeys.keyMessage) as? String
        if aDecoder.containsValue(forKey: PropertyKeys.seen){
            self.seen = aDecoder.decodeBool(forKey: PropertyKeys.seen)
        }
        self.associatedPostId = aDecoder.decodeObject(forKey: PropertyKeys.associatedPostId) as? String
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKeys.id)
        aCoder.encode(self.userId, forKey: PropertyKeys.userId)
        aCoder.encode(self.toUserId, forKey: PropertyKeys.toUserId)
        aCoder.encode(self.chatId, forKey: PropertyKeys.chatId)
        aCoder.encode(self.text, forKey: PropertyKeys.text)
        aCoder.encode(self.timestamp, forKey: PropertyKeys.timestamp)
        aCoder.encode(self.keyMessage, forKey: PropertyKeys.keyMessage)
        if let seen = self.seen{
            aCoder.encode(seen, forKey: PropertyKeys.seen)
        }
        aCoder.encode(self.associatedPostId, forKey: PropertyKeys.associatedPostId)
    }
    
    fileprivate struct PropertyKeys {
        static let id = "_id"
        static let userId = "userId"
        static let toUserId = "toUserId"
        static let chatId = "chatId"
        static let text = "text"
        static let timestamp = "timestamp"
        static let keyMessage = "keyMessage"
        static let seen = "seen"
        static let associatedPostId = "associatedPostId"
    }
    
    func isOwn(_ userId: String) -> Bool{
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
