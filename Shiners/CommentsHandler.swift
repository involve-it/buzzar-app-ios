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
    fileprivate var data = Dictionary<String, CommentsResponse>()
    fileprivate var pendingRequests = [CommentsRequest]()
    
    func getCommentsByRequestId(_ id: String) -> Array<Comment>?{
        return data.removeValue(forKey: id)?.comments
    }
    
    func isCompleted(_ id: String) -> Bool?{
        return data[id]?.done
    }
    
    func getCommentsAsync(_ postId: String, skip: Int, take: Int = MessagesHandler.DEFAULT_PAGE_SIZE) -> String{
        let id = UUID().uuidString
        let request = CommentsRequest(id: id, postId: postId, take: take, skip: skip)
        if ConnectionHandler.Instance.isNetworkConnected() {
            self.processRequest(request)
        } else {
            if self.pendingRequests.count == 0 {
                NotificationCenter.default.addObserver(self, selector: #selector(processPendingRequests), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorNetworkConnected.rawValue), object: nil)
            }
            
            pendingRequests.append(request)
        }
        return id
    }
    
    @objc func processPendingRequests(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorNetworkConnected.rawValue), object: nil)
        self.pendingRequests.forEach { (request) in
            self.processRequest(request)
        }
        self.pendingRequests.removeAll()
    }
    
    fileprivate func processRequest(_ request: CommentsRequest){
        let response = CommentsResponse()
        self.data[request.id] = response
        
        ConnectionHandler.Instance.posts.getComments(request.postId, skip: request.skip, take: request.take) { (success, errorId, errorMessage, result) in
            response.setSuccess(success, comments: result as? Array<Comment>)
            NotificationManager.sendNotification(NotificationManager.Name.CommentsAsyncRequestCompleted, object: request.id as AnyObject?)
        }
    }
    
    fileprivate init (){}
    fileprivate static let instance = CommentsHandler()
    static var Instance: CommentsHandler {
        get{
            return instance
        }
    }
    
    fileprivate class CommentsResponse{
        var success: Bool?
        var done: Bool
        var comments: Array<Comment>?
        
        init(){
            done = false
        }
        
        func setSuccess(_ success: Bool, comments: Array<Comment>?){
            self.success = success
            self.comments = comments
            self.done = true
        }
    }
    
    fileprivate class CommentsRequest{
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
