//
//  PostsCollection.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

open class PostsCollection:AbstractCollection{
    var subscribing = false
    open var posts = [Post]()
    
    init() {
        super.init(name: "posts");
    }
    
    override open func documentWasAdded(_ collection: String, id: String, fields: NSDictionary?) {
        let post = Post(id: id, fields: fields)
        self.posts.append(post)
        if !subscribing {
            NotificationManager.sendNotification(NotificationManager.Name.NearbyPostAdded, object: post)
        }
    }
    
    override open func documentWasRemoved(_ collection: String, id: String) {
        guard subscribing == false else { return }
        if let index = self.posts.index(where: {post in return post.id == id}){
            self.posts.remove(at: index)
            if !subscribing {
                NotificationManager.sendNotification(NotificationManager.Name.NearbyPostRemoved, object: id as AnyObject?)
            }
        }
    }
    
    override open func documentWasChanged(_ collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.posts.index(where: {post in return post.id == id}){
            let post = self.posts[index];
            post.update(fields);
            if !subscribing {
                NotificationManager.sendNotification(NotificationManager.Name.NearbyPostModified, object: post)
            }
        }
    }
    
    open func count() -> Int{
        return posts.count;
    }
    
    open func itemAtIndex(_ index: Int) -> Post{
        return posts[index];
    }
}
