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
        
        case MyChatsUpdated = "shiners:MyChatsUpdated"
        
        case NearbyPostsSubscribed = "shiners:NearbyPostsSubscribed"
        case NearbyPostAdded = "shiners:NearbyPostAdded"
        case NearbyPostRemoved = "shiners:NearbyPostRemoved"
        case NearbyPostModified = "shiners:NearbyPosrtModified"
        
        case MessagesNewSubscribed = "shiners:MessagesNewSubscribed"
        case MessageAdded = "shiners:MessageAdded"
        case MessageRemoved = "shiners:MessageRemoved"
        case MessageModified = "shiners:MessageModified"
        
        case MessagesAsyncRequestCompleted = "shiners:MessagesAsyncRequestCompleted"
        
        case ChatAdded = "shiners:ChatAdded"
    }
}
