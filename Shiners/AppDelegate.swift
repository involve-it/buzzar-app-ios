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
import CoreLocation
import Google

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LocationHandlerDelegate {
    var window: UIWindow?
    fileprivate var reachability: Reachability?
    
    fileprivate let locationManager = LocationHandler()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        NSSetUncaughtExceptionHandler { (ex) in
            ExceptionHandler.saveException(ex)
        }
        SecurityHandler.setDeviceId()
        
        self.locationManager.delegate = self
        if AccountHandler.Instance.isLoggedIn(){
            self.locationManager.monitorSignificantLocationChanges()
        }
        
        // Override point for customization after application launch.
        self.reachability = Reachability()!
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification, object: nil)
        
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
        
        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: AnyObject]{
            self.handlePushNotification(notification)
        }
        
        //customizeApperance()
        
        let colorTabBar = UIColor(red: 90/255, green: 177/255, blue: 231/255, alpha: 1)
        UITabBar.appearance().tintColor = colorTabBar
        
        
        //UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Normal)
        //UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.redColor()], forState: .Selected)

        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()!
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        //gai.logger.logLevel = GAILogLevel.verbose  // remove before app release
        
        //UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).tintColor = UIColor.whiteColor()
        NotificationCenter.default.addObserver(self, selector: #selector(accountUpdated), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
        
        return true
    }
    
    func accountUpdated(){
        if AccountHandler.Instance.isLoggedIn() {
            self.locationManager.monitorSignificantLocationChanges()
        } else {
            self.locationManager.stopMonitoringLocation()
        }
    }
    
    func locationReported(_ geocoderInfo: GeocoderInfo) {
        if UIApplication.shared.applicationState == .background, let coords = geocoderInfo.coordinate {
            ConnectionHandler.Instance.reportLocation(coords.latitude, lng: coords.longitude, notify: true)
        }
    }
    
    fileprivate func handlePushNotification(_ notification: [String: AnyObject]){
        if let payload = notification["ejson"] as? String{
            PushNotificationsHandler.handleNotification(payload, rootViewController: self.window?.rootViewController as! MainViewController)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if (application.applicationState == .inactive || application.applicationState == .background  )
        {
            if let payload = userInfo["ejson"] as? String{
                PushNotificationsHandler.handleNotification(payload, rootViewController: self.window?.rootViewController as! MainViewController)
            }
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        return handled
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = PushNotificationsHandler.saveToken(deviceToken)
        if AccountHandler.Instance.isLoggedIn(){
            if ConnectionHandler.Instance.isNetworkConnected() {
                self.savePushToken()
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(self.savePushToken), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            }
        }
        print("Registered for push. Token: \(token)")
    }
    
    func savePushToken(){
        AccountHandler.Instance.savePushToken({ (success) in
            if !success {
                UIApplication.shared.unregisterForRemoteNotifications()
                NotificationManager.sendNotification(NotificationManager.Name.PushRegistrationFailed, object: nil)
            }
        })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for push notifications")
        application.unregisterForRemoteNotifications()
        NotificationManager.sendNotification(NotificationManager.Name.PushRegistrationFailed, object: nil)
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if !application.isRegisteredForRemoteNotifications{
            NotificationManager.sendNotification(NotificationManager.Name.PushRegistrationFailed, object: nil)
        }
    }
    
    func reachabilityChanged(_ notification: Notification){
        guard let reachability = self.reachability else {return}
        if reachability.isReachable{
            NotificationManager.sendNotification(NotificationManager.Name.NetworkReachable, object: nil)
        } else {
            NotificationManager.sendNotification(NotificationManager.Name.NetworkUnreachable, object: nil)
        }
    }
    
    func isNetworkReachable() -> Bool {
        guard let reachability = self.reachability else {return true}
        return reachability.isReachable
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        UIApplication.shared.applicationIconBadgeNumber = LocalNotificationsHandler.Instance.getTotalEventCount()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        //UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    
    func customizeApperance() {
        let barTintColor = UIColor(red: 0/255, green: 118/255, blue: 255/255, alpha: 1)
        //UISearchBar.appearance().tintColor = barTintColor
        UISearchBar.appearance().barTintColor = barTintColor
        window!.tintColor = UIColor(red: 0/255, green: 118/255, blue: 255/255, alpha: 1)
    }
    
}

