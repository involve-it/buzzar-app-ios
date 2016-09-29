//
//  Chat.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class Chat: NSObject, DictionaryInitializable, NSCoding {
    var id: String?
    var userId: String?
    var otherUserIds: [String]?
    var created: NSDate?
    var lastMessageTimestamp: NSDate?
    var activated: Bool?
    var lastMessage: String?
    var otherParty: User?
    var seen: Bool?
    var toUserId: String?
    
    var messages = [Message]()
    var messagesRequested = false
    
    override init (){
        super.init()
    }
    
    required public init (fields: NSDictionary?){
        super.init()
        
        self.id = fields?.objectForKey(PropertyKeys.id) as? String
        self.userId = fields?.objectForKey(PropertyKeys.userId) as? String
        if let users = fields?.objectForKey(PropertyKeys.otherUserIds) as? [String?]{
            self.otherUserIds = [String]()
            users.forEach({ (otherUserId) in
                if let ouId = otherUserId {
                    self.otherUserIds?.append(ouId)
                }
            })
        }
        if let createdMilliseconds = fields?.valueForKey(PropertyKeys.created) as? Double {
            self.created = NSDate(timeIntervalSince1970: createdMilliseconds / 1000)
        }
        if let lastMessageTimestampMilliseconds = fields?.valueForKey(PropertyKeys.lastMessageTimestamp) as? Double{
            self.lastMessageTimestamp = NSDate(timeIntervalSince1970: lastMessageTimestampMilliseconds / 1000)
        }
        self.activated = fields?.objectForKey(PropertyKeys.activated) as? Bool
        
        if let messagesArray = fields?.valueForKey(PropertyKeys.messages) as? [NSDictionary]{
            messagesArray.forEach({ (messageFields) in
                self.messages.append(Message(fields: messageFields))
            })
        }
        if let lastMessageFields = fields?.valueForKey(PropertyKeys.lastMessage) as? NSDictionary{
            self.lastMessage = lastMessageFields.valueForKey("text") as? String
            self.seen = lastMessageFields.valueForKey(PropertyKeys.seen) as? Bool
            self.toUserId = lastMessageFields.valueForKey(PropertyKeys.toUserId) as? String
        }
        
        if let otherUsers = fields?.valueForKey(PropertyKeys.otherParty) as? NSArray {
            if let otherUserFields = otherUsers.firstObject as? NSDictionary {
                self.otherParty = User(fields: otherUserFields)
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObjectForKey(PropertyKeys.id) as? String
        self.userId = aDecoder.decodeObjectForKey(PropertyKeys.userId) as? String
        self.otherUserIds = aDecoder.decodeObjectForKey(PropertyKeys.otherUserIds) as? [String]
        self.created = aDecoder.decodeObjectForKey(PropertyKeys.created) as? NSDate
        self.lastMessageTimestamp = aDecoder.decodeObjectForKey(PropertyKeys.lastMessageTimestamp) as? NSDate
        if aDecoder.containsValueForKey(PropertyKeys.activated){
            self.activated = aDecoder.decodeBoolForKey(PropertyKeys.activated)
        }
        self.messages = aDecoder.decodeObjectForKey(PropertyKeys.messages) as! [Message]
        self.lastMessage = aDecoder.decodeObjectForKey(PropertyKeys.lastMessage) as? String
        self.otherParty = aDecoder.decodeObjectForKey(PropertyKeys.otherParty) as? User
        if aDecoder.containsValueForKey(PropertyKeys.seen){
            self.seen = aDecoder.decodeBoolForKey(PropertyKeys.seen)
        }
        self.toUserId = aDecoder.decodeObjectForKey(PropertyKeys.toUserId) as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.id, forKey: PropertyKeys.id)
        aCoder.encodeObject(self.userId, forKey: PropertyKeys.userId)
        aCoder.encodeObject(self.otherUserIds, forKey: PropertyKeys.otherUserIds)
        aCoder.encodeObject(self.created, forKey: PropertyKeys.created)
        aCoder.encodeObject(self.lastMessageTimestamp, forKey: PropertyKeys.lastMessageTimestamp)
        if let activated = self.activated {
            aCoder.encodeBool(activated, forKey: PropertyKeys.activated)
        }
        aCoder.encodeObject(self.messages, forKey: PropertyKeys.messages)
        aCoder.encodeObject(self.lastMessage, forKey: PropertyKeys.lastMessage)
        aCoder.encodeObject(self.otherParty, forKey: PropertyKeys.otherParty)
        if let seen = self.seen {
            aCoder.encodeBool(seen, forKey: PropertyKeys.seen)
        }
        aCoder.encodeObject(self.toUserId, forKey: PropertyKeys.toUserId)
    }
    
    func addMessage(message: Message){
        self.messages.append(message)
        self.lastMessage = message.text
        self.lastMessageTimestamp = message.timestamp
        self.toUserId = message.toUserId
    }
    
    private struct PropertyKeys {
        static let id = "_id"
        static let userId = "userId"
        static let otherUserIds = "users"
        static let created = "timeBegin"
        static let lastMessageTimestamp = "lastMessageTs"
        static let activated = "activated"
        static let lastMessage = "lastMessage"
        static let otherParty = "otherParty"
        
        static let messages = "messages"
        static let seen = "seen"
        static let toUserId = "toUserId"
    }
}