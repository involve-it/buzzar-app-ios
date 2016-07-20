//
//  AppDelegate.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import SystemConfiguration
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LocationHandlerDelegate {
    var window: UIWindow?
    private var reachability: Reachability?
    
    private let locationManager = LocationHandler()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.locationManager.delegate = self
        if UsersProxy.Instance.isLoggedIn(){
            self.locationManager.monitorSignificantLocationChanges()
        }
        
        // Override point for customization after application launch.
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch{
            NSLog("Can't create reachability")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification, object: nil)
        
        do {
            try reachability?.startNotifier()
        } catch {
            NSLog("Can't start reachability notifier")
        }
        
        CachingHandler.Instance.restoreAllOfflineData()
        ImageCachingHandler.Instance.initLocalCache()
        
        //meteor client handles network mishaps by itself
        ConnectionHandler.Instance.connect()
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        application.registerForRemoteNotifications()
        
        if let notification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [String: AnyObject]{
            self.handlePushNotification(notification)
        }
        
        return true
    }
    
    func locationReported(geocoderInfo: GeocoderInfo) {
        if UIApplication.sharedApplication().applicationState == .Background, let coords = geocoderInfo.coordinate {
            ConnectionHandler.Instance.reportLocation(coords.latitude, lng: coords.longitude)
        }
    }
    
    private func handlePushNotification(notification: [String: AnyObject]){
        if let payload = notification["ejson"] as? String{
            PushNotificationsHandler.handleNotification(payload, rootViewController: self.window?.rootViewController as! MainViewController)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if (application.applicationState == .Inactive || application.applicationState == .Background  )
        {
            if let payload = userInfo["ejson"] as? String{
                PushNotificationsHandler.handleNotification(payload, rootViewController: self.window?.rootViewController as! MainViewController)
            }
        }
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
        return handled
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let token = PushNotificationsHandler.saveToken(deviceToken)
        if UsersProxy.Instance.isLoggedIn(){
            if ConnectionHandler.Instance.status == .Connected {
                self.savePushToken()
            } else {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.savePushToken), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            }
        }
        print("Registered for push. Token: \(token)")
    }
    
    func savePushToken(){
        AccountHandler.Instance.savePushToken({ (success) in
            if !success {
                UIApplication.sharedApplication().unregisterForRemoteNotifications()
                NotificationManager.sendNotification(NotificationManager.Name.PushRegistrationFailed, object: nil)
            }
        })
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Failed to register for push notifications")
        application.unregisterForRemoteNotifications()
        NotificationManager.sendNotification(NotificationManager.Name.PushRegistrationFailed, object: nil)
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        if !application.isRegisteredForRemoteNotifications(){
            NotificationManager.sendNotification(NotificationManager.Name.PushRegistrationFailed, object: nil)
        }
    }
    
    func reachabilityChanged(notification: NSNotification){
        guard let reachability = self.reachability else {return}
        if reachability.isReachable(){
            NotificationManager.sendNotification(NotificationManager.Name.NetworkReachable, object: nil)
        } else {
            NotificationManager.sendNotification(NotificationManager.Name.NetworkUnreachable, object: nil)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if UsersProxy.Instance.isLoggedIn(){
            self.locationManager.monitorSignificantLocationChanges()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

