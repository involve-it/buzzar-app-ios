//
//  NotificationManager.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class NotificationManager{
    open class func sendNotification(_ name: NotificationManager.Name, object: AnyObject?){
        NotificationCenter.default.post(name: Notification.Name(rawValue: name.rawValue), object: object)
    }
    
    public enum Name: String{
        case UserUpdated = "shiners:userUpdated"
        case MyPostsUpdated = "shiners:myPostsUpdated"
        case MyPostUpdated = "shiners:myPostUpdated"
        case NetworkUnreachable = "shiners:networkUnrechable"
        case NetworkReachable = "shiners:networkReachable"
        case MeteorConnected = "shiners:meteorConnected"
        case MeteorNetworkConnected = "shiners:meteorNetworkConnected"
        case OfflineCacheRestored = "shiners:offlineCacheRestored"
        case AccountUpdated = "shiners:AccountUpdated"
        case AccountLoaded = "shiners:AccountLoaded"
        case MeteorConnectionFailed = "shiners:MeteorConnectionFailed"
        
        case MyChatsUpdated = "shiners:MyChatsUpdated"
        
        case NearbyPostsSubscribed = "shiners:NearbyPostsSubscribed"
        case NearbyPostAdded = "shiners:NearbyPostAdded"
        case NearbyPostRemoved = "shiners:NearbyPostRemoved"
        case NearbyPostModified = "shiners:NearbyPostModified"
        case NearbyPostsUpdated = "shiners:NearbyPostsUpdated"
        
        case MessagesNewSubscribed = "shiners:MessagesNewSubscribed"
        case MessageAdded = "shiners:MessageAdded"
        case MessageRemoved = "shiners:MessageRemoved"
        //case MessageModified = "shiners:MessageModified"
        
        case MessagesAsyncRequestCompleted = "shiners:MessagesAsyncRequestCompleted"
        case CommentsAsyncRequestCompleted = "shiners:CommentsAsyncRequestCompleted"
        
        case PostCommentsUpdated = "shiners:PostCommentsUpdated"
        //case PostCommentAddedLocally = "shiners:PostCommentAddedLocally"
        
        case CommentsMySubscribed = "shiners:CommentsMySubscribed"
        case CommentAdded = "shiners:CommentAdded"
        case CommentRemoved = "shiners:CommentRemoved"
        case CommentUpdated = "shiners:CommentUpdated"
        
        case CommentsForPostSubscribed = "shiners:CommentsForPostSubscribed"
        //case MyCommentAdded = "shiners:MyCommentAdded"
        //case MyCommentRemoved = "shiners:MyCommentRemoved"
        
        //case ChatAdded = "shiners:ChatAdded"
        
        case PushRegistrationFailed = "shiners:PushRegistrationFailed"
        
        case NewPostLocationReported = "shiners:NewPostLocationReported"
        
        case ServerEventNotification = "shiners:ServerEventNotification"
        
        case PostUpdated = "shiners:PostUpdated"
        
        case DisplaySettings = "shiners:DisplaySettings"
        case DisplayProfile = "shiners:DisplayProfile"
        case DisplayPost = "shiners:DisplayPost"
    }
}
