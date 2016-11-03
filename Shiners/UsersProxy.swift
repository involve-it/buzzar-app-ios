//
//  UsersProxy.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/4/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class UsersProxy{
    private init(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didLogin), name: DDP_USER_DID_LOGIN, object: nil);
    }
    
    private static let instance = UsersProxy()
    public class var Instance: UsersProxy{
        get{
            return instance;
        }
    }
    
    public func contactUs(email: String, subject: String, message: String, callback: MeteorMethodCallback){
        var dict = Dictionary<String, AnyObject>()
        dict["email"] = email
        dict["subject"] = subject
        dict["message"] = message
        
        Meteor.call("contactUs", params: [dict]) { (result, error) in
            if error == nil{
                callback(success: ResponseHelper.isSuccessful(result), errorId: nil, errorMessage: nil, result: nil)
            } else {
                callback(success: false, errorId: nil, errorMessage: nil, result: nil)
            }
        }
    }
    
    //public var currentUser: User?
    
    public func getCurrentUser(callback: MeteorMethodCallback){
        if let userId = Meteor.client.userId() {
            self.getUser(userId, callback: callback) /*{ (success, errorId, errorMessage, result) in
                
                if (success){
                    var user = result as? User
                    CachingHandler.saveObject(self.currentUser!, path: CachingHandler.currentUser)
                    NotificationManager.sendNotification(NotificationManager.Name.UserUpdated, object: nil)
                }
                callback(success: success)
            }*/
        } else {
            callback(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
        }
    }
    
    public func getUser(userId: String, callback: MeteorMethodCallback){
        Meteor.call("getUser", params: [Meteor.client.userId()!]){ result, error in
            if (error == nil){
                ResponseHelper.callHandler(result, handler: callback) as User?
            } else {
                callback(success: false, errorId: nil, errorMessage: error?.reason, result: nil)
            }
        };
    }
    
    public func saveUser(user: User, callback: MeteorMethodCallback){
        Meteor.call("editUser", params: [user.toDictionary()]){ result, error in
            if (error == nil){
                let errorId = ResponseHelper.getErrorId(result)
                callback(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: user)
            } else {
                callback(success: false, errorId: nil, errorMessage: error?.reason, result: nil)
            }
        }
    }
    
    public func register(user: RegisterUser, callback: MeteorMethodCallback){
        Meteor.call("addUser", params: [user.toDictionary()]){ result, error in
            if (error == nil){
                let errorId = ResponseHelper.getErrorId(result);
                callback(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback(success: false, errorId: nil, errorMessage: error?.reason, result: nil)
            }
        }
    }
    
    public func login(userName: String, password: String, callback: MeteorMethodCallback){
        Meteor.loginWithUsername(userName, password: password){ result, error in
            if (error == nil){
                callback(success: true, errorId: nil, errorMessage: nil, result: nil);
            } else {
                let reason = error?.reason;
                callback(success: false, errorId: nil, errorMessage: reason, result: nil);
            }
        }
    }
    
    public func logoff(callback: (success: Bool)-> Void){
        Meteor.logout(){ result, error in
            if (error == nil){
                callback(success: true)
            } else {
                callback(success: false)
            }
        }
    }
    
    @objc private func didLogin(){
        NSLog("LOGGED IN");
    }
}