//
//  MessagesCollection.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

class MessagesCollection: AbstractCollection{
    var messages = [Message]()
    
    init() {
        super.init(name: "messages");
    }
    
    override func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        let message = Message(id: id, fields: fields)
        self.messages.append(message)
        NotificationManager.sendNotification(NotificationManager.Name.MessageAdded, object: nil)
    }
    
    override func documentWasRemoved(collection: String, id: String) {
        if let index = self.messages.indexOf({post in return post.id == id}){
            self.messages.removeAtIndex(index)
            NotificationManager.sendNotification(NotificationManager.Name.MessageRemoved, object: nil)
        }
    }
    
    override func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.messages.indexOf({post in return post.id == id}){
            let message = self.messages[index];
            message.update(fields);
            NotificationManager.sendNotification(NotificationManager.Name.MessageModified, object: nil)
        }
    }
    
    func count() -> Int{
        return messages.count;
    }
    
    func itemAtIndex(index: Int) -> Message{
        return messages[index];
    }
}