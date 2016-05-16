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
    
    class func saveObjects(obj: AnyObject, path: String) -> Bool{
        let archiveUrl = documentDirectory.URLByAppendingPathComponent(path)
        return NSKeyedArchiver.archiveRootObject(obj, toFile: archiveUrl.path!)
    }
    
    class func loadObjects<T>(path: String) -> [T]? {
        let archiveUrl = documentDirectory.URLByAppendingPathComponent(path)
        return NSKeyedUnarchiver.unarchiveObjectWithFile(archiveUrl.path!) as? [T]
    }
}