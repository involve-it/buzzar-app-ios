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
        super.init(name: "bz.messages");
    }
    
    override func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        let message = Message(id: id, fields: fields)
        self.messages.append(message)
        
        if let chatIndex = AccountHandler.Instance.myChats?.indexOf({return $0.id == message.chatId}), chat = AccountHandler.Instance.myChats?[chatIndex] {
            chat.messages.append(message)
            
            NotificationManager.sendNotification(NotificationManager.Name.MessageAdded, object: message)
        } else {
            ConnectionHandler.Instance.messages.getChat(message.chatId!){ success, errorId, errorMessage, result in
                if let chat = result as? Chat where success {
                    chat.messages.append(message)
                    AccountHandler.Instance.myChats?.append(chat)
                    
                    NotificationManager.sendNotification(.ChatAdded, object: chat)
                } else {
                    NSLog("error loading chat")
                }
            }
        }
    }
    
    override func documentWasRemoved(collection: String, id: String) {
        if let index = self.messages.indexOf({message in return message.id == id}){
            let message = self.messages[index]
            self.messages.removeAtIndex(index)
            
            if let chatIndex = AccountHandler.Instance.myChats?.indexOf({return $0.id == message.chatId}), chat = AccountHandler.Instance.myChats?[chatIndex], messageIndex = chat.messages.indexOf({return $0.id == message.id}) {
                chat.messages.removeAtIndex(messageIndex)
                
                NotificationManager.sendNotification(NotificationManager.Name.MessageRemoved, object: message)
            } else {
                NSLog("message was removed, chat unknown!")
            }
        }
    }
    
    override func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.messages.indexOf({message in return message.id == id}){
            let message = self.messages[index];
            message.update(fields);
            
            if let chatIndex = AccountHandler.Instance.myChats?.indexOf({return $0.id == message.chatId}), chat = AccountHandler.Instance.myChats?[chatIndex], messageIndex = chat.messages.indexOf({return $0.id == message.id}) {
                chat.messages.removeAtIndex(messageIndex)
                chat.messages.insert(message, atIndex: messageIndex)
                
                NotificationManager.sendNotification(NotificationManager.Name.MessageModified, object: message)
            } else {
                NSLog("message was changed, chat unknown!")
            }
        }
    }
    
    func count() -> Int{
        return messages.count;
    }
    
    func itemAtIndex(index: Int) -> Message{
        return messages[index];
    }
}