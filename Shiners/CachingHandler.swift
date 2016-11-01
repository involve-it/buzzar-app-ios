//
//  CachingHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/15/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class CachingHandler{
    private static let documentDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    
    static let postsAll = "postsall"
    static let postsMy = "postsmy"
    static let currentUser = "currentuser"
    static let chats = "chats"
    static let seenPostIds = "seenPostIds"
    static let todaySeenPostIds = "todaySeenPostIds"
    static let lastSeenPostIdReport = "lastSeenPostIdReport"
    
    private class func saveObject(obj: AnyObject, path: String) -> Bool{
        let archiveUrl = documentDirectory.URLByAppendingPathComponent(path)
        return NSKeyedArchiver.archiveRootObject(obj, toFile: archiveUrl.path!)
    }
    
    class func loadObjects<T>(path: String) throws -> [T]? {
        let archiveUrl = documentDirectory.URLByAppendingPathComponent(path)
        return NSKeyedUnarchiver.unarchiveObjectWithFile(archiveUrl.path!) as? [T]
    }
    
    class func loadObject<T>(path: String) throws -> T? {
        let archiveUrl = documentDirectory.URLByAppendingPathComponent(path)
        return NSKeyedUnarchiver.unarchiveObjectWithFile(archiveUrl.path!) as? T
    }
    
    class func deleteFile(path: String) -> Bool{
        let archiveUrl = documentDirectory.URLByAppendingPathComponent(path)
        if NSFileManager.defaultManager().isDeletableFileAtPath(archiveUrl.path!){
            do{
                try NSFileManager.defaultManager().removeItemAtPath(archiveUrl.path!)
                return true
            }
            catch {
                
            }
        }
        
        return false
    }
    
    class func deleteAllFiles() -> Bool {
        return deleteFile(postsAll) && deleteFile(postsMy) && deleteFile(currentUser) && deleteFile(chats) && deleteFile(seenPostIds) && deleteFile(todaySeenPostIds) && deleteFile(lastSeenPostIdReport)
    }
    
    class func deleteAllPrivateFiles() -> Bool {
        return deleteFile(postsMy) && deleteFile(currentUser) && deleteFile(chats) && deleteFile(seenPostIds) && deleteFile(todaySeenPostIds) && deleteFile(lastSeenPostIdReport)
    }
    
    func restoreAllOfflineData(){
        ThreadHelper.runOnBackgroundThread {
            do {
                try self.seenPostIds = CachingHandler.loadObjects(CachingHandler.seenPostIds)
                try self.postsAll = CachingHandler.loadObjects(CachingHandler.postsAll)
                try self.postsMy = CachingHandler.loadObjects(CachingHandler.postsMy)
                try self.currentUser = CachingHandler.loadObject(CachingHandler.currentUser)
                try self.chats = CachingHandler.loadObject(CachingHandler.chats)
                try self.todaySeenPostIds = CachingHandler.loadObject(CachingHandler.todaySeenPostIds)
                try self.lastSeenPostIdReport = CachingHandler.loadObject(CachingHandler.lastSeenPostIdReport)
                
                self.status = .Complete
            }
            catch{
                NSLog("Error occurred while restoring cache. Clearing all cache.")
                self.postsAll = nil
                self.postsMy = nil
                self.currentUser = nil
                self.chats = nil
                self.todaySeenPostIds = nil
                self.lastSeenPostIdReport = nil
                
                CachingHandler.deleteAllFiles()
            }
            
            NotificationManager.sendNotification(.OfflineCacheRestored, object: nil)
        }
    }
    
    var status = Status.NotStarted
    
    var postsAll: [Post]?
    var postsMy: [Post]?
    var currentUser: User?
    var chats: [Chat]?
    var seenPostIds: [String]?
    
    var todaySeenPostIds: [String]?
    var lastSeenPostIdReport: NSDate?
    
    func savePostsAll(posts: [Post]) -> Bool{
        if self.status == .Complete && CachingHandler.saveObject(posts, path: CachingHandler.postsAll) {
            self.postsAll = posts
            return true
        }
        return false
    }
    
    func savePostsMy(posts: [Post]) -> Bool{
        if self.status == .Complete && CachingHandler.saveObject(posts, path: CachingHandler.postsMy) {
            self.postsMy = posts
            return true
        }
        return false
    }
    
    func saveCurrentUser(user: User) -> Bool{
        if self.status == .Complete && CachingHandler.saveObject(user, path: CachingHandler.currentUser) {
            self.currentUser = user
            return true
        }
        return false
    }
    
    func saveChats(chats: [Chat]) -> Bool{
        if self.status == .Complete && CachingHandler.saveObject(chats, path: CachingHandler.chats) {
            self.chats = chats
            return true
        }
        return false
    }
    
    func saveSeenPostIds(postIds: [String]) -> Bool{
        if self.status == .Complete && CachingHandler.saveObject(postIds, path: CachingHandler.seenPostIds) {
            self.seenPostIds = postIds
            return true
        }
        return false
    }
    
    func saveTodaySeenPostIds(postIds: [String]) -> Bool {
        if self.status == .Complete && CachingHandler.saveObject(postIds, path: CachingHandler.todaySeenPostIds) {
            self.todaySeenPostIds = postIds
            self.lastSeenPostIdReport = NSDate()
            CachingHandler.saveObject(self.lastSeenPostIdReport!, path: CachingHandler.lastSeenPostIdReport)
            return true
        }
        return false
    }
    
    private init(){}
    private static let instance = CachingHandler()
    class var Instance: CachingHandler {
        get {
            return instance
        }
    }
    
    enum Status{
        case NotStarted, Complete
    }
}