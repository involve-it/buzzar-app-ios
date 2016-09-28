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
    private static let USER_ID = "shiners:userId"
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
            //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(saveMyChats), name: NotificationManager.Name.MessageModified.rawValue, object: nil)
        }
        self.messagesId = Meteor.subscribe("messages-new") {
            NSLog("messages-new subscribed");
            NotificationManager.sendNotification(NotificationManager.Name.MessagesNewSubscribed, object: nil)
        }
    }
    
    @objc public func saveMyChats(){
        if self.status == .Completed {
            CachingHandler.saveObject(self.myChats!, path: CachingHandler.chats)
        }
    }
    
    public func getNearbyPosts(lat: Double, lng: Double, radius: Double, callback: MeteorMethodCallback){
        ConnectionHandler.Instance.posts.getNearbyPosts(lat, lng: lng, radius: radius){ (success, errorId, errorMessage, result) in
            if success {
                ThreadHelper.runOnBackgroundThread(){
                    if !CachingHandler.saveObject(result as! [Post], path: CachingHandler.postsAll){
                        NSLog("Unable to archive posts")
                    }
                }
            }
            
            callback(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
        }
    }
    
    public func subscribeToNearbyPosts(lat: Double, lng: Double, radius: Double){
        if let nearbyPostsId = self.nearbyPostsId {
            Meteor.unsubscribe(withId: nearbyPostsId)
        }
        var dict = Dictionary<String, AnyObject>()
        dict["lat"] = lat
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
                NSUserDefaults.standardUserDefaults().setObject(Meteor.client.userId(), forKey: AccountHandler.USER_ID)
                self.loadAccount()
            } else {
                NSUserDefaults.standardUserDefaults().setObject(nil, forKey: AccountHandler.USER_ID)
            }
        }
    }
    
    public func loginFacebook(clientId: String, viewController: UIViewController){
        Meteor.loginWithFacebook(clientId, viewController: viewController)
    }
    
    public func logoff(callback: (success: Bool)-> Void){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(processLogoff), name: DDP_USER_DID_LOGOUT, object: nil)
        self.unregisterToken { (success) in
            if success{
                ConnectionHandler.Instance.users.logoff { (success) in
                    if !success {
                        //self.processLogoff()
                        NSNotificationCenter.defaultCenter().removeObserver(self, name: DDP_USER_DID_LOGOUT, object: nil)
                    }
                    
                    callback(success: success)
                }
            } else {
                callback(success: false)
            }
        }
    }
    
    public func getSavedUserId() -> String?{
        return NSUserDefaults.standardUserDefaults().objectForKey(AccountHandler.USER_ID) as? String
    }
    
    @objc public func processLogoff(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DDP_USER_DID_LOGOUT, object: nil)
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: AccountHandler.USER_ID)
        CachingHandler.deleteAllPrivateFiles()
        self.currentUser = nil
        self.myPosts = nil
        self.userId = nil
        self.myChats = nil
        
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
    
    public func isLoggedIn() -> Bool {
        return Meteor.client.userId() != nil
    }
    
    public func loadAccount(){
        self.resolvedDependencies = 0
        self.status = .Loading
        
        self.latestCallId += 1
        let callId = self.latestCallId
        
        if self.isLoggedIn(){
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
                        
                        //temp
                        self.myChats = self.myChats?.filter({$0.lastMessage != nil})
                        
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
                
                //temp
                self.myChats = self.myChats?.filter({$0.lastMessage != nil})
                
                self.processLocalNotifications()
                
                self.saveMyChats()
                NotificationManager.sendNotification(NotificationManager.Name.MyChatsUpdated, object: nil)
            }
            callback?(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
        })
    }
    
    private func processLocalNotifications(){
        self.myChats?.forEach({ (chat) in
            if !(chat.seen ?? true) {
                LocalNotificationsHandler.Instance.reportNewEvent(.Messages, id: chat.id)
            }
        })
    }
    
    private func handleCompleted(callId: Int){
        if callId == self.latestCallId && self.resolvedDependencies == self.totalDependencies {
            self.resolvedDependencies = 0
            self.status = .Completed
            
            NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
            
            self.processLocalNotifications()
        }
    }
    
    public func requestPushNotifications(){
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        let app = UIApplication.sharedApplication()
        app.registerForRemoteNotifications()
        app.registerUserNotificationSettings(settings)
    }
    
    public func savePushToken(callback: (success: Bool) -> Void){
        if let token = PushNotificationsHandler.getToken(), user = self.currentUser{
            //yes, doing it twice. thanks raix:push!
            self.savePushTokenRaix({ (success) in
                if success {
                    var dict = Dictionary<String, AnyObject>()
                    dict["token"] = token
                    dict["deviceId"] = SecurityHandler.getDeviceId()
                    dict["platform"] = "apn"
                    dict["userId"] = user.id
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
            })
            
        } else {
            callback(success: false)
        }
    }

    private func savePushTokenRaix(callback: (success: Bool) -> Void){
        if let token = PushNotificationsHandler.getToken(), user = self.currentUser{
            var dict = Dictionary<String, AnyObject>()
            var tokenDict = Dictionary<String, AnyObject>()
            tokenDict["apn"] = token
            dict["token"] = tokenDict
            dict["appName"] = "org.buzzar.app"
            dict["userId"] = user.id
            
            Meteor.call("raix:push-update", params: [dict], callback: { (result, error) in
                if error == nil, let fields = result as? NSDictionary, _ = fields.valueForKey("_id") as? String{
                    callback(success: true)
                    print("raix token update success")
                } else {
                    callback(success: false)
                    print ("raix token update failed")
                }
            })
        } else {
            callback(success: false)
        }
    }

    
    public func unregisterToken(callback: (success: Bool) -> Void){
        if let user = self.currentUser{
            var dict = Dictionary<String, AnyObject>()
            dict["deviceId"] = SecurityHandler.getDeviceId()
            dict["platform"] = "apn"
            dict["userId"] = user.id
            
            Meteor.call("unregisterPushToken", params: [dict], callback: { (result, error) in
                if error == nil, let fields = result as? NSDictionary, success = fields.valueForKey("success") as? Bool{
                    callback(success: success)
                } else {
                    callback(success: false)
                }
            })
        } else {
            callback(success: false)
        }
        
        //callback(success: true)
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