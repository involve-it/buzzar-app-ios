//
//  NavigationControllerBase.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/15/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class NavigationControllerBase: UINavigationController{
    private var notificationToolbar: UIToolbar?
    private var notificationLabel: UILabel?
    private var notificationToolbarVisible = false
    private var operationsCounter = 0
    private var connected = true
    private var dateDisconnected: NSDate?
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        //self.setupNotificationToolbar()
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(networkConnected), name: NotificationManager.Name.NetworkReachable.rawValue, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(networkDisconnected), name: NotificationManager.Name.NetworkUnreachable.rawValue, object: nil)
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(forceLayout), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    @objc private func networkConnected(notification: NSNotification){
        var timeInterval: NSTimeInterval = 100
        if let date = dateDisconnected{
            timeInterval = NSDate().timeIntervalSinceDate(date)
        }
        if ConnectionHandler.Instance.status == .Connected && !self.connected && timeInterval > 1 {
            self.connected = true
            self.connectionAquired()
        }
    }
    
    @objc private func networkDisconnected(notification: NSNotification){
        self.dateDisconnected = NSDate()
        self.connected = false
        self.connectionLost()
    }
    
    @objc private func forceLayout(notification: NSNotification){
        var heightOffset: CGFloat = -15
        if self.notificationToolbarVisible {
            heightOffset = 1
        }
        let frame = CGRectMake(0, self.navigationBar.frame.height - heightOffset, self.view.frame.width, 15)
        notificationToolbar!.frame = frame
        self.navigationBar.layoutSubviews()
    }
    
    private func setupNotificationToolbar(){
        notificationToolbar = UIToolbar(frame: CGRectMake(0, self.navigationBar.frame.height - 15, self.view.frame.width, 15))
        
        //label
        self.notificationLabel = UILabel(frame: CGRectMake(8, 0, toolbar!.bounds.width - 16, 14))
        self.notificationLabel!.font = UIFont.systemFontOfSize(8)
        self.notificationLabel!.text = NSLocalizedString("Connecting message...", comment: "Label, Connecting message...")
        notificationToolbar?.addSubview(self.notificationLabel!)
        
        //bottom separator
        let view = UIView(frame: CGRectMake(0, 14, toolbar!.bounds.width, 1 / UIScreen.mainScreen().scale))
        view.backgroundColor = UIColor(red: 200/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1.0)
        self.notificationToolbar?.addSubview(view)
        
        self.notificationToolbar?.clipsToBounds = true
        
        self.navigationBar.addSubview(notificationToolbar!)
        self.navigationBar.sendSubviewToBack(notificationToolbar!)
    }
    
    private func showNotificationToolbar(){
        if (!self.notificationToolbarVisible){
            self.notificationToolbarVisible = true
            UIView.animateWithDuration(0.2, animations: { 
                self.notificationToolbar!.frame.origin.y += 16
            })
        }
    }
    
    private func hideNotificationToolbar(){
        if (self.notificationToolbarVisible){
            self.notificationToolbarVisible = false
            UIView.animateWithDuration(0.2, animations: {
                self.notificationToolbar!.frame.origin.y -= 16
            })
        }
    }
    
    private func connectionLost(){
        self.notificationLabel!.text = MessagesProvider.getMessage(.ConnectionBroken);
        self.showNotificationToolbar()
        
        self.hideNotificationToolbarLater()
    }
    
    private func connectionAquired(){
        self.notificationLabel!.text = MessagesProvider.getMessage(.ConnectionConnecting)
        self.showNotificationToolbar()
        
        self.hideNotificationToolbarLater()
    }
    
    private func hideNotificationToolbarLater(){
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        self.operationsCounter += 1
        dispatch_after(dispatchTime, dispatch_get_main_queue()) {
            self.operationsCounter -= 1
            if (self.operationsCounter == 0){
                self.hideNotificationToolbar()
            }
        }
    }
}
