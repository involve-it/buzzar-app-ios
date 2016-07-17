//
//  AccountHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/21/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class AccountHandler{
    private let totalDependencies = 3
    private var resolvedDependencies = 0
    private var latestCallId = 0
    
    public private(set) var status:Status = .NotInitialized;
    
    public var myChats: [Chat]?
    public private(set) var myPosts: [Post]?
    public private(set) var currentUser: User?
    public private(set) var userId: String?
    
    public var postsCollection = PostsCollection()
    private var nearbyPostsId: String?
    
    var messagesCollection = MessagesCollection()
    private var messagesId: String?
    
    func subscribeToNewMessages(){
        if let messagesId = self.messagesId {
            Meteor.unsubscribe(withId: messagesId)
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(saveMyChats), name: NotificationManager.Name.MessageAdded.rawValue, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(saveMyChats), name: NotificationManager.Name.MessageRemoved.rawValue, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(saveMyChats), name: NotificationManager.Name.MessageModified.rawValue, object: nil)
        }
        self.messagesId = Meteor.subscribe("messages-new") {
            NSLog("messages-new subscribed");
            NotificationManager.sendNotification(NotificationManager.Name.MessagesNewSubscribed, object: nil)
        }
    }
    
    @objc private func saveMyChats(){
        CachingHandler.saveObject(self.myChats!, path: CachingHandler.chats)
    }
    
    public func subscribeToNearbyPosts(lat: Double, lng: Double, radius: Double){
        if let nearbyPostsId = self.nearbyPostsId {
            Meteor.unsubscribe(withId: nearbyPostsId)
        }
        var dict = Dictionary<String, AnyObject>()
        dict["lat"] = lat
        //todo: fix paging
        dict["lng"] = lng
        dict["radius"] = radius
        self.nearbyPostsId = Meteor.subscribe("posts-nearby", params: [dict]) {
            //saving posts for offline use
            ThreadHelper.runOnBackgroundThread(){
                if !CachingHandler.saveObject(self.postsCollection.posts, path: CachingHandler.postsAll){
                    NSLog("Unable to archive posts")
                }
            }
            
            NSLog("posts-nearby subscribed");
            NotificationManager.sendNotification(NotificationManager.Name.NearbyPostsSubscribed, object: nil)
        }
    }
    
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
    
    public func loginFacebook(clientId: String, viewController: UIViewController){
        Meteor.loginWithFacebook(clientId, viewController: viewController)
    }
    
    public func logoff(callback: (success: Bool)-> Void){
        self.unregisterToken { (success) in
            if success{
                ConnectionHandler.Instance.users.logoff { (success) in
                    if success {
                        self.processLogoff()
                    }
                    
                    callback(success: success)
                }
            } else {
                callback(success: false)
            }
        }
    }
    
    public func processLogoff(){
        CachingHandler.deleteAllPrivateFiles()
        self.currentUser = nil
        self.myPosts = nil
        self.userId = nil
        
        NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
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
            self.userId = Meteor.client.userId()
            self.subscribeToNewMessages()
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
            
            ConnectionHandler.Instance.messages.getChats(0, take: 100, callback: { (success, errorId, errorMessage, result) in
                if self.latestCallId == callId {
                    if (success){
                        self.myChats = result as? [Chat]
                        
                        CachingHandler.saveObject(self.myChats!, path: CachingHandler.chats)
                        
                        NotificationManager.sendNotification(.MyChatsUpdated, object: nil)
                    }
                    self.resolvedDependencies += 1
                    self.handleCompleted(callId)
                    if !success {
                        NSLog("Error loading my chats")
                    }
                }
            })
        }
    }
    
    public func updateMyPosts(callback: MeteorMethodCallback? = nil){
        ConnectionHandler.Instance.posts.getMyPosts(0, take: 100, callback: { (success, errorId, errorMessage, result) in
            if success {
                self.myPosts = result as? [Post]
                
                CachingHandler.saveObject(self.myPosts!, path: CachingHandler.postsMy)
                NotificationManager.sendNotification(.MyPostsUpdated, object: nil)
            }
            callback?(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
        })
    }
    
    public func updateMyChats(callback: MeteorMethodCallback? = nil){
        ConnectionHandler.Instance.messages.getChats(0, take: 100, callback: { (success, errorId, errorMessage, result) in
            if success {
                self.myChats = result as? [Chat]
                
                self.saveMyChats()
                NotificationManager.sendNotification(NotificationManager.Name.MyChatsUpdated, object: nil)
            }
            callback?(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
        })
    }
    
    private func handleCompleted(callId: Int){
        if callId == self.latestCallId && self.resolvedDependencies == self.totalDependencies {
            self.resolvedDependencies = 0
            self.status = .Completed
            
            NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
        }
    }
    
    public func requestPushNotifications(){
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        let app = UIApplication.sharedApplication()
        app.registerForRemoteNotifications()
        app.registerUserNotificationSettings(settings)
    }
    
    /*public func savePushToken(callback: (success: Bool) -> Void){
        if let token = PushNotificationsHandler.getToken(), deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString, userId = Meteor.client.userId(){
            var dict = Dictionary<String, AnyObject>()
            dict["token"] = token
            dict["deviceId"] = deviceId
            dict["platform"] = "apn"
            dict["userId"] = userId
            
            Meteor.call("registerPushToken", params: [dict], callback: { (result, error) in
                if error == nil, let fields = result as? NSDictionary, success = fields.valueForKey("success") as? Bool{
                    callback(success: success)
                } else {
                    callback(success: false)
                }
            })
        } else {
            callback(success: false)
        }
    }*/

    public func savePushToken(callback: (success: Bool) -> Void){
        if let token = PushNotificationsHandler.getToken(), userId = Meteor.client.userId(){
            var dict = Dictionary<String, AnyObject>()
            var tokenDict = Dictionary<String, AnyObject>()
            tokenDict["apn"] = token
            dict["token"] = tokenDict
            dict["appName"] = "org.buzzar.app"
            dict["userId"] = userId
            
            Meteor.call("raix:push-update", params: [dict], callback: { (result, error) in
                if error == nil, let fields = result as? NSDictionary, _ = fields.valueForKey("_id") as? String{
                    callback(success: true)
                } else {
                    callback(success: false)
                }
            })
        } else {
            callback(success: false)
        }
    }

    
    public func unregisterToken(callback: (success: Bool) -> Void){
        /*if let deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString, userId = Meteor.client.userId(){
            var dict = Dictionary<String, AnyObject>()
            dict["deviceId"] = deviceId
            dict["platform"] = "apn"
            dict["userId"] = userId
            
            Meteor.call("unregisterPushToken", params: [dict], callback: { (result, error) in
                if error == nil, let fields = result as? NSDictionary, success = fields.valueForKey("success") as? Bool{
                    callback(success: success)
                } else {
                    callback(success: false)
                }
            })
        } else {
            callback(success: false)
        }*/
        
        callback(success: true)
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