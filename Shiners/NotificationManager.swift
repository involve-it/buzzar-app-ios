//
//  NotificationManager.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class NotificationManager{
    public class func sendNotification(name: NotificationManager.Name, object: AnyObject?){
        NSNotificationCenter.defaultCenter().postNotificationName(name.rawValue, object: object)
    }
    
    public enum Name: String{
        case UserUpdated = "shiners:userUpdated"
        case MyPostsUpdated = "shiners:myPostsUpdated"
        case NetworkUnreachable = "shiners:networkUnrechable"
        case NetworkReachable = "shiners:networkReachable"
        case MeteorConnected = "shiners:meteorConnected"
        case OfflineCacheRestored = "shiners:offlineCacheRestored"
        case AccountUpdated = "shiners:AccountUpdated"
        case NearbyPostsSubscribed = "shiners:NearbyPostsSubscribed"
    }
}
