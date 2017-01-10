//
//  UniversalLinksHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 1/9/17.
//  Copyright © 2017 Involve IT, Inc. All rights reserved.
//

import Foundation

class UniversalLinksHandler {
    
    
    func handleLink(components: URLComponents) -> Bool {
        print("\(components.path)")
        
        return false
    }
    
    var postId: String?
    
    @objc fileprivate func openPost() {
        if let postId = self.postId, ConnectionHandler.Instance.isNetworkConnected() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            self.doOpenPost(id: postId)
            self.postId = nil
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(openPost), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }
    
    fileprivate func doOpenPost(id: String){
        ConnectionHandler.Instance.posts.getPost(id) { (success, errorId, error, result) in
            if success {
                let post = result as! Post
                //open view controller
            } else {
                //alert of failure
            }
        }
    }
    
    fileprivate static let instance: UniversalLinksHandler = UniversalLinksHandler();
    class var Instance: UniversalLinksHandler {
        return instance;
    }
    
    fileprivate init() {}
}
