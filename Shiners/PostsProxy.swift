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

public class PostsProxy{
    private static let instance = PostsProxy()
    public class var Instance: PostsProxy{
        get{
            return instance;
        }
    }
    
    public func getNearbyPosts(lat: Double, lng: Double, radius: Double, skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["lat"] = lat
        dict["lng"] = lng
        dict["radius"] = radius
        dict["skip"] = skip
        dict["take"] = take
        
        Meteor.call("getNearbyPostsTest", params: [dict]) {result, error in
            if error == nil {
                if let posts = ResponseHelper.callHandlerArray(result, handler: callback) as [Post]? {
                    let users = posts.map({ (post) -> User in
                        return post.user!
                    })
                    AccountHandler.Instance.mergeNewUsers(users)
                }
                
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
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
    
    public func addPost(post: Post, currentCoordinates: CLLocationCoordinate2D?, callback: MeteorMethodCallback? = nil){
        let postDict = post.toDictionary()
        var parameters = [postDict];
        if let coordinates = currentCoordinates{
            var coordinatesDict = Dictionary<String, AnyObject>()
            coordinatesDict["lat"] = coordinates.latitude
            coordinatesDict["lng"] = coordinates.longitude
            coordinatesDict["deviceId"] = SecurityHandler.getDeviceId()

            parameters.append(coordinatesDict)
        }
        Meteor.call("addPost", params: parameters) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                var id: String? = nil
                if let fields = result as? NSDictionary {
                    id = fields.valueForKey("result") as? String
                }
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: id)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    public func editPost(post: Post, callback: MeteorMethodCallback? = nil){
        let postDict = post.toDictionary()
        Meteor.call("editPost", params: [postDict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    public func deletePost(id: String, callback: MeteorMethodCallback? = nil){
        Meteor.call("deletePost", params: [id]){(result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    public func incrementSeenCounters(id: String, incrementTotal: Bool, incrementToday: Bool, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["postId"] = id
        //todo: fix paging
        dict["incrementTotal"] = incrementTotal
        dict["incrementToday"] = incrementToday
        dict["incrementAll"] = true
        Meteor.call("incrementPostSeenCounters", params: [dict]){(result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    public func getComments(postId: String, skip: Int, take: Int, callback: MeteorMethodCallback? = nil){
        var dict = Dictionary<String, AnyObject>()
        dict["postId"] = postId
        dict["take"] = take
        dict["skip"] = skip
        Meteor.call("getComments", params: [dict]){ (result, error) in
            if error == nil {
                ResponseHelper.callHandlerArray(result, handler: callback) as [Comment]?
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    func addComment(comment: Comment, callback: MeteorMethodCallback? = nil){
        let dict = comment.toDictionary()
        Meteor.call("addComment", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                var id: String? = nil
                if let fields = result as? NSDictionary {
                    id = fields.valueForKey("result") as? String
                }
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: id)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    func likePost(postId: String, callback: MeteorMethodCallback?){
        var dict = Dictionary<String, AnyObject>()
        dict["userId"] = AccountHandler.Instance.userId!
        dict["postId"] = postId
        Meteor.call("likePost", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
    
    func unlikePost(postId: String, callback: MeteorMethodCallback?){
        var dict = Dictionary<String, AnyObject>()
        dict["userId"] = AccountHandler.Instance.userId!
        dict["postId"] = postId
        Meteor.call("unlikePost", params: [dict]) { (result, error) in
            if error == nil {
                let errorId = ResponseHelper.getErrorId(result);
                callback?(success: ResponseHelper.isSuccessful(result), errorId: errorId, errorMessage: ResponseHelper.getErrorMessage(errorId), result: nil)
            } else {
                callback?(success: false, errorId: nil, errorMessage: ResponseHelper.getDefaultErrorMessage(), result: nil)
            }
        }
    }
}