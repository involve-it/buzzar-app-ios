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
    
    public var currentUser: User?
    
    public func getCurrentUser(callback: (success: Bool) -> Void){
        if let userId = Meteor.client.userId() {
            self.getUser(userId) { (user) in
                if let currentUser = user {
                    self.currentUser = currentUser
                    callback(success: true)
                } else {
                    callback(success: false)
                }
            }
        } else {
            callback(success: false)
        }
    }
    
    public func getUser(userId: String, callback: (user: User?) -> Void){
        Meteor.call("getUser", params: [Meteor.client.userId()!]){ result, error in
            var user: User?
            if (error == nil){
                if let userFields = result as? NSDictionary {
                    user = User(fields: userFields)
                }
            }
            callback(user: user)
        };
    }
    
    public func saveUser(user: User, callback: (success: Bool, errorId: Int?) -> Void){
        Meteor.call("editUser", params: [user.toDictionary()]){ result, error in
            if (error == nil){
                let errorId = ResponseErrorHelper.getError(result)
                if errorId == nil {
                    self.currentUser = user
                    NotificationManager.sendNotification(.UserUpdated, object: nil)
                }
                callback(success: errorId == nil, errorId: errorId)
            } else {
                callback(success: false, errorId: nil)
            }
        }
    }
    
    public func register(user: RegisterUser, callback: (success: Bool, errorId: Int?) -> Void){
        Meteor.call("addUser", params: [user.toDictionary()]){ result, error in
            if (error == nil){
                let errorId = ResponseErrorHelper.getError(result)
                callback(success: errorId == nil, errorId: errorId)
            } else {
                callback(success: false, errorId: nil)
            }
        }
    }
    
    public func login(userName: String, password: String, callback: (success: Bool, reason: String?) -> Void){
        Meteor.loginWithUsername(userName, password: password){ result, error in
            if (error == nil){
                self.getCurrentUser(){ (success) in
                    if (success){
                        callback(success: true, reason: nil)
                    } else {
                        callback(success: false, reason: "Error retrieveing user")
                    }
                }
            } else {
                let reason = error?.reason;
                callback(success: false, reason: reason);
            }
        }
    }
    
    public func logoff(callback: (success: Bool)-> Void){
        Meteor.logout(){ result, error in
            if (error == nil){
                self.currentUser = nil;
                callback(success: true)
            } else {
                callback(success: false)
            }
        }
    }
    
    @objc private func didLogin(){
        NSLog("LOGGED IN");
    }
    
    public func isLoggedIn() -> Bool {
        return Meteor.client.userId() != nil
    }
}