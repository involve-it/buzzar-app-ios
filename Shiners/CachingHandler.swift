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
    
    class func saveObject(obj: AnyObject, path: String) -> Bool{
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
        return deleteFile(postsAll) && deleteFile(postsMy) && deleteFile(currentUser)
    }
    
    class func deleteAllPrivateFiles() -> Bool {
        return deleteFile(postsMy) && deleteFile(currentUser)
    }
    
    func restoreAllOfflineData(){
        ThreadHelper.runOnBackgroundThread {
            do {
                try self.postsAll = CachingHandler.loadObjects(CachingHandler.postsAll)
                try self.postsMy = CachingHandler.loadObjects(CachingHandler.postsMy)
                try self.currentUser = CachingHandler.loadObject(CachingHandler.currentUser)
                
                self.status = .Complete
            }
            catch{
                NSLog("Error occurred while restoring cache. Clearing all cache.")
                self.postsAll = nil
                self.postsMy = nil
                self.currentUser = nil
                
                CachingHandler.deleteAllFiles()
            }
            
            NotificationManager.sendNotification(.OfflineCacheRestored, object: nil)
        }
    }
    
    var status = Status.NotStarted
    
    var postsAll: [Post]?
    var postsMy: [Post]?
    var currentUser: User?
    
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