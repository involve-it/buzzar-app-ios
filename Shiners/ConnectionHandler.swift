//
//  ConnectionHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

open class ConnectionHandler{
    public static let baseUrl = "http://192.168.1.71:3000"
    //public static let baseUrl = "http://msg.webhop.org"
    //open static let baseUrl = "https://www.shiners.mobi"
    
    open static let publicUrl = "https://shiners.ru"
    
    //private let url:String = "ws://msg.webhop.org/websocket"
    private let url:String = "ws://192.168.1.71:3000/websocket"
    //fileprivate let url:String = "wss://www.shiners.mobi/websocket"
    
    open fileprivate(set) var status: ConnectionStatus = .notInitialized
    
    open var users = UsersProxy.Instance
    open var posts = PostsProxy.Instance
    open var messages = MessagesProxy.Instance
    
    fileprivate var totalDependencies = 1
    fileprivate var dependenciesResolved = 0
    
    fileprivate var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    open func reportLocation(_ lat: Double, lng: Double, notify: Bool){
        CachingHandler.Instance.saveLastLocation(lat, lng: lng)
        if let userId = AccountHandler.Instance.getSavedUserId() {
            var dict = Dictionary<String, AnyObject>()
            dict["lat"] = lat as AnyObject?
            dict["lng"] = lng as AnyObject?
            dict["userId"] = userId as AnyObject?
            dict["deviceId"] = SecurityHandler.getDeviceId() as AnyObject?
            dict["notify"] = notify as AnyObject?
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions()), let url = URL(string: ConnectionHandler.baseUrl + "/api/geolocation"){
                let request = NSMutableURLRequest(url: url)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                request.httpBody = jsonData
                
                
                self.backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                    UIApplication.shared.endBackgroundTask(self.backgroundTask)
                })
                
                URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {data,response,error in
                    print(data)
                }).resume()
                
                if self.backgroundTask != UIBackgroundTaskInvalid{
                    UIApplication.shared.endBackgroundTask(self.backgroundTask)
                    self.backgroundTask = UIBackgroundTaskInvalid
                }
            }
        }
    }
    
    @objc fileprivate func accountLoaded(){
        Logger.log("account loaded callback")
        self.dependenciesResolved += 1
        self.executeHandlers(self.dependenciesResolved)
    }
    
    open func connect() {
        if self.status != .connected && self.status != .connecting{
            NotificationCenter.default.addObserver(self, selector: #selector(clientDisconnected), name: NSNotification.Name(rawValue: DDP_WEBSOCKET_ERROR), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(clientDisconnected), name: NSNotification.Name(rawValue: DDP_WEBSOCKET_CLOSE), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(clientDisconnected), name: NSNotification.Name(rawValue: DDP_DISCONNECTED), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(clientDisconnected), name: NSNotification.Name(rawValue: DDP_FAILED), object: nil)
            
            self.status = ConnectionStatus.connecting
            //Meteor.client.logLevel = .Debug;
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.accountLoaded), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountLoaded.rawValue), object: nil)
            Logger.log("connect() called")
            Meteor.connect(url) { (session) in
                NSLog("Meteor connected")
                Logger.log("Meteor.connect callback, current status: \(self.status)")
                self.dependenciesResolved = 0
                self.status = .networkConnected
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
    
    open func isConnected() -> Bool {
        return self.status == .connected && self.isNetworkReachable()
    }
    
    open func isNetworkConnected() -> Bool {
        return self.status == .networkConnected || self.status == .connected
    }
    
    open func isNetworkReachable() -> Bool {
        return (UIApplication.shared.delegate as! AppDelegate).isNetworkReachable()
    }
    
    open func disconnect(){
        //todo: disconnect
        Meteor.connect("")
    }
    
    fileprivate func executeHandlers(_ count: Int){
        print("execute handlers: \(count)")
        Logger.log("execute handlers. count: \(count)")
        if (count == self.totalDependencies && self.status != .connected){
            Logger.log("execute handlers: executing")
            self.status = ConnectionStatus.connected;
            NotificationManager.sendNotification(NotificationManager.Name.MeteorConnected, object: nil)
        }
    }
    
    fileprivate init(){
        //singleton
    }
    
    fileprivate static let instance: ConnectionHandler = ConnectionHandler();
    open class var Instance: ConnectionHandler {
        return instance;
    }
    
    
    public enum ConnectionStatus{
        case notInitialized, connecting, failed, connected, networkConnected
    }
    
    @objc func clientDisconnected(){
        Logger.log("Client disconnected, current status: \(self.status). Setting to: .Failed")
        self.status = .failed
        self.dependenciesResolved = 0
        NotificationManager.sendNotification(.MeteorConnectionFailed, object: nil)
    }
}

