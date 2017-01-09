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
    fileprivate var data = Dictionary<String, MessagesResponse>()
    fileprivate var pendingRequests = [MessagesRequest]()
    
    func getMessagesByRequestId(_ id: String) -> Array<Message>?{
        return data.removeValue(forKey: id)?.messages
    }
    
    func isCompleted(_ id: String) -> Bool?{
        return data[id]?.done
    }
    
    func getMessagesAsync(_ chatId: String, skip: Int, take: Int = MessagesHandler.DEFAULT_PAGE_SIZE) -> String{
        let id = UUID().uuidString
        let request = MessagesRequest(id: id, chatId: chatId, take: take + 1, skip: skip)
        if ConnectionHandler.Instance.isNetworkConnected() {
            self.processRequest(request)
        } else {
            if self.pendingRequests.count == 0 {
                NotificationCenter.default.addObserver(self, selector: #selector(processPendingRequests), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            }
            
            pendingRequests.append(request)
        }
        return id
    }
    
    @objc func processPendingRequests(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        self.pendingRequests.forEach { (request) in
            self.processRequest(request)
        }
        self.pendingRequests.removeAll()
    }
    
    fileprivate func processRequest(_ request: MessagesRequest){
        let response = MessagesResponse()
        self.data[request.id] = response
        ConnectionHandler.Instance.messages.getMessages(request.chatId, skip: request.skip, take: request.take) { (success, errorId, errorMessage, result) in
            response.setSuccess(success, messages: result as? Array<Message>)
            NotificationManager.sendNotification(NotificationManager.Name.MessagesAsyncRequestCompleted, object: request.id as AnyObject?)
        }
    }
    
    fileprivate init (){}
    fileprivate static let instance = MessagesHandler()
    static var Instance: MessagesHandler {
        get{
            return instance
        }
    }
    
    fileprivate class MessagesResponse{
        var success: Bool?
        var done: Bool
        var messages: Array<Message>?
        
        init(){
            done = false
        }
        
        func setSuccess(_ success: Bool, messages: Array<Message>?){
            self.success = success
            self.messages = messages
        }
    }
    
    fileprivate class MessagesRequest{
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
