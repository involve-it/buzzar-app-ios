//
//  MessagesHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class MessagesHandler {
    static let DEFAULT_PAGE_SIZE = 20
    private var data = Dictionary<String, MessagesResponse>()
    
    func getMessagesByRequestId(id: String) -> Array<Message>?{
        return data.removeValueForKey(id)?.messages
    }
    
    func isCompleted(id: String) -> Bool?{
        return data[id]?.done
    }
    
    func getMessagesAsync(chatId: String, skip: Int, take: Int = MessagesHandler.DEFAULT_PAGE_SIZE) -> String{
        let id = NSUUID().UUIDString
        let response = MessagesResponse()
        self.data[id] = response
        ConnectionHandler.Instance.messages.getMessages(chatId, skip: skip, take: take) { (success, errorId, errorMessage, result) in
            response.setSuccess(success, messages: result as? Array<Message>)
            NotificationManager.sendNotification(NotificationManager.Name.MessagesAsyncRequestCompleted, object: id)
        }
        return id
    }
    
    
    private init (){}
    private static let instance = MessagesHandler()
    static var Instance: MessagesHandler {
        get{
            return instance
        }
    }
    
    private class MessagesResponse{
        var success: Bool?
        var done: Bool
        var messages: Array<Message>?
        
        init(){
            done = false
        }
        
        func setSuccess(success: Bool, messages: Array<Message>?){
            self.success = success
            self.messages = messages
        }
    }
}