//
//  LocalNotificationsHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 9/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit
import BRYXBanner

class LocalNotificationsHandler{
    var activeView: AppView = .posts
    var activeViewId: String?
    fileprivate var newEvents = Dictionary<AppView, NotificationCounter>()
    
    let bannerBackgroundColor = UIColor(red: 0, green: 122/255.0, blue: 1, alpha: 1)
    
    func showBanner(_ title: String, subtitle: String){
        let banner = Banner(title: title, subtitle: subtitle, image: nil, backgroundColor: self.bannerBackgroundColor, didTapBlock: nil)
        banner.dismissesOnTap = true
        ThreadHelper.runOnMainThread({
            banner.show(duration: 1.0)
        })
    }
    
    func getTotalEventCount() -> Int {
        return newEvents.values.reduce(0, { (i, counter) -> Int in
            return i + counter.totalCount
        })
    }
    
    func getNewEventCount(_ view: AppView) -> Int {
        let event = self.newEvents[view]!
        return event.totalCount
    }
    
    func reportNewEvent(_ view: AppView, count: Int = 1, id: String? = nil, messageTitle: String? = nil, messageSubtitle: String? = nil){
        let event = self.newEvents[view]!
        event.addCounter(count, id: id)
        
        if self.activeView == .posts && view == .posts {
            event.subtractCounter()
        } else {
            self.sendLocalNotification(view, count: event.totalCount)
            if !self.isActive(view, id: id), let msgTitle = messageTitle, let msgSubtitle = messageSubtitle {
                self.showBanner(msgTitle, subtitle: msgSubtitle)
            }
        }
    }
    
    func reportEventSeen(_ view: AppView, id: String? = nil){
        let event = self.newEvents[view]!
        event.subtractCounter(id)
        
        self.sendLocalNotification(view, count: event.totalCount)
    }
    
    func reportActiveView(_ view: AppView, id: String? = nil){
        self.activeView = view
        self.activeViewId = id
    }
    
    func isActive(_ view: AppView, id: String? = nil) -> Bool{
        return self.activeView == view && self.activeViewId == id
    }
    
    fileprivate func sendLocalNotification(_ view: AppView, count: Int){
        UIApplication.shared.applicationIconBadgeNumber = self.getTotalEventCount()
        let notificationEvent = LocalNotificationEvent(view: view, count: count)
        NotificationManager.sendNotification(NotificationManager.Name.ServerEventNotification, object: notificationEvent)
    }
    
    fileprivate class func isAppInForeground() -> Bool{
        return UIApplication.shared.applicationState == .active
    }
    
    //singleton
    fileprivate init(){
        for view in [AppView.posts, AppView.messages, AppView.myPosts] {
            self.newEvents[view] = NotificationCounter(view: view)
        }
    }
    
    fileprivate static let instance: LocalNotificationsHandler = LocalNotificationsHandler();
    class var Instance: LocalNotificationsHandler {
        return instance;
    }
    
    fileprivate class NotificationCounter{
        var totalCount: Int = 0
        var individualCounters = Array<String>()
        let view: AppView
        
        init(view: AppView){
            self.view = view
        }
        
        func addCounter(_ count: Int = 1, id: String? = nil){
            self.totalCount += count
            if let _id = id  {
                if !self.individualCounters.contains(_id){
                    self.individualCounters.append(_id)
                }
                self.totalCount = self.individualCounters.count
            }
        }
        
        func subtractCounter(_ id:String? = nil){
            if let _id = id {
                if let index = self.individualCounters.index(of: _id){
                    self.individualCounters.remove(at: index)
                }
                self.totalCount = self.individualCounters.count
            } else if self.individualCounters.count == 0 {
                self.totalCount = 0
            }
        }
    }
}

class LocalNotificationEvent {
    let view: AppView
    let count: Int
    
    init(view: AppView, count: Int){
        self.view = view
        self.count = count
    }
}

enum AppView{
    case posts, messages, myPosts, other
}
