//
//  PostsCollection.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class PostsCollection:AbstractCollection{
    var subscribing = false
    public var posts = [Post]()
    
    init() {
        super.init(name: "posts");
    }
    
    override public func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        let post = Post(id: id, fields: fields)
        self.posts.append(post)
        if !subscribing {
            NotificationManager.sendNotification(NotificationManager.Name.NearbyPostAdded, object: post)
        }
    }
    
    override public func documentWasRemoved(collection: String, id: String) {
        guard subscribing == false else { return }
        if let index = self.posts.indexOf({post in return post.id == id}){
            self.posts.removeAtIndex(index)
            if !subscribing {
                NotificationManager.sendNotification(NotificationManager.Name.NearbyPostRemoved, object: id)
            }
        }
    }
    
    override public func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.posts.indexOf({post in return post.id == id}){
            let post = self.posts[index];
            post.update(fields);
            if !subscribing {
                NotificationManager.sendNotification(NotificationManager.Name.NearbyPostModified, object: post)
            }
        }
    }
    
    public func count() -> Int{
        return posts.count;
    }
    
    public func itemAtIndex(index: Int) -> Post{
        return posts[index];
    }
}