//
//  PostsProxy.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class PostsProxy{
    public var myPosts = [Post]()
    
    private static let instance = PostsProxy()
    public class var Instance: PostsProxy{
        get{
            return instance;
        }
    }
    
    private init(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didLogin), name: DDP_USER_DID_LOGIN, object: nil);
    }
    
    @objc private func didLogin(){
        self.getMyPosts(true, callback: nil)
    }
    
    public func getMyPosts(triggerNotification: Bool, callback: MeteorMethodCallback?){
        var dict = Dictionary<String, AnyObject>()
        dict["type"] = "all"
        //todo: fix paging
        dict["take"] = 100
        dict["skip"] = 0
        Meteor.call("getMyPosts", params: [dict]) { (result, error) in
            if error == nil {
                if ResponseHelper.isSuccessful(result){
                    self.myPosts.removeAll()
                    
                    let res = ResponseHelper.getResult(result) as! NSArray
                    for postFields in res {
                        if let postFieldsDic = postFields as? NSDictionary{
                            self.myPosts.append(Post(fields: postFieldsDic))
                        }
                    }
                    if triggerNotification{
                        NotificationManager.sendNotification(.MyPostsUpdated, object: nil)
                    }
                }
                ResponseHelper.callHandler(result, handler: callback)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
}