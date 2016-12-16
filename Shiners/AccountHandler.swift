//
//  AccountHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/21/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


open class AccountHandler{
    fileprivate static let USER_ID = "shiners:userId"
    fileprivate let totalDependencies = 5
    fileprivate var resolvedDependencies = 0
    fileprivate var latestCallId = 0
    
    open fileprivate(set) var status:Status = .notInitialized;
    
    open var myChats: [Chat]?
    open fileprivate(set) var myPosts: [Post]?
    open fileprivate(set) var currentUser: User?
    open fileprivate(set) var userId: String?
    open var allUsers = [User]()
    
    open var postsCollection = PostsCollection()
    fileprivate var nearbyPostsId: String?
    
    var messagesCollection = MessagesCollection()
    fileprivate var messagesId: String?
    
    var commentsCollection = CommentsCollection()
    fileprivate var commentsId: String?
    fileprivate var commentsForPostId: String?
    
    fileprivate var lastLocationReport: Date?
    //2 minutes
    fileprivate static let LOCATION_REPORT_INTEVAL_SECONDS = 2 * 60.0
    
    open static let NEARBY_POSTS_PAGE_SIZE = 50
    fileprivate static let NEARBY_POSTS_COLLECTION_RADIUS = 5
    
    fileprivate static let SEEN_WELCOME_SCREEN = "shiners:seen-welcome-screen"
    
    class func hasSeenWelcomeScreen() -> Bool{
        let defaults = UserDefaults.standard
        return (defaults.value(forKey: AccountHandler.SEEN_WELCOME_SCREEN) as? Bool) ?? false
    }
    
    class func setSeenWelcomeScreen(_ seen: Bool){
        let defaults = UserDefaults.standard
        defaults.set(seen, forKey: AccountHandler.SEEN_WELCOME_SCREEN)
    }
    
    func subscribeToCommentsForPost(_ id: String) -> String {
        if let commentsForPostId = self.commentsForPostId {
            Meteor.unsubscribe(withId: commentsForPostId)
        }
        self.commentsForPostId = Meteor.subscribe("comments-post", params: [id]) {
            print ("subscribed for comments for post id: \(id)")
            NotificationManager.sendNotification(NotificationManager.Name.CommentsForPostSubscribed, object: id as AnyObject?)
        }
        return self.commentsForPostId!
    }
    
    func unsubscribeFromCommentsForPost(_ subscriptionId: String){
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
    
    func subscribe(_ callId: Int){
        Logger.log("loadAccount: subscribe")
        self.subscribeToNewMessages(callId)
        self.subscribeToNewComments(callId)
    }
    
    func subscribeToNewMessages(_ callId: Int){
        if let messagesId = self.messagesId {
            Meteor.unsubscribe(withId: messagesId)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(saveMyChats), name: NSNotification.Name(rawValue: NotificationManager.Name.MessageAdded.rawValue), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(saveMyChats), name: NSNotification.Name(rawValue: NotificationManager.Name.MessageRemoved.rawValue), object: nil)
        }
        self.messagesId = Meteor.subscribe("messages-new") {
            Logger.log("loadAccount: susbcribeToNewMessages callback")
            NSLog("messages-new subscribed");
            self.resolvedDependencies += 1
            self.handleCompleted(callId)
            NotificationManager.sendNotification(NotificationManager.Name.MessagesNewSubscribed, object: nil)
        }
    }
    
    func subscribeToNewComments(_ callId: Int){
        if let commentsId = self.commentsId {
            Meteor.unsubscribe(withId: commentsId)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(savePosts), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentAdded.rawValue), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(savePosts), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentRemoved.rawValue), object: nil)
        }
        self.commentsId = Meteor.subscribe("comments-my") {
            Logger.log("loadAccount: susbcribeToNewComments callback")
            print("comments-my subscribed")
            self.resolvedDependencies += 1
            self.handleCompleted(callId)
            NotificationManager.sendNotification(NotificationManager.Name.CommentsMySubscribed, object: nil)
        }
    }
    
    @objc func savePosts(_ notification: Notification){
        if self.status == .completed, let comment = notification.object as? Comment {
            if let _ = self.myPosts?.index(where: {$0.id == comment.entityId}){
                CachingHandler.Instance.savePostsMy(self.myPosts!)
            }
        }
    }
    
    @objc open func saveMyChats(){
        if let cachedChats = CachingHandler.Instance.chats, let myChats = self.myChats {
            myChats.forEach({ (chat) in
                if chat.messages.count == 0, let cachedIndex = cachedChats.index(where: {$0.id == chat.id!}) {
                    let cachedChat = cachedChats[cachedIndex]
                    if cachedChat.messages.count > 0 {
                        chat.messages = cachedChat.messages
                    }
                }
            })
        }
        if self.status == .completed {
            CachingHandler.Instance.saveChats(self.myChats!)
        }
    }
    
    func sortNearbyPosts(_ posts: [Post]) -> [Post] {
        let sorted = posts.sorted(by: { (post1, post2) -> Bool in
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
    
    open func mergeNewUsers(_ users: [User]){
        users.forEach { (user) in
            if let index = self.allUsers.index(where: {$0.id == user.id}) {
                self.allUsers.remove(at: index)
            }
            self.allUsers.append(user)
        }
    }
    
    open func getNearbyPosts(_ lat: Double, lng: Double, radius: Double, skip: Int, take: Int, callback: @escaping MeteorMethodCallback){
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
                callback(success, errorId, errorMessage, posts)
            } else {
                callback(success, errorId, errorMessage, result)
            }
        }
    }
    
    open func subscribeToNearbyPosts(_ lat: Double, lng: Double){
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
        dict["lat"] = lat as AnyObject?
        dict["lng"] = lng as AnyObject?
        dict["radius"] = AccountHandler.NEARBY_POSTS_COLLECTION_RADIUS as AnyObject?
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
    
    open func register(_ user: RegisterUser, callback: @escaping MeteorMethodCallback){
        ConnectionHandler.Instance.users.register(user, callback: callback)
    }
    
    open func login(_ userName: String, password: String, callback: @escaping MeteorMethodCallback){
        ConnectionHandler.Instance.users.login(userName, password: password) { (success, errorId, errorMessage, result) in
            self.lastLocationReport = nil
            callback(success, errorId, errorMessage, result)
            if (success){
                UserDefaults.standard.set(Meteor.client.userId(), forKey: AccountHandler.USER_ID)
                self.loadAccount()
            } else {
                UserDefaults.standard.set(nil, forKey: AccountHandler.USER_ID)
            }
        }
    }
    
    open func loginFacebook(_ clientId: String, viewController: UIViewController){
        Meteor.loginWithFacebook(clientId, viewController: viewController)
    }
    
    open func logoff(_ callback: @escaping (_ success: Bool)-> Void){
        NotificationCenter.default.addObserver(self, selector: #selector(processLogoff), name: NSNotification.Name(rawValue: DDP_USER_DID_LOGOUT), object: nil)
        self.unregisterToken { (success) in
            if success{
                ConnectionHandler.Instance.users.logoff { (success) in
                    if !success {
                        //self.processLogoff()
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DDP_USER_DID_LOGOUT), object: nil)
                    }
                    
                    callback(success)
                }
            } else {
                callback(false)
            }
        }
    }
    
    open func getSavedUserId() -> String?{
        return UserDefaults.standard.object(forKey: AccountHandler.USER_ID) as? String
    }
    
    @objc open func processLogoff(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DDP_USER_DID_LOGOUT), object: nil)
        UserDefaults.standard.set(nil, forKey: AccountHandler.USER_ID)
        CachingHandler.deleteAllPrivateFiles()
        self.currentUser = nil
        self.myPosts = nil
        self.userId = nil
        self.myChats = nil
        self.lastLocationReport = nil
        
        NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
    }

    
    open func saveUser(_ user: User, callback: @escaping (_ success: Bool, _ errorMessage: String?) -> Void){
        ConnectionHandler.Instance.users.saveUser(user) { (success, errorId, errorMessage, result) in
            if errorId == nil {
                self.currentUser = user
                CachingHandler.Instance.saveCurrentUser(self.currentUser!)
                
                NotificationManager.sendNotification(.UserUpdated, object: nil)
                
            }
            
            callback(success, errorMessage)
        }
    }
    
    open func isLoggedIn() -> Bool {
        return Meteor.client.userId() != nil
    }
    
    open func loadAccount(){
        self.resolvedDependencies = 0
        self.status = .loading
        
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
    
    open func updateMyPosts(_ callback: MeteorMethodCallback? = nil){
        ConnectionHandler.Instance.posts.getMyPosts(0, take: 1000, callback: { (success, errorId, errorMessage, result) in
            if success {
                self.myPosts = result as? [Post]
                
                CachingHandler.Instance.savePostsMy(self.myPosts!)
                NotificationManager.sendNotification(.MyPostsUpdated, object: nil)
            }
            callback?(success, errorId, errorMessage, result)
        })
    }
    
    open func updateMyChats(_ callback: MeteorMethodCallback? = nil){
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
            callback?(success, errorId, errorMessage, result)
        })
    }
    
    fileprivate func restoreCachedMessages(){
        if CachingHandler.Instance.status == .complete, let cachedChats = CachingHandler.Instance.chats {
            self.myChats?.filter({$0.messages.count == 0}).forEach({ (chat) in
                if let cachedChatIndex = cachedChats.index(where: {$0.id! == chat.id!}){
                    let cachedChat = cachedChats[cachedChatIndex]
                    chat.messages = cachedChat.messages
                }
            })
        }
    }
    
    open func reportLocation(_ lat: Double, lng: Double, callback: MeteorMethodCallback? = nil){
        CachingHandler.Instance.saveLastLocation(lat, lng: lng)
        if AccountHandler.Instance.status == .completed && self.isLoggedIn() && (self.lastLocationReport == nil || Date().timeIntervalSince(self.lastLocationReport!) >= AccountHandler.LOCATION_REPORT_INTEVAL_SECONDS){
            var dict = Dictionary<String, AnyObject>()
            dict["lat"] = lat as AnyObject?
            dict["lng"] = lng as AnyObject?
            dict["deviceId"] = SecurityHandler.getDeviceId() as AnyObject?
            Meteor.call("reportLocation", params: [dict]) { (result, error) in
                if error == nil {
                    self.lastLocationReport = NSDate() as Date
                    callback?(true, nil, nil, nil)
                } else {
                    print("Error reporting location")
                    print(error!.error)
                    callback?(false, nil, nil, nil)
                }
                
            }
        } else {
            callback?(true, nil, nil, nil)
        }
    }
    
    func processLocalNotifications(){
        LocalNotificationsHandler.Instance.reportEventSeen(.messages)
        self.myChats?.forEach({ (chat) in
            if !(chat.seen ?? true) && chat.toUserId == self.userId{
                LocalNotificationsHandler.Instance.reportNewEvent(.messages, id: chat.id)
            }
        })
    }
    
    let lockQueue = DispatchQueue(label: "handleCompletedLock", attributes: [])
    fileprivate func handleCompleted(_ callId: Int){
        Logger.log("loadAccount: handleCompleted. count: \(self.resolvedDependencies), total: \(self.totalDependencies)")
        lockQueue.sync{
            if callId == self.latestCallId && self.resolvedDependencies == self.totalDependencies {
                Logger.log("handleCompleted: account loaded")
                print("account loaded")
                self.resolvedDependencies = 0
                self.status = .completed
                
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
    
    open func requestPushNotifications(){
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        let app = UIApplication.shared
        app.registerForRemoteNotifications()
        app.registerUserNotificationSettings(settings)
        if let _ = PushNotificationsHandler.getToken() {
            self.savePushToken { (success) in
                if !success {
                    UIApplication.shared.unregisterForRemoteNotifications()
                    NotificationManager.sendNotification(NotificationManager.Name.PushRegistrationFailed, object: nil)
                }
            }
        }
    }
    
    open func savePushToken(_ callback: @escaping (_ success: Bool) -> Void){
        if let token = PushNotificationsHandler.getToken(), let user = self.currentUser{
            //yes, doing it twice. thanks raix:push!
            self.savePushTokenRaix({ (success) in
                if success {
                    var dict = Dictionary<String, AnyObject>()
                    dict["token"] = token as AnyObject?
                    dict["deviceId"] = SecurityHandler.getDeviceId() as AnyObject?
                    dict["platform"] = "apn" as AnyObject?
                    dict["userId"] = user.id as AnyObject?
                    Meteor.call("registerPushToken", params: [dict], callback: { (result, error) in
                        if error == nil, let fields = result as? NSDictionary, let success = fields.value(forKey: "success") as? Bool{
                            callback(success)
                        } else {
                            callback(false)
                        }
                    })
                } else {
                    callback(false)
                }
            })
            
        } else {
            callback(false)
        }
    }

    fileprivate func savePushTokenRaix(_ callback: @escaping (_ success: Bool) -> Void){
        if let token = PushNotificationsHandler.getToken(), let user = self.currentUser{
            var dict = Dictionary<String, AnyObject>()
            var tokenDict = Dictionary<String, AnyObject>()
            tokenDict["apn"] = token as AnyObject?
            dict["token"] = tokenDict as AnyObject?
            dict["appName"] = "org.buzzar.app" as AnyObject?
            dict["userId"] = user.id as AnyObject?
            
            Meteor.call("raix:push-update", params: [dict], callback: { (result, error) in
                if error == nil, let fields = result as? NSDictionary, let _ = fields.value(forKey: "_id") as? String{
                    callback(true)
                    print("raix token update success")
                } else {
                    callback(false)
                    print ("raix token update failed")
                }
            })
        } else {
            callback(false)
        }
    }

    
    open func unregisterToken(_ callback: @escaping (_ success: Bool) -> Void){
        if let user = self.currentUser{
            var dict = Dictionary<String, AnyObject>()
            dict["deviceId"] = SecurityHandler.getDeviceId() as AnyObject?
            dict["platform"] = "apn" as AnyObject?
            dict["userId"] = user.id as AnyObject?
            
            Meteor.call("unregisterPushToken", params: [dict], callback: { (result, error) in
                if error == nil, let fields = result as? NSDictionary, let success = fields.value(forKey: "success") as? Bool{
                    callback(success)
                } else {
                    callback(false)
                }
            })
        } else {
            callback(false)
        }
        
        //callback(success: true)
    }
    
    fileprivate init (){}
    fileprivate static let instance = AccountHandler()
    open static var Instance: AccountHandler {
        get{
            return instance
        }
    }
    
    public enum Status{
        case notInitialized, loading, completed
    }
}
