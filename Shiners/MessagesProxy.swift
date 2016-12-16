//
//  MessagesProxy.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

open class MessagesProxy {
    fileprivate static let instance = MessagesProxy()
    class var Instance: MessagesProxy{
        get{
            return instance;
        }
    }
    
    func messagesSetSeen(_ messageIds: [String], callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["messageIds"] = messageIds as AnyObject?
        Meteor.call("messagesSetSeen", params: [dict]){ (result, error) in
            if error == nil {
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), 1, ResponseHelper.getDefaultErrorMessage(), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func getChat(_ id: String, callback: MeteorMethodCallback? = nil){
        Meteor.call("getChat", params: [id]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandler(result as AnyObject?, handler: callback) as Chat?
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func getChats(_ skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["take"] = take as AnyObject?
        dict["skip"] = skip as AnyObject?
        
        Meteor.call("getChats", params: [dict]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandlerArray(result as AnyObject?, handler: callback) as [Chat]?
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func getMessages(_ chatId: String, skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["take"] = take as AnyObject?
        dict["skip"] = skip as AnyObject?
        dict["chatId"] = chatId as AnyObject?
        
        Meteor.call("getMessages", params: [dict]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandlerArray(result as AnyObject?, handler: callback) as [Message]?
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func sendMessage(_ message: MessageToSend, callback: MeteorMethodCallback? = nil){
        let dict = message.toDictionary()
        Meteor.call("addMessage", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func deleteChats(_ chatIds: Array<String>, callback: MeteorMethodCallback? = nil){
        Meteor.call("deleteChats", params: [chatIds]){ (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
}
