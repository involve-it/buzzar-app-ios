//
//  NavigationControllerBase.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/15/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

open class NavigationControllerBase: UINavigationController{
    fileprivate var notificationToolbar: UIToolbar?
    fileprivate var notificationLabel: UILabel?
    fileprivate var notificationToolbarVisible = false
    fileprivate var operationsCounter = 0
    fileprivate var connected = true
    fileprivate var dateDisconnected: Date?
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        //self.setupNotificationToolbar()
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(networkConnected), name: NotificationManager.Name.NetworkReachable.rawValue, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(networkDisconnected), name: NotificationManager.Name.NetworkUnreachable.rawValue, object: nil)
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(forceLayout), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    @objc fileprivate func networkConnected(_ notification: Notification){
        var timeInterval: TimeInterval = 100
        if let date = dateDisconnected{
            timeInterval = Date().timeIntervalSince(date)
        }
        if ConnectionHandler.Instance.status == .connected && !self.connected && timeInterval > 1 {
            self.connected = true
            self.connectionAquired()
        }
    }
    
    @objc fileprivate func networkDisconnected(_ notification: Notification){
        self.dateDisconnected = Date()
        self.connected = false
        self.connectionLost()
    }
    
    @objc fileprivate func forceLayout(_ notification: Notification){
        var heightOffset: CGFloat = -15
        if self.notificationToolbarVisible {
            heightOffset = 1
        }
        let frame = CGRect(x: 0, y: self.navigationBar.frame.height - heightOffset, width: self.view.frame.width, height: 15)
        notificationToolbar!.frame = frame
        self.navigationBar.layoutSubviews()
    }
    
    fileprivate func setupNotificationToolbar(){
        notificationToolbar = UIToolbar(frame: CGRect(x: 0, y: self.navigationBar.frame.height - 15, width: self.view.frame.width, height: 15))
        
        //label
        self.notificationLabel = UILabel(frame: CGRect(x: 8, y: 0, width: toolbar!.bounds.width - 16, height: 14))
        self.notificationLabel!.font = UIFont.systemFont(ofSize: 8)
        self.notificationLabel!.text = NSLocalizedString("Connecting message...", comment: "Label, Connecting message...")
        notificationToolbar?.addSubview(self.notificationLabel!)
        
        //bottom separator
        let view = UIView(frame: CGRect(x: 0, y: 14, width: toolbar!.bounds.width, height: 1 / UIScreen.main.scale))
        view.backgroundColor = UIColor(red: 200/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1.0)
        self.notificationToolbar?.addSubview(view)
        
        self.notificationToolbar?.clipsToBounds = true
        
        self.navigationBar.addSubview(notificationToolbar!)
        self.navigationBar.sendSubview(toBack: notificationToolbar!)
    }
    
    fileprivate func showNotificationToolbar(){
        if (!self.notificationToolbarVisible){
            self.notificationToolbarVisible = true
            UIView.animate(withDuration: 0.2, animations: { 
                self.notificationToolbar!.frame.origin.y += 16
            })
        }
    }
    
    fileprivate func hideNotificationToolbar(){
        if (self.notificationToolbarVisible){
            self.notificationToolbarVisible = false
            UIView.animate(withDuration: 0.2, animations: {
                self.notificationToolbar!.frame.origin.y -= 16
            })
        }
    }
    
    fileprivate func connectionLost(){
        self.notificationLabel!.text = MessagesProvider.getMessage(.connectionBroken);
        self.showNotificationToolbar()
        
        self.hideNotificationToolbarLater()
    }
    
    fileprivate func connectionAquired(){
        self.notificationLabel!.text = MessagesProvider.getMessage(.connectionConnecting)
        self.showNotificationToolbar()
        
        self.hideNotificationToolbarLater()
    }
    
    fileprivate func hideNotificationToolbarLater(){
        let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        self.operationsCounter += 1
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            self.operationsCounter -= 1
            if (self.operationsCounter == 0){
                self.hideNotificationToolbar()
            }
        }
    }
}
