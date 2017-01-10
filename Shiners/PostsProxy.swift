//
//  PostsProxy.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP
import CoreLocation

open class PostsProxy{
    fileprivate static let instance = PostsProxy()
    open class var Instance: PostsProxy{
        get{
            return instance;
        }
    }
    
    open func getNearbyPosts(_ lat: Double, lng: Double, radius: Double, skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["lat"] = lat as AnyObject?
        dict["lng"] = lng as AnyObject?
        dict["radius"] = radius as AnyObject?
        dict["skip"] = skip as AnyObject?
        dict["take"] = take as AnyObject?
        
        Meteor.call("getNearbyPostsTest", params: [dict]) {result, error in
            if error == nil {
                if let posts = ResponseHelper.callHandlerArray(result as AnyObject?, handler: callback) as [Post]? {
                    let users = posts.map({ (post) -> User in
                        return post.user!
                    })
                    AccountHandler.Instance.mergeNewUsers(users)
                }
                
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    open func getPost(_ id: String, _ callback: MeteorMethodCallback? = nil){
        Meteor.call("getPost", params: [id]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandler(result as AnyObject?, handler: callback) as Post?
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    open func getMyPosts(_ skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["type"] = "all" as AnyObject?
        //todo: fix paging
        dict["take"] = take as AnyObject?
        dict["skip"] = skip as AnyObject?
        Meteor.call("getMyPosts", params: [dict]) { (result, error) in
            if error == nil {
                ResponseHelper.callHandlerArray(result as AnyObject?, handler: callback) as [Post]?
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    open func addPost(_ post: Post, currentCoordinates: CLLocationCoordinate2D?, callback: MeteorMethodCallback? = nil){
        let postDict = post.toDictionary()
        var parameters = [postDict];
        if let coordinates = currentCoordinates{
            var coordinatesDict = Dictionary<String, AnyObject>()
            coordinatesDict["lat"] = coordinates.latitude as AnyObject?
            coordinatesDict["lng"] = coordinates.longitude as AnyObject?
            coordinatesDict["deviceId"] = SecurityHandler.getDeviceId() as AnyObject?

            parameters.append(coordinatesDict)
        }
        Meteor.call("addPost", params: parameters) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                var id: String? = nil
                if let fields = result as? NSDictionary {
                    id = fields.value(forKey: "result") as? String
                }
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), id)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    open func editPost(_ post: Post, callback: MeteorMethodCallback? = nil){
        let postDict = post.toDictionary()
        Meteor.call("editPost", params: [postDict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    open func deletePost(_ id: String, callback: MeteorMethodCallback? = nil){
        Meteor.call("deletePost", params: [id]){(result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    open func incrementSeenCounters(_ id: String, incrementTotal: Bool, incrementToday: Bool, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["postId"] = id as AnyObject?
        //todo: fix paging
        dict["incrementTotal"] = incrementTotal as AnyObject?
        dict["incrementToday"] = incrementToday as AnyObject?
        dict["incrementAll"] = true as AnyObject?
        Meteor.call("incrementPostSeenCounters", params: [dict]){(result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    open func getComments(_ postId: String, skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["postId"] = postId as AnyObject?
        dict["take"] = take as AnyObject?
        dict["skip"] = skip as AnyObject?
        Meteor.call("getComments", params: [dict]){ (result, error) in
            if error == nil {
                ResponseHelper.callHandlerArray(result as AnyObject?, handler: callback) as [Comment]?
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func addComment(_ comment: Comment, callback: MeteorMethodCallback? = nil){
        let dict = comment.toDictionary()
        Meteor.call("addComment", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                var id: String? = nil
                if let fields = result as? NSDictionary {
                    id = fields.value(forKey: "result") as? String
                }
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), id)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func deleteComment(_ commentId: String, callback: MeteorMethodCallback? = nil){
        Meteor.call("deleteComment", params: [commentId]) {(result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func likePost(_ postId: String, callback: MeteorMethodCallback?){
        var dict = Dictionary<String, AnyObject>()
        dict["userId"] = AccountHandler.Instance.userId! as AnyObject?
        dict["entityId"] = postId as AnyObject?
        dict["entityType"] = "post" as AnyObject?
        Meteor.call("likeEntity", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func unlikePost(_ postId: String, callback: MeteorMethodCallback?){
        var dict = Dictionary<String, AnyObject>()
        dict["userId"] = AccountHandler.Instance.userId! as AnyObject?
        dict["entityId"] = postId as AnyObject?
        dict["entityType"] = "post" as AnyObject?
        Meteor.call("unlikeEntity", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func likeComment(_ commentId: String, callback: MeteorMethodCallback?){
        var dict = Dictionary<String, AnyObject>()
        dict["userId"] = AccountHandler.Instance.userId! as AnyObject?
        dict["entityId"] = commentId as AnyObject?
        dict["entityType"] = "comment" as AnyObject?
        Meteor.call("likeEntity", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
    
    func unlikeComment(_ commentId: String, callback: MeteorMethodCallback?){
        var dict = Dictionary<String, AnyObject>()
        dict["userId"] = AccountHandler.Instance.userId! as AnyObject?
        dict["entityId"] = commentId as AnyObject?
        dict["entityType"] = "comment" as AnyObject?
        Meteor.call("unlikeEntity", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result as AnyObject?);
                callback?(ResponseHelper.isSuccessful(result as AnyObject?), errorId, ResponseHelper.getErrorMessage(errorId), nil)
            } else {
                callback?(false, nil, ResponseHelper.getDefaultErrorMessage(), nil)
            }
        }
    }
}
