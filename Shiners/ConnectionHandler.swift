//
//  ConnectionHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP



public class ConnectionHandler{
    private let url:String = "ws://msg.webhop.org/websocket";
    //private let url:String = "ws://192.168.1.61:3000/websocket";
    private var status: ConnectionStatus = .NotInitialized;
    private var handlers = [EventHandler]()
    
    public var postsCollection = PostsCollection();
    public var imagesCollection = MeteorCollection<Image>(name: "images");
    public var currentUser: User?;
    
    private var totalDependencies = 2;
    
    public func connect() {
        if self.status != .Connected && self.status != .Connecting{
            self.status = ConnectionStatus.Connecting;
            Meteor.client.logLevel = .Debug;
            Meteor.connect(url) { (session) in
                var dependenciesResolved = 0;
                NSLog("Meteor connected");
                
                if let userId = Meteor.client.userId(){
                    self.totalDependencies += 1;
                    
                    self.retrieveCurrentUser(userId) { success in
                        dependenciesResolved += 1;
                        self.executeHandlers(dependenciesResolved);
                        if !success {
                            NSLog("Error getting current user")
                        }
                    };
                }
                
                Meteor.subscribe("posts-all"){
                    NSLog("posts-all subscribed");
                    dependenciesResolved += 1;
                    self.executeHandlers(dependenciesResolved);
                }
                
                Meteor.subscribe("posts-images"){
                    NSLog("images subscribed");
                    dependenciesResolved += 1;
                    self.executeHandlers(dependenciesResolved);
                }
            }
        }
    }
    
    public func disconnect(){
        //todo: disconnect
        Meteor.connect("")
    }
    
    private func retrieveCurrentUser(userId: String, callback: (success: Bool) -> Void){
        Meteor.call("getUser", params: [Meteor.client.userId()!]){ result, error in
            if (error == nil){
                if let user = result as? NSDictionary {
                    self.currentUser = User(fields: user)
                    
                    callback(success: true)
                    return
                }
            }
            callback(success: false)
        };
    }
    
    public func login(userName: String, password: String, callback: (success: Bool, reason: String?) -> Void){
        Meteor.loginWithUsername(userName, password: password){ result, error in
            if (error == nil){
                self.retrieveCurrentUser(Meteor.client.userId()!, callback: { (success) in
                    if (success){
                        callback(success: true, reason: nil)
                    } else {
                        callback(success: false, reason: "Error retrieveing user")
                    }
                })
                
            } else {
                let reason = error?.reason;
                callback(success: false, reason: reason);
            }
        }
    }
    
    public func logoff(callback: (success: Bool)-> Void){
        Meteor.logout(){ result, error in
            if (error == nil){
                self.currentUser = nil;
                callback(success: true)
            } else {
                callback(success: false)
            }
        }
    }
    
    private func executeHandlers(count: Int){
        if (count == self.totalDependencies && self.handlers.count > 0){
            for eventHandler in self.handlers{
                eventHandler.handler();
            }
            self.handlers.removeAll();
            
            self.status = ConnectionStatus.Connected;
        }
    }
    
    private init(){
        //singleton
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didLogin), name: DDP_USER_DID_LOGIN, object: nil);
    }
    
    @objc private func didLogin(){
        NSLog("LOGGED IN");
    }
    
    private static let instance: ConnectionHandler = ConnectionHandler();
    public class var Instance: ConnectionHandler {
        return instance;
    }
    
    
    private enum ConnectionStatus{
        case NotInitialized, Connecting, Failed, Connected
    }
    
    public func onConnected(handler: ()->Void){
        if (self.status == .Connected){
            handler();
        } else {
            self.handlers.append(EventHandler(target: handler));
        }
    }
    
    private class EventHandler{
        let handler: () ->Void;
        
        init(target: () ->Void){
            self.handler = target;
        }
    }
    
    /*public class func downloadUrl(urlString: String, done: (data: NSData?, response: NSURLResponse?, error: NSError?)){
        let url:NSURL = NSURL(string: urlString)!;
        NSURLSession.sharedSession().dataTaskWithURL(url){data,response,error in
            
        }
    }*/
}

