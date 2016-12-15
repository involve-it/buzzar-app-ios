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
    private let totalDependencies = 5
    private var resolvedDependencies = 0
    private var latestCallId = 0
    
    public private(set) var status:Status = .NotInitialized;
    
    public var myChats: [Chat]?
    public private(set) var myPosts: [Post]?
    public private(set) var currentUser: User?
    public private(set) var userId: String?
    public var allUsers = [User]()
    
    public var postsCollection = PostsCollection()
    private var nearbyPostsId: String?
    
    var messagesCollection = MessagesCollection()
    private var messagesId: String?
    
    var commentsCollection = CommentsCollection()
    private var commentsId: String?
    private var commentsForPostId: String?
    
    private var lastLocationReport: NSDate?
    //2 minutes
    private static let LOCATION_REPORT_INTEVAL_SECONDS = 2 * 60.0
    
    public static let NEARBY_POSTS_PAGE_SIZE = 50
    private static let NEARBY_POSTS_COLLECTION_RADIUS = 5
    
    private static let SEEN_WELCOME_SCREEN = "shiners:seen-welcome-screen"
    
    class func hasSeenWelcomeScreen() -> Bool{
        let defaults = NSUserDefaults.standardUserDefaults()
        return (defaults.valueForKey(AccountHandler.SEEN_WELCOME_SCREEN) as? Bool) ?? false
    }
    
    class func setSeenWelcomeScreen(seen: Bool){
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(seen, forKey: AccountHandler.SEEN_WELCOME_SCREEN)
    }
    
    func subscribeToCommentsForPost(id: String) -> String {
        if let commentsForPostId = self.commentsForPostId {
            Meteor.unsubscribe(withId: commentsForPostId)
        }
        self.commentsForPostId = Meteor.subscribe("comments-post", params: [id]) {
            print ("subscribed for comments for post id: \(id)")
            NotificationManager.sendNotification(NotificationManager.Name.CommentsForPostSubscribed, object: id)
        }
        return self.commentsForPostId!
    }
    
    func unsubscribeFromCommentsForPost(subscriptionId: String){
        if self.commentsForPostId == subscriptionId {
            Meteor.unsubscribe(withId: subscriptionId)
            self.commentsForPostId = nil
        }
    }
    
    func unsubscribeFromCommentsForPost(){
        if let subscrptionId = self.commentsForPostId {
            Meteor.unsubscribe(withId: subscrptionId)
            self.commentsForPostId = nil
        }
    }
    
    func subscribe(callId: Int){
        Logger.log("loadAccount: subscribe")
        self.subscribeToNewMessages(callId)
        self.subscribeToNewComments(callId)
    }
    
    func subscribeToNewMessages(callId: Int){
        if let messagesId = self.messagesId {
            Meteor.unsubscribe(withId: messagesId)
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(saveMyChats), name: NotificationManager.Name.MessageAdded.rawValue, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(saveMyChats), name: NotificationManager.Name.MessageRemoved.rawValue, object: nil)
        }
        self.messagesId = Meteor.subscribe("messages-new") {
            Logger.log("loadAccount: susbcribeToNewMessages callback")
            NSLog("messages-new subscribed");
            self.resolvedDependencies += 1
            self.handleCompleted(callId)
            NotificationManager.sendNotification(NotificationManager.Name.MessagesNewSubscribed, object: nil)
        }
    }
    
    func subscribeToNewComments(callId: Int){
        if let commentsId = self.commentsId {
            Meteor.unsubscribe(withId: commentsId)
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(savePosts), name: NotificationManager.Name.CommentAdded.rawValue, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(savePosts), name: NotificationManager.Name.CommentRemoved.rawValue, object: nil)
        }
        self.commentsId = Meteor.subscribe("comments-my") {
            Logger.log("loadAccount: susbcribeToNewComments callback")
            print("comments-my subscribed")
            self.resolvedDependencies += 1
            self.handleCompleted(callId)
            NotificationManager.sendNotification(NotificationManager.Name.CommentsMySubscribed, object: nil)
        }
    }
    
    @objc func savePosts(notification: NSNotification){
        if self.status == .Completed, let comment = notification.object as? Comment {
            if let _ = self.myPosts?.indexOf({$0.id == comment.entityId}){
                CachingHandler.Instance.savePostsMy(self.myPosts!)
            }
        }
    }
    
    @objc public func saveMyChats(){
        if let cachedChats = CachingHandler.Instance.chats, myChats = self.myChats {
            myChats.forEach({ (chat) in
                if chat.messages.count == 0, let cachedIndex = cachedChats.indexOf({$0.id == chat.id!}) {
                    let cachedChat = cachedChats[cachedIndex]
                    if cachedChat.messages.count > 0 {
                        chat.messages = cachedChat.messages
                    }
                }
            })
        }
        if self.status == .Completed {
            CachingHandler.Instance.saveChats(self.myChats!)
        }
    }
    
    func sortNearbyPosts(posts: [Post]) -> [Post] {
        let sorted = posts.sort({ (post1, post2) -> Bool in
            if post1.isLive() && !post2.isLive() {
                return true
            }
            if post2.isLive() && !post1.isLive() {
                return false
            }
            if post1.isLive() == post2.isLive(){
                if let currentLocation = LocationHandler.lastLocation {
                    return post1.getDistance(currentLocation) < post2.getDistance(currentLocation)
                } else {
                    return true
                }
            }
            return false
        })
        return sorted
    }
    
    public func mergeNewUsers(users: [User]){
        users.forEach { (user) in
            if let index = self.allUsers.indexOf({$0.id == user.id}) {
                self.allUsers.removeAtIndex(index)
            }
            self.allUsers.append(user)
        }
    }
    
    public func getNearbyPosts(lat: Double, lng: Double, radius: Double, skip: Int, take: Int, callback: MeteorMethodCallback){
        ConnectionHandler.Instance.posts.getNearbyPosts(lat, lng: lng, radius: radius, skip: skip, take: take){ (success, errorId, errorMessage, result) in
            if success {
                var posts = result as! [Post]
                posts = self.sortNearbyPosts(posts)
                let users = posts.map({ (post) -> User in
                    return post.user!
                })
                self.mergeNewUsers(users)
                
                if posts.count <= AccountHandler.NEARBY_POSTS_PAGE_SIZE + 1 {
                    ThreadHelper.runOnBackgroundThread(){
                        if !CachingHandler.Instance.savePostsAll(posts){
                            NSLog("Unable to archive posts")
                        }
                    }
                }
                callback(success: success, errorId: errorId, errorMessage: errorMessage, result: posts)
            } else {
                callback(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
            }
        }
    }
    
    public func subscribeToNearbyPosts(lat: Double, lng: Double){
        self.postsCollection.subscribing = true
        var operationsCount = 1
        if let nearbyPostsId = self.nearbyPostsId {
            operationsCount += 1
            Meteor.unsubscribe(withId: nearbyPostsId) {
                operationsCount -= 1
                if operationsCount == 0 {
                    self.postsCollection.subscribing = false
                }
            }
        }
        
        var dict = Dictionary<String, AnyObject>()
        dict["lat"] = lat
        dict["lng"] = lng
        dict["radius"] = AccountHandler.NEARBY_POSTS_COLLECTION_RADIUS
        self.nearbyPostsId = Meteor.subscribe("posts-nearby-events", params: [dict]) {
            operationsCount -= 1
            if operationsCount == 0 {
                self.postsCollection.subscribing = false
            }
            //saving posts for offline use
            /*ThreadHelper.runOnBackgroundThread(){
                if !CachingHandler.Instance.savePostsAll(self.postsCollection.posts){
                    NSLog("Unable to archive posts")
                }
            }*/
            
            NSLog("posts-nearby subscribed");
            NotificationManager.sendNotification(NotificationManager.Name.NearbyPostsSubscribed, object: nil)
        }
    }
    
    public func register(user: RegisterUser, callback: MeteorMethodCallback){
        ConnectionHandler.Instance.users.register(user, callback: callback)
    }
    
    public func login(userName: String, password: String, callback: MeteorMethodCallback){
        ConnectionHandler.Instance.users.login(userName, password: password) { (success, errorId, errorMessage, result) in
            self.lastLocationReport = nil
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
        self.lastLocationReport = nil
        
        NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
    }

    
    public func saveUser(user: User, callback: (success: Bool, errorMessage: String?) -> Void){
        ConnectionHandler.Instance.users.saveUser(user) { (success, errorId, errorMessage, result) in
            if errorId == nil {
                self.currentUser = user
                CachingHandler.Instance.saveCurrentUser(self.currentUser!)
                
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
            self.subscribe(callId)
            Logger.log("loadAccount: invoke getCurrentUser")
            ConnectionHandler.Instance.users.getCurrentUser({ (success, errorId, errorMessage, result) in
                Logger.log("loadAccount: getCurrentUser callback")
                if (self.latestCallId == callId){
                    if (success){
                        self.currentUser = result as? User
                        
                        CachingHandler.Instance.saveCurrentUser(self.currentUser!)
                        NotificationManager.sendNotification(NotificationManager.Name.UserUpdated, object: nil)
                    } else {
                        NSLog("Error getting current user")
                    }
                    self.resolvedDependencies += 1
                    self.handleCompleted(callId)
                }
            })
            Logger.log("loadAccount: invoke getMyPosts")
            ConnectionHandler.Instance.posts.getMyPosts(0, take: 1000, callback: { (success, errorId, errorMessage, result) in
                Logger.log("loadAccount: getMyPosts callback")
                if self.latestCallId == callId {
                    if (success){
                        self.myPosts = result as? [Post]
                        
                        CachingHandler.Instance.savePostsMy(self.myPosts!)
                        
                        NotificationManager.sendNotification(.MyPostsUpdated, object: nil)
                    }
                    self.resolvedDependencies += 1
                    self.handleCompleted(callId)
                    if !success {
                        NSLog("Error loading my posts")
                    }
                }
            })
            Logger.log("loadAccount: invoke getChats")
            ConnectionHandler.Instance.messages.getChats(0, take: MessagesHandler.DEFAULT_PAGE_SIZE, callback: { (success, errorId, errorMessage, result) in
                Logger.log("loadAccount: getChats callback")
                if self.latestCallId == callId {
                    if (success){
                        self.myChats = result as? [Chat]
                        
                        //temp
                        self.myChats = self.myChats?.filter({$0.lastMessage != nil})
                        
                        self.restoreCachedMessages()
                        
                        CachingHandler.Instance.saveChats(self.myChats!)
                        
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
        ConnectionHandler.Instance.posts.getMyPosts(0, take: 1000, callback: { (success, errorId, errorMessage, result) in
            if success {
                self.myPosts = result as? [Post]
                
                CachingHandler.Instance.savePostsMy(self.myPosts!)
                NotificationManager.sendNotification(.MyPostsUpdated, object: nil)
            }
            callback?(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
        })
    }
    
    public func updateMyChats(callback: MeteorMethodCallback? = nil){
        ConnectionHandler.Instance.messages.getChats(0, take: MessagesHandler.DEFAULT_PAGE_SIZE, callback: { (success, errorId, errorMessage, result) in
            if success {
                self.myChats = result as? [Chat]
                
                //temp
                self.myChats = self.myChats?.filter({$0.lastMessage != nil})
                //restore cached messages
                self.restoreCachedMessages()
                
                self.processLocalNotifications()
                
                self.saveMyChats()
                NotificationManager.sendNotification(NotificationManager.Name.MyChatsUpdated, object: nil)
            }
            callback?(success: success, errorId: errorId, errorMessage: errorMessage, result: result)
        })
    }
    
    private func restoreCachedMessages(){
        if CachingHandler.Instance.status == .Complete, let cachedChats = CachingHandler.Instance.chats {
            self.myChats?.filter({$0.messages.count == 0}).forEach({ (chat) in
                if let cachedChatIndex = cachedChats.indexOf({$0.id! == chat.id!}){
                    let cachedChat = cachedChats[cachedChatIndex]
                    chat.messages = cachedChat.messages
                }
            })
        }
    }
    
    public func reportLocation(lat: Double, lng: Double, callback: MeteorMethodCallback? = nil){
        CachingHandler.Instance.saveLastLocation(lat, lng: lng)
        if AccountHandler.Instance.status == .Completed && self.isLoggedIn() && (self.lastLocationReport == nil || NSDate().timeIntervalSinceDate(self.lastLocationReport!) >= AccountHandler.LOCATION_REPORT_INTEVAL_SECONDS){
            var dict = Dictionary<String, AnyObject>()
            dict["lat"] = lat
            dict["lng"] = lng
            dict["deviceId"] = SecurityHandler.getDeviceId()
            Meteor.call("reportLocation", params: [dict]) { (result, error) in
                if error == nil {
                    self.lastLocationReport = NSDate()
                    callback?(success: true, errorId: nil, errorMessage: nil, result: nil)
                } else {
                    print("Error reporting location")
                    print(error!.error)
                    callback?(success: false, errorId: nil, errorMessage: nil, result: nil)
                }
                
            }
        } else {
            callback?(success: true, errorId: nil, errorMessage: nil, result: nil)
        }
    }
    
    func processLocalNotifications(){
        LocalNotificationsHandler.Instance.reportEventSeen(.Messages)
        self.myChats?.forEach({ (chat) in
            if !(chat.seen ?? true) && chat.toUserId == self.userId{
                LocalNotificationsHandler.Instance.reportNewEvent(.Messages, id: chat.id)
            }
        })
    }
    
    let lockQueue = dispatch_queue_create("handleCompletedLock", nil)
    private func handleCompleted(callId: Int){
        Logger.log("loadAccount: handleCompleted. count: \(self.resolvedDependencies), total: \(self.totalDependencies)")
        dispatch_sync(lockQueue){
            if callId == self.latestCallId && self.resolvedDependencies == self.totalDependencies {
                Logger.log("handleCompleted: account loaded")
                print("account loaded")
                self.resolvedDependencies = 0
                self.status = .Completed
                
                self.requestPushNotifications()
                
                NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
                NotificationManager.sendNotification(NotificationManager.Name.AccountLoaded, object: nil)
                
                /*if let location = LocationHandler.lastLocation {
                    self.reportLocation(location.coordinate.latitude, lng: location.coordinate.longitude)
                }*/
                
                self.processLocalNotifications()
            }
        }
    }
    
    public func requestPushNotifications(){
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        let app = UIApplication.sharedApplication()
        app.registerForRemoteNotifications()
        app.registerUserNotificationSettings(settings)
        if let _ = PushNotificationsHandler.getToken() {
            self.savePushToken { (success) in
                if !success {
                    UIApplication.sharedApplication().unregisterForRemoteNotifications()
                    NotificationManager.sendNotification(NotificationManager.Name.PushRegistrationFailed, object: nil)
                }
            }
        }
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