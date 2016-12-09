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
    //public static let baseUrl = "http://192.168.1.71:3000"
    //public static let baseUrl = "http://msg.webhop.org"
    public static let baseUrl = "https://www.shiners.mobi"
    
    public static let publicUrl = "https://shiners.ru"
    
    //private let url:String = "ws://msg.webhop.org/websocket"
    //private let url:String = "ws://192.168.1.71:3000/websocket"
    private let url:String = "wss://www.shiners.mobi/websocket"
    
    public private(set) var status: ConnectionStatus = .NotInitialized
    
    public var users = UsersProxy.Instance
    public var posts = PostsProxy.Instance
    public var messages = MessagesProxy.Instance
    
    private var totalDependencies = 1
    private var dependenciesResolved = 0
    
    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    public func reportLocation(lat: Double, lng: Double, notify: Bool){
        CachingHandler.Instance.saveLastLocation(lat, lng: lng)
        if let userId = AccountHandler.Instance.getSavedUserId() {
            var dict = Dictionary<String, AnyObject>()
            dict["lat"] = lat
            dict["lng"] = lng
            dict["userId"] = userId
            dict["deviceId"] = SecurityHandler.getDeviceId()
            dict["notify"] = notify
            if let jsonData = try? NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions()), url = NSURL(string: ConnectionHandler.baseUrl + "/api/geolocation"){
                let request = NSMutableURLRequest(URL: url)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.HTTPMethod = "POST"
                request.HTTPBody = jsonData
                
                
                self.backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
                    UIApplication.sharedApplication().endBackgroundTask(self.backgroundTask)
                })
                
                NSURLSession.sharedSession().dataTaskWithRequest(request){data,response,error in
                    print(data)
                }.resume()
                
                if self.backgroundTask != UIBackgroundTaskInvalid{
                    UIApplication.sharedApplication().endBackgroundTask(self.backgroundTask)
                    self.backgroundTask = UIBackgroundTaskInvalid
                }
            }
        }
    }
    
    @objc private func accountLoaded(){
        Logger.log("account loaded callback")
        self.dependenciesResolved += 1
        self.executeHandlers(self.dependenciesResolved)
    }
    
    public func connect() {
        if self.status != .Connected && self.status != .Connecting{
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(clientDisconnected), name: DDP_WEBSOCKET_ERROR, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(clientDisconnected), name: DDP_WEBSOCKET_CLOSE, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(clientDisconnected), name: DDP_DISCONNECTED, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(clientDisconnected), name: DDP_FAILED, object: nil)
            
            self.status = ConnectionStatus.Connecting
            //Meteor.client.logLevel = .Debug;
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.accountLoaded), name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
            Logger.log("connect() called")
            Meteor.connect(url) { (session) in
                NSLog("Meteor connected")
                Logger.log("Meteor.connect callback, current status: \(self.status)")
                self.dependenciesResolved = 0
                self.status = .NetworkConnected
                NotificationManager.sendNotification(.MeteorNetworkConnected, object: nil)
                
                if AccountHandler.Instance.isLoggedIn(){
                    Logger.log("Meteor.connect callback: invoke loadAccount")
                    AccountHandler.Instance.loadAccount()
                } else {
                    Logger.log("Meteor.connect callback: invoke processLogoff")
                    AccountHandler.Instance.processLogoff()
                    self.dependenciesResolved += 1
                }
                self.executeHandlers(self.dependenciesResolved)
            }
        }
    }
    
    public func isConnected() -> Bool {
        return self.status == .Connected && self.isNetworkReachable()
    }
    
    public func isNetworkConnected() -> Bool {
        return self.status == .NetworkConnected || self.status == .Connected
    }
    
    public func isNetworkReachable() -> Bool {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).isNetworkReachable()
    }
    
    public func disconnect(){
        //todo: disconnect
        Meteor.connect("")
    }
    
    private func executeHandlers(count: Int){
        print("execute handlers: \(count)")
        Logger.log("execute handlers. count: \(count)")
        if (count == self.totalDependencies && self.status != .Connected){
            Logger.log("execute handlers: executing")
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
        case NotInitialized, Connecting, Failed, Connected, NetworkConnected
    }
    
    @objc func clientDisconnected(){
        Logger.log("Client disconnected, current status: \(self.status). Setting to: .Failed")
        self.status = .Failed
        self.dependenciesResolved = 0
        NotificationManager.sendNotification(.MeteorConnectionFailed, object: nil)
    }
}

