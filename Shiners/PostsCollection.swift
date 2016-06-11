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
    public var posts = [Post]()
    
    init() {
        super.init(name: "posts");
    }
    
    override public func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        let post = Post(id: id, fields: fields)
        self.posts.append(post)
        NotificationManager.sendNotification(NotificationManager.Name.NearbyPostAdded, object: nil)
    }
    
    override public func documentWasRemoved(collection: String, id: String) {
        if let index = self.posts.indexOf({post in return post.id == id}){
            self.posts.removeAtIndex(index)
            NotificationManager.sendNotification(NotificationManager.Name.NearbyPostRemoved, object: nil)
        }
    }
    
    override public func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.posts.indexOf({post in return post.id == id}){
            let post = self.posts[index];
            post.update(fields);
            NotificationManager.sendNotification(NotificationManager.Name.NearbyPostModified, object: nil)
        }
    }
    
    public func count() -> Int{
        return posts.count;
    }
    
    public func itemAtIndex(index: Int) -> Post{
        return posts[index];
    }
}