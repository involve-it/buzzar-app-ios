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
    
    public var users = UsersProxy.Instance
    public var posts = PostsProxy.Instance
    
    private var totalDependencies = 2;
    
    public func connect() {
        if self.status != .Connected && self.status != .Connecting{
            self.status = ConnectionStatus.Connecting;
            Meteor.client.logLevel = .Debug;
            Meteor.connect(url) { (session) in
                var dependenciesResolved = 0;
                NSLog("Meteor connected");
                
                if self.users.isLoggedIn(){
                    self.totalDependencies += 1;
                    
                    self.users.getCurrentUser() { success in
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
}

