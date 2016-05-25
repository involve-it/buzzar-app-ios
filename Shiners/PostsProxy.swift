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
    //public var myPosts = [Post]()
    
    private static let instance = PostsProxy()
    public class var Instance: PostsProxy{
        get{
            return instance;
        }
    }
    
    /*private init(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didLogin), name: DDP_USER_DID_LOGIN, object: nil);
    }
    
    @objc private func didLogin(){
        self.getMyPosts(true, callback: nil)
    }*/
    
    public func getMyPosts(skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["type"] = "all"
        //todo: fix paging
        dict["take"] = take
        dict["skip"] = skip
        Meteor.call("getMyPosts", params: [dict]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandlerArray(result, handler: callback) as [Post]?
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    public func addPost(post: Post, callback: MeteorMethodCallback? = nil){
        Meteor.call("addPost", params: [post]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    public func editPost(post: Post, callback: MeteorMethodCallback? = nil){
        Meteor.call("editPost", params: [post]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
}