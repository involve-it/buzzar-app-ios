//
//  Chat.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class Chat: NSObject, DictionaryInitializable, NSCoding {
    var id: String?
    var userId: String?
    var otherUserIds: [String]?
    var created: Date?
    var lastMessageTimestamp: Date?
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
        
        self.id = fields?.object(forKey: PropertyKeys.id) as? String
        self.userId = fields?.object(forKey: PropertyKeys.userId) as? String
        if let users = fields?.object(forKey: PropertyKeys.otherUserIds) as? [String?]{
            self.otherUserIds = [String]()
            users.forEach({ (otherUserId) in
                if let ouId = otherUserId {
                    self.otherUserIds?.append(ouId)
                }
            })
        }
        if let createdMilliseconds = fields?.value(forKey: PropertyKeys.created) as? Double {
            self.created = Date(timeIntervalSince1970: createdMilliseconds / 1000)
        }
        if let lastMessageTimestampMilliseconds = fields?.value(forKey: PropertyKeys.lastMessageTimestamp) as? Double{
            self.lastMessageTimestamp = Date(timeIntervalSince1970: lastMessageTimestampMilliseconds / 1000)
        }
        self.activated = fields?.object(forKey: PropertyKeys.activated) as? Bool
        
        if let messagesArray = fields?.value(forKey: PropertyKeys.messages) as? [NSDictionary]{
            messagesArray.forEach({ (messageFields) in
                self.messages.append(Message(fields: messageFields))
            })
        }
        if let lastMessageFields = fields?.value(forKey: PropertyKeys.lastMessage) as? NSDictionary{
            self.lastMessage = lastMessageFields.value(forKey: "text") as? String
            self.seen = lastMessageFields.value(forKey: PropertyKeys.seen) as? Bool
            self.toUserId = lastMessageFields.value(forKey: PropertyKeys.toUserId) as? String
        }
        
        if let otherUsers = fields?.value(forKey: PropertyKeys.otherParty) as? NSArray {
            if let otherUserFields = otherUsers.firstObject as? NSDictionary {
                self.otherParty = User(fields: otherUserFields)
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: PropertyKeys.id) as? String
        self.userId = aDecoder.decodeObject(forKey: PropertyKeys.userId) as? String
        self.otherUserIds = aDecoder.decodeObject(forKey: PropertyKeys.otherUserIds) as? [String]
        self.created = aDecoder.decodeObject(forKey: PropertyKeys.created) as? Date
        self.lastMessageTimestamp = aDecoder.decodeObject(forKey: PropertyKeys.lastMessageTimestamp) as? Date
        if aDecoder.containsValue(forKey: PropertyKeys.activated){
            self.activated = aDecoder.decodeBool(forKey: PropertyKeys.activated)
        }
        self.messages = aDecoder.decodeObject(forKey: PropertyKeys.messages) as! [Message]
        self.lastMessage = aDecoder.decodeObject(forKey: PropertyKeys.lastMessage) as? String
        self.otherParty = aDecoder.decodeObject(forKey: PropertyKeys.otherParty) as? User
        if aDecoder.containsValue(forKey: PropertyKeys.seen){
            self.seen = aDecoder.decodeBool(forKey: PropertyKeys.seen)
        }
        self.toUserId = aDecoder.decodeObject(forKey: PropertyKeys.toUserId) as? String
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKeys.id)
        aCoder.encode(self.userId, forKey: PropertyKeys.userId)
        aCoder.encode(self.otherUserIds, forKey: PropertyKeys.otherUserIds)
        aCoder.encode(self.created, forKey: PropertyKeys.created)
        aCoder.encode(self.lastMessageTimestamp, forKey: PropertyKeys.lastMessageTimestamp)
        if let activated = self.activated {
            aCoder.encode(activated, forKey: PropertyKeys.activated)
        }
        aCoder.encode(self.messages, forKey: PropertyKeys.messages)
        aCoder.encode(self.lastMessage, forKey: PropertyKeys.lastMessage)
        aCoder.encode(self.otherParty, forKey: PropertyKeys.otherParty)
        if let seen = self.seen {
            aCoder.encode(seen, forKey: PropertyKeys.seen)
        }
        aCoder.encode(self.toUserId, forKey: PropertyKeys.toUserId)
    }
    
    func addMessage(_ message: Message){
        self.messages.append(message)
        self.lastMessage = message.text
        self.lastMessageTimestamp = message.timestamp as Date?
        self.toUserId = message.toUserId
    }
    
    fileprivate struct PropertyKeys {
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
