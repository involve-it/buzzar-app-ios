//
//  CachingHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/15/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import CoreLocation

class CachingHandler{
    fileprivate static let documentDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static let postsAll = "postsall"
    static let postsMy = "postsmy"
    static let currentUser = "currentuser"
    static let chats = "chats"
    static let seenPostIds = "seenPostIds"
    static let todaySeenPostIds = "todaySeenPostIds"
    static let lastSeenPostIdReport = "lastSeenPostIdReport"
    static let lastLocation = "lastLocation"
    
    fileprivate class func saveObject(_ obj: AnyObject, path: String) -> Bool{
        let archiveUrl = documentDirectory.appendingPathComponent(path)
        return NSKeyedArchiver.archiveRootObject(obj, toFile: archiveUrl.path)
    }
    
    class func loadObjects<T>(_ path: String) throws -> [T]? {
        let archiveUrl = documentDirectory.appendingPathComponent(path)
        return NSKeyedUnarchiver.unarchiveObject(withFile: archiveUrl.path) as? [T]
    }
    
    class func loadObject<T>(_ path: String) throws -> T? {
        let archiveUrl = documentDirectory.appendingPathComponent(path)
        return NSKeyedUnarchiver.unarchiveObject(withFile: archiveUrl.path) as? T
    }
    
    class func deleteFile(_ path: String) -> Bool{
        let archiveUrl = documentDirectory.appendingPathComponent(path)
        if FileManager.default.isDeletableFile(atPath: archiveUrl.path){
            do{
                try FileManager.default.removeItem(atPath: archiveUrl.path)
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
                try self.lastLocation = CachingHandler.loadObject(CachingHandler.lastLocation)
                
                if LocationHandler.lastLocation == nil, let lastLocation = CachingHandler.Instance.lastLocation {
                    let location = CLLocation(latitude: lastLocation[0], longitude: lastLocation[1])
                    LocationHandler.lastLocation = location
                }
                
                self.status = .complete
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
    
    var status = Status.notStarted
    
    var postsAll: [Post]?
    var postsMy: [Post]?
    var currentUser: User?
    var chats: [Chat]?
    var seenPostIds: [String]?
    
    var todaySeenPostIds: [String]?
    var lastSeenPostIdReport: Date?
    var lastLocation: [Double]?
    
    func savePostsAll(_ posts: [Post]) -> Bool{
        if self.status == .complete && CachingHandler.saveObject(posts as AnyObject, path: CachingHandler.postsAll) {
            self.postsAll = posts
            return true
        }
        return false
    }
    
    func savePostsMy(_ posts: [Post]) -> Bool{
        if self.status == .complete && CachingHandler.saveObject(posts as AnyObject, path: CachingHandler.postsMy) {
            self.postsMy = posts
            return true
        }
        return false
    }
    
    func saveCurrentUser(_ user: User) -> Bool{
        if self.status == .complete && CachingHandler.saveObject(user, path: CachingHandler.currentUser) {
            self.currentUser = user
            return true
        }
        return false
    }
    
    func saveChats(_ chats: [Chat]) -> Bool{
        if self.status == .complete && CachingHandler.saveObject(chats as AnyObject, path: CachingHandler.chats) {
            self.chats = chats
            return true
        }
        return false
    }
    
    func saveSeenPostIds(_ postIds: [String]) -> Bool{
        if self.status == .complete && CachingHandler.saveObject(postIds as AnyObject, path: CachingHandler.seenPostIds) {
            self.seenPostIds = postIds
            return true
        }
        return false
    }
    
    func saveTodaySeenPostIds(_ postIds: [String]) -> Bool {
        if self.status == .complete && CachingHandler.saveObject(postIds as AnyObject, path: CachingHandler.todaySeenPostIds) {
            self.todaySeenPostIds = postIds
            self.lastSeenPostIdReport = Date()
            CachingHandler.saveObject(self.lastSeenPostIdReport! as AnyObject, path: CachingHandler.lastSeenPostIdReport)
            return true
        }
        return false
    }
    
    func saveLastLocation(_ lat: Double, lng: Double) -> Bool {
        let lastLocation = [lat ,lng]
        if self.status == .complete && CachingHandler.saveObject(lastLocation as AnyObject, path: CachingHandler.lastLocation) {
            self.lastLocation = lastLocation
            return true
        }
        return false
    }
    
    fileprivate init(){}
    fileprivate static let instance = CachingHandler()
    class var Instance: CachingHandler {
        get {
            return instance
        }
    }
    
    enum Status{
        case notStarted, complete
    }
}
