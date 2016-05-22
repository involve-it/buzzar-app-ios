//
//  AccountHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/21/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class AccountHandler{
    private let totalDependencies = 2
    private var resolvedDependencies = 0
    private var latestCallId = 0
    
    public private(set) var status:Status = .NotInitialized;
    
    public private(set) var myPosts: [Post]?
    public private(set) var currentUser: User?
    
    public func register(user: RegisterUser, callback: MeteorMethodCallback){
        ConnectionHandler.Instance.users.register(user, callback: callback)
    }
    
    public func login(userName: String, password: String, callback: MeteorMethodCallback){
        ConnectionHandler.Instance.users.login(userName, password: password) { (success, errorId, errorMessage, result) in
            callback(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
            if (success){
                self.loadAccount()
            }
        }
    }
    
    public func logoff(callback: (success: Bool)-> Void){
        ConnectionHandler.Instance.users.logoff { (success) in
            if success {
                CachingHandler.deleteAllPrivateFiles()
                self.currentUser = nil
                self.myPosts = nil
            }
            callback(success: success)
            NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
        }
    }

    
    public func saveUser(user: User, callback: (success: Bool, errorMessage: String?) -> Void){
        ConnectionHandler.Instance.users.saveUser(user) { (success, errorId, errorMessage, result) in
            if errorId == nil {
                self.currentUser = user
                CachingHandler.saveObject(self.currentUser!, path: CachingHandler.currentUser)
                
                NotificationManager.sendNotification(.UserUpdated, object: nil)
                
            }
            
            callback(success: success, errorMessage: errorMessage)
        }
    }
    
    public func loadAccount(){
        self.resolvedDependencies = 0
        self.status = .Loading
        
        self.latestCallId += 1
        let callId = self.latestCallId
        
        if ConnectionHandler.Instance.users.isLoggedIn(){
            
            ConnectionHandler.Instance.users.getCurrentUser({ (success, errorId, errorMessage, result) in
                if (self.latestCallId == callId){
                    if (success){
                        self.currentUser = result as? User
                        
                        CachingHandler.saveObject(self.currentUser!, path: CachingHandler.currentUser)
                        NotificationManager.sendNotification(NotificationManager.Name.UserUpdated, object: nil)
                    } else {
                        NSLog("Error getting current user")
                    }
                    self.resolvedDependencies += 1
                    self.handleCompleted(callId)
                }
            })

            ConnectionHandler.Instance.posts.getMyPosts(0, take: 100, callback: { (success, errorId, errorMessage, result) in
                if self.latestCallId == callId {
                    if (success){
                        self.myPosts = result as? [Post]
                        
                        CachingHandler.saveObject(self.myPosts!, path: CachingHandler.postsMy)
                        
                        NotificationManager.sendNotification(.MyPostsUpdated, object: nil)
                    }
                    self.resolvedDependencies += 1
                    self.handleCompleted(callId)
                    if !success {
                        NSLog("Error loading my posts")
                    }
                }
            })
        }
    }
    
    public func updateMyPosts(callback: MeteorMethodCallback){
        ConnectionHandler.Instance.posts.getMyPosts(0, take: 100, callback: { (success, errorId, errorMessage, result) in
            if success {
                self.myPosts = result as? [Post]
                
                CachingHandler.saveObject(self.myPosts!, path: CachingHandler.postsMy)
                NotificationManager.sendNotification(.MyPostsUpdated, object: nil)
            }
            callback(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
        })
    }
    
    private func handleCompleted(callId: Int){
        if callId == self.latestCallId && self.resolvedDependencies == self.totalDependencies {
            self.resolvedDependencies = 0
            self.status = .Completed
            
            NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
        }
    }
    
    private init (){}
    private static let instance = AccountHandler()
    public static var Instance: AccountHandler {
        get{
            return instance
        }
    }
    
    public enum Status{
        case NotInitialized, Loading, Completed
    }
}