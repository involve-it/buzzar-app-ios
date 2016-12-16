//
//  UsersProxy.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/4/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

open class UsersProxy{
    fileprivate init(){
        NotificationCenter.default.addObserver(self, selector: #selector(didLogin), name: NSNotification.Name(rawValue: DDP_USER_DID_LOGIN), object: nil);
    }
    
    fileprivate static let instance = UsersProxy()
    open class var Instance: UsersProxy{
        get{
            return instance;
        }
    }
    
    open func errorLog(_ log: String, callback: @escaping MeteorMethodCallback){
        var dict = Dictionary<String, AnyObject>()
        dict["userId"] = Meteor.client.userId() as AnyObject?
        dict["data"] = log as AnyObject?
        dict["platform"] = "ios" as AnyObject?
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            dict["version"] = version as AnyObject?
        }
        
        Meteor.call("errorLog", params: [dict]){(result, error) in
            if error == nil{
                callback(ResponseHelper.isSuccessful(result as AnyObject?), nil, nil, nil)
            } else {
                callback(false, nil, nil, nil)
            }
        }
    }
    
    open func contactUs(_ email: String, subject: String, message: String, callback: @escaping MeteorMethodCallback){
        var dict = Dictionary<String, AnyObject>()
        dict["email"] = email as AnyObject?
        dict["subject"] = subject as AnyObject?
        dict["message"] = message as AnyObject?
        
        Meteor.call("contactUs", params: [dict]) { (result, error) in
            if error == nil{
                callback(ResponseHelper.isSuccessful(result as AnyObject?), nil, nil, nil)
            } else {
                callback(false, nil, nil, nil)
            }
        }
    }
    
    //public var currentUser: User?
    
    open func getCurrentUser(_ callback: @escaping MeteorMethodCallback){
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
            callback(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
        }
    }
    
    open func getUser(_ userId: String, callback: @escaping MeteorMethodCallback){
        Meteor.call("getUser", params: [Meteor.client.userId()!]){ result, error in
            if (error == nil){
                if let user = ResponseHelper.callHandler(result as AnyObject?, handler: callback) as User?{
                    AccountHandler.Instance.mergeNewUsers([user])
                }
            } else {
                callback(false, nil, error?.reason, nil)
            }
        };
    }
    
    open func saveUser(_ user: User, callback: @escaping MeteorMethodCallback){
        Meteor.call("editUser", params: [user.toDictionary()]){ result, error in
            if (error == nil){
                let errorId = ResponseHelper.getErrorId(result as AnyObject?)
                callback(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), user)
            } else {
                callback(false, nil, error?.reason, nil)
            }
        }
    }
    
    open func register(_ user: RegisterUser, callback: @escaping MeteorMethodCallback){
        Meteor.call("addUser", params: [user.toDictionary()]){ result, error in
            if (error == nil){
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback(false, nil, error?.reason, nil)
            }
        }
    }
    
    open func resetPassword(_ email: String, callback: @escaping MeteorMethodCallback){
        var dict = Dictionary<String, AnyObject>()
        dict["email"] = email as AnyObject?
        Meteor.call("forgotPassword", params: [dict]) { (result, error) in
            if (error == nil){
                //let errorId = ResponseHelper.getErrorId(result)
                callback(true, nil, nil, nil)
            } else {
                callback(false, nil, error?.reason, nil)
            }
        }
    }
    
    open func login(_ userName: String, password: String, callback: @escaping MeteorMethodCallback){
        Meteor.loginWithUsername(userName, password: password){ result, error in
            if (error == nil){
                callback(true, nil, nil, nil);
            } else {
                let reason = error?.reason;
                callback(false, nil, reason, nil);
            }
        }
    }
    
    open func logoff(_ callback: @escaping (_ success: Bool)-> Void){
        Meteor.logout(){ result, error in
            if (error == nil){
                callback(true)
            } else {
                callback(false)
            }
        }
    }
    
    @objc fileprivate func didLogin(){
        NSLog("LOGGED IN");
    }
}
