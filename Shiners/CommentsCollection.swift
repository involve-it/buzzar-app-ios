//
//  CommentsCollection.swift
//  Shiners
//
//  Created by Yury Dorofeev on 11/27/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

class CommentsCollection: AbstractCollection {
    var comments = [Comment]()
    
    init(){
        super.init(name: "bz.reviews")
    }
    
    override func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        let comment = Comment(id: id, fields: fields)
        self.comments.append(comment)
        
        if let index = AccountHandler.Instance.allUsers.indexOf({$0.id == comment.userId!}){
            let user = AccountHandler.Instance.allUsers[index]
            comment.user = user
        } else {
            if ConnectionHandler.Instance.isNetworkConnected() {
                print ("loading user id: \(comment.userId!)")
                ConnectionHandler.Instance.users.getUser(comment.userId!, callback: { (success, errorId, errorMessage, result) in
                    if success {
                        comment.user = result as? User
                        AccountHandler.Instance.mergeNewUsers([comment.user!])
                        NotificationManager.sendNotification(NotificationManager.Name.CommentUpdated, object: comment)
                    }
                })
            }
        }
        
        if let myPostIndex = AccountHandler.Instance.myPosts?.indexOf({$0.id == comment.entityId}), post = AccountHandler.Instance.myPosts?[myPostIndex]{
            post.comments.append(comment)
            if comment.userId != AccountHandler.Instance.userId {
                LocalNotificationsHandler.Instance.reportNewEvent(.MyPosts, count: 1, id: comment.entityId, messageTitle: "New comment on your post from \(comment.username ?? "Unknown")", messageSubtitle: (comment.text?.shortMessageForNotification() ?? ""))
            }
        }
        NotificationManager.sendNotification(NotificationManager.Name.CommentAdded, object: comment)
    }
    
    override func documentWasRemoved(collection: String, id: String) {
        if let index = self.comments.indexOf({$0.id == id}) {
            let comment = self.comments[index]
            self.comments.removeAtIndex(index)
            if let myPostIndex = AccountHandler.Instance.myPosts?.indexOf({$0.id == comment.entityId}), post = AccountHandler.Instance.myPosts?[myPostIndex], commentIndex = post.comments.indexOf({$0.id == id}){
                post.comments.removeAtIndex(commentIndex)
            }
            NotificationManager.sendNotification(NotificationManager.Name.CommentRemoved, object: comment)
        }
    }
    
    override func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.comments.indexOf({$0.id == id}) {
            let comment = self.comments[index]
            comment.update(fields)
            comment.id = id
            
            NotificationManager.sendNotification(NotificationManager.Name.CommentUpdated, object: comment)
        }
    }
}