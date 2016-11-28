//
//  MessagesHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class MessagesHandler {
    static let DEFAULT_PAGE_SIZE = 40
    private var data = Dictionary<String, MessagesResponse>()
    private var pendingRequests = [MessagesRequest]()
    
    func getMessagesByRequestId(id: String) -> Array<Message>?{
        return data.removeValueForKey(id)?.messages
    }
    
    func isCompleted(id: String) -> Bool?{
        return data[id]?.done
    }
    
    func getMessagesAsync(chatId: String, skip: Int, take: Int = MessagesHandler.DEFAULT_PAGE_SIZE) -> String{
        let id = NSUUID().UUIDString
        let request = MessagesRequest(id: id, chatId: chatId, take: take, skip: skip)
        if ConnectionHandler.Instance.isNetworkConnected() {
            self.processRequest(request)
        } else {
            if self.pendingRequests.count == 0 {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(processPendingRequests), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            }
            
            pendingRequests.append(request)
        }
        return id
    }
    
    @objc func processPendingRequests(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        self.pendingRequests.forEach { (request) in
            self.processRequest(request)
        }
        self.pendingRequests.removeAll()
    }
    
    private func processRequest(request: MessagesRequest){
        let response = MessagesResponse()
        self.data[request.id] = response
        ConnectionHandler.Instance.messages.getMessages(request.chatId, skip: request.skip, take: request.take) { (success, errorId, errorMessage, result) in
            response.setSuccess(success, messages: result as? Array<Message>)
            NotificationManager.sendNotification(NotificationManager.Name.MessagesAsyncRequestCompleted, object: request.id)
        }
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
    
    private class MessagesRequest{
        var chatId: String
        var skip: Int
        var take: Int
        var id: String
        
        init(id : String, chatId: String, take: Int, skip: Int){
            self.id = id
            self.skip = skip
            self.take = take
            self.chatId = chatId
        }
    }
}