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
    private let url:String = "ws://msg.webhop.org/websocket"
    //private let url:String = "ws://192.168.1.61:3000/websocket"
    public private(set) var status: ConnectionStatus = .NotInitialized
    
    public var users = UsersProxy.Instance
    public var posts = PostsProxy.Instance
    
    private var totalDependencies = 0
    private var dependenciesResolved = 0
    
    @objc private func accountLoaded(){
        self.dependenciesResolved += 1
        self.executeHandlers(self.dependenciesResolved)
    }
    
    public func connect() {
        if self.status != .Connected && self.status != .Connecting{
            self.status = ConnectionStatus.Connecting
            //Meteor.client.logLevel = .Debug;
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.accountLoaded), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
            
            Meteor.connect(url) { (session) in
                NSLog("Meteor connected")
                
                if self.users.isLoggedIn(){
                    self.totalDependencies += 1
                    AccountHandler.Instance.loadAccount()
                }
                self.executeHandlers(self.dependenciesResolved)
            }
        }
    }
    
    public func disconnect(){
        //todo: disconnect
        Meteor.connect("")
    }
    
    private func executeHandlers(count: Int){
        if (count == self.totalDependencies && self.status != .Connected){
            self.status = ConnectionStatus.Connected;
            NotificationManager.sendNotification(NotificationManager.Name.MeteorConnected, object: nil)
        }
    }
    
    private init(){
        //singleton
    }
    
    private static let instance: ConnectionHandler = ConnectionHandler();
    public class var Instance: ConnectionHandler {
        return instance;
    }
    
    
    public enum ConnectionStatus{
        case NotInitialized, Connecting, Failed, Connected
    }
}

