//
//  MessagesHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/3/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class CommentsHandler {
    static let DEFAULT_PAGE_SIZE = 20
    private var data = Dictionary<String, CommentsResponse>()
    private var pendingRequests = [CommentsRequest]()
    
    func getCommentsByRequestId(id: String) -> Array<Comment>?{
        return data.removeValueForKey(id)?.comments
    }
    
    func isCompleted(id: String) -> Bool?{
        return data[id]?.done
    }
    
    func getCommentsAsync(postId: String, skip: Int, take: Int = MessagesHandler.DEFAULT_PAGE_SIZE) -> String{
        let id = NSUUID().UUIDString
        let request = CommentsRequest(id: id, postId: postId, take: take, skip: skip)
        if ConnectionHandler.Instance.isNetworkConnected() {
            self.processRequest(request)
        } else {
            if self.pendingRequests.count == 0 {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(processPendingRequests), name: NotificationManager.Name.MeteorNetworkConnected.rawValue, object: nil)
            }
            
            pendingRequests.append(request)
        }
        return id
    }
    
    @objc func processPendingRequests(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorNetworkConnected.rawValue, object: nil)
        self.pendingRequests.forEach { (request) in
            self.processRequest(request)
        }
        self.pendingRequests.removeAll()
    }
    
    private func processRequest(request: CommentsRequest){
        let response = CommentsResponse()
        self.data[request.id] = response
        
        ConnectionHandler.Instance.posts.getComments(request.postId, skip: request.skip, take: request.take) { (success, errorId, errorMessage, result) in
            response.setSuccess(success, comments: result as? Array<Comment>)
            NotificationManager.sendNotification(NotificationManager.Name.CommentsAsyncRequestCompleted, object: request.id)
        }
    }
    
    private init (){}
    private static let instance = CommentsHandler()
    static var Instance: CommentsHandler {
        get{
            return instance
        }
    }
    
    private class CommentsResponse{
        var success: Bool?
        var done: Bool
        var comments: Array<Comment>?
        
        init(){
            done = false
        }
        
        func setSuccess(success: Bool, comments: Array<Comment>?){
            self.success = success
            self.comments = comments
            self.done = true
        }
    }
    
    private class CommentsRequest{
        var postId: String
        var skip: Int
        var take: Int
        var id: String
        
        init(id : String, postId: String, take: Int, skip: Int){
            self.id = id
            self.skip = skip
            self.take = take
            self.postId = postId
        }
    }
}