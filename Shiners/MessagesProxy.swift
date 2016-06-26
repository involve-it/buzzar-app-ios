//
//  MessagesProxy.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class MessagesProxy {
    private static let instance = MessagesProxy()
    class var Instance: MessagesProxy{
        get{
            return instance;
        }
    }
    
    func getChat(id: String, callback: MeteorMethodCallback? = nil){
        Meteor.call("getChat", params: [id]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandler(result, handler: callback) as Chat?
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    func getChats(skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["take"] = take
        dict["skip"] = skip
        
        Meteor.call("getChats", params: [dict]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandlerArray(result, handler: callback) as [Chat]?
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    func getMessages(chatId: String, skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["take"] = take
        dict["skip"] = skip
        dict["chatId"] = chatId
        
        Meteor.call("getMessages", params: [dict]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandlerArray(result, handler: callback) as [Message]?
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    func sendMessage(message: MessageToSend, callback: MeteorMethodCallback? = nil){
        let dict = message.toDictionary()
        Meteor.call("addMessage", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    func deleteChats(chatIds: Array<String>, callback: MeteorMethodCallback? = nil){
        Meteor.call("deleteChats", params: [chatIds]){ (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
}