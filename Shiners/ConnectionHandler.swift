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
        self.dependenciesResolved += 1
        self.executeHandlers(self.dependenciesResolved)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
    }
    
    public func connect() {
        if self.status != .Connected && self.status != .Connecting{
            self.status = ConnectionStatus.Connecting
            //Meteor.client.logLevel = .Debug;
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.accountLoaded), name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
            
            Meteor.connect(url) { (session) in
                NSLog("Meteor connected")
                
                if AccountHandler.Instance.isLoggedIn(){
                    AccountHandler.Instance.loadAccount()
                } else {
                    AccountHandler.Instance.processLogoff()
                    self.dependenciesResolved += 1
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

