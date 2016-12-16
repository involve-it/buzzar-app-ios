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
    
    override func documentWasAdded(_ collection: String, id: String, fields: NSDictionary?) {
        let comment = Comment(id: id, fields: fields)
        self.comments.append(comment)
        
        if let index = AccountHandler.Instance.allUsers.index(where: {$0.id == comment.userId!}){
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
        
        if let myPostIndex = AccountHandler.Instance.myPosts?.index(where: {$0.id == comment.entityId}), let post = AccountHandler.Instance.myPosts?[myPostIndex]{
            post.comments.insert(comment, at: 0)
            if comment.userId != AccountHandler.Instance.userId {
                LocalNotificationsHandler.Instance.reportNewEvent(.myPosts, count: 1, id: comment.entityId, messageTitle: "New comment on your post from \(comment.username ?? "Unknown")", messageSubtitle: (comment.text?.shortMessageForNotification() ?? ""))
            }
        }
        NotificationManager.sendNotification(NotificationManager.Name.CommentAdded, object: comment)
    }
    
    override func documentWasRemoved(_ collection: String, id: String) {
        if let index = self.comments.index(where: {$0.id == id}) {
            let comment = self.comments[index]
            self.comments.remove(at: index)
            if let myPostIndex = AccountHandler.Instance.myPosts?.index(where: {$0.id == comment.entityId}), let post = AccountHandler.Instance.myPosts?[myPostIndex], let commentIndex = post.comments.index(where: {$0.id == id}){
                post.comments.remove(at: commentIndex)
            }
            NotificationManager.sendNotification(NotificationManager.Name.CommentRemoved, object: comment)
        }
    }
    
    override func documentWasChanged(_ collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.comments.index(where: {$0.id == id}) {
            let comment = self.comments[index]
            comment.update(fields)
            comment.id = id
            
            NotificationManager.sendNotification(NotificationManager.Name.CommentUpdated, object: comment)
        }
    }
}
