//
//  MessagesCollection.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP
//import BRYXBanner

class MessagesCollection: AbstractCollection{
    var messages = [Message]()
    let bannerBackgroundColor = UIColor(red: 0, green: 122/255.0, blue: 1, alpha: 1)
    
    init() {
        super.init(name: "bz.messages");
    }
    
    override func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        let message = Message(id: id, fields: fields)
        self.messages.append(message)
        
        if let chatIndex = AccountHandler.Instance.myChats?.indexOf({return $0.id == message.chatId}), chat = AccountHandler.Instance.myChats?[chatIndex] {
            chat.addMessage(message)
            if message.toUserId == AccountHandler.Instance.userId {
                chat.seen = message.seen
            }
            
            if message.toUserId == AccountHandler.Instance.userId{
                /*if !LocalNotificationsHandler.Instance.isActive(.Messages, id: chat.id) && !LocalNotificationsHandler.Instance.isActive(.Messages, id: nil){
                    let banner = Banner(title: "New message from \(chat.otherParty?.username ?? "Unknown")", subtitle: message.shortMessage(), image: nil, backgroundColor: self.bannerBackgroundColor, didTapBlock: nil)
                    banner.dismissesOnTap = true
                    ThreadHelper.runOnMainThread({
                        banner.show(duration: 1.0)
                    })
                }*/
                
                LocalNotificationsHandler.Instance.reportNewEvent(.Messages, count: 1, id: chat.id, messageTitle: "New message from \(chat.otherParty?.username ?? "Unknown")", messageSubtitle: message.shortMessage())
            }
            NotificationManager.sendNotification(NotificationManager.Name.MessageAdded, object: message)
        } else {
            ConnectionHandler.Instance.messages.getChat(message.chatId!){ success, errorId, errorMessage, result in
                if AccountHandler.Instance.myChats?.indexOf({$0.id == message.chatId}) == nil{
                    if let chat = result as? Chat where success {
                        chat.addMessage(message)
                        if message.toUserId == AccountHandler.Instance.userId {
                            chat.seen = message.seen
                        }
                        chat.messagesRequested = true
                        AccountHandler.Instance.myChats?.insert(chat, atIndex: 0)
                        if message.toUserId == AccountHandler.Instance.userId{
                            LocalNotificationsHandler.Instance.reportNewEvent(.Messages, count: 1, id: chat.id)
                        }
                        NotificationManager.sendNotification(.MyChatsUpdated, object: chat)
                    } else {
                        NSLog("error loading chat")
                    }
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
    
    /*override func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.messages.indexOf({message in return message.id == id}){
            let message = self.messages[index];
            message.update(fields);
            
            if let chatIndex = AccountHandler.Instance.myChats?.indexOf({return $0.id == message.chatId}), chat = AccountHandler.Instance.myChats?[chatIndex], messageIndex = chat.messages.indexOf({return $0.id == message.id}) {
                chat.messages[messageIndex] = message
                //chat.messages.removeAtIndex(messageIndex)
                //chat.messages.insert(message, atIndex: messageIndex)
                
                NotificationManager.sendNotification(NotificationManager.Name.MessageModified, object: message)
            } else {
                NSLog("message was changed, chat unknown!")
            }
        }
    }*/
    
    func count() -> Int{
        return messages.count;
    }
    
    func itemAtIndex(index: Int) -> Message{
        return messages[index];
    }
}