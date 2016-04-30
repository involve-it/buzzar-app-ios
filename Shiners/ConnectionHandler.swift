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
    private var status: ConnectionStatus = .NotInitialized;
    private var handlers = [EventHandler]()
    
    public var postsCollection = PostsCollection();
    public var imagesCollection = MeteorCollection<Image>(name: "images");
    public var usersCollection = UsersCollection();
    public var profileDetailsCollection = ProfileDetailsCollection();
    
    private var totalSubscriptions = 2;
    
    private var usersId: String?;
    private var profileDetailsId: String?;
    
    public func connect() {
        if self.status != .Connected && self.status != .Connecting{
            self.status = ConnectionStatus.Connecting;
            //Meteor.client.logLevel = .Debug;
            Meteor.client.connect(url) { (session) in
                var subscriptionCount = 0;
                NSLog("Meteor connected");
                
                if let userId = Meteor.client.userId(){
                    self.totalSubscriptions += 2;
                    
                    self.usersId = Meteor.subscribe("users-one", params: [userId]){
                        NSLog("Current user subscribed");
                        subscriptionCount+=1;
                        self.executeHandlers(subscriptionCount);
                    }
                    
                    self.profileDetailsId = Meteor.subscribe("profileDetails-my"){
                        NSLog("Current user profile details subscribed");
                        subscriptionCount+=1;
                        self.executeHandlers(subscriptionCount);
                    }
                }
                
                Meteor.subscribe("posts-all"){
                    NSLog("posts-all subscribed");
                    subscriptionCount+=1;
                    self.executeHandlers(subscriptionCount);
                }
                
                Meteor.subscribe("posts-images"){
                    NSLog("images subscribed");
                    subscriptionCount+=1;
                    self.executeHandlers(subscriptionCount);
                }
            }
        }
    }
    
    public func login(userName: String, password: String, callback: (success: Bool, reason: String?) -> Void){
        Meteor.loginWithUsername(userName, password: password){ result, error in
            if (error == nil){
                self.usersId = Meteor.subscribe("users-one", params: [Meteor.client.userId()!]){
                    self.profileDetailsId = Meteor.subscribe("profileDetails-my"){
                        callback(success: true, reason: nil)
                    }
                }
            } else {
                let reason = error?.reason;
                callback(success: false, reason: reason);
            }
        }
    }
    
    public func logoff(callback: (success: Bool)-> Void){
        Meteor.logout(){ result, error in
            if (error == nil){
                Meteor.unsubscribe(withId: self.profileDetailsId!);
                self.profileDetailsId = nil;
                Meteor.unsubscribe(withId: self.usersId!){
                    self.usersId = nil;
                    callback(success: true);
                }
            } else {
                callback(success: false);
            }
        }
    }
    
    private func executeHandlers(count: Int){
        if (count == self.totalSubscriptions && self.handlers.count > 0){
            for eventHandler in self.handlers{
                eventHandler.handler();
            }
            self.handlers.removeAll();
            
            self.status = ConnectionStatus.Connected;
        }
    }
    
    private init(){
        //singleton
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

