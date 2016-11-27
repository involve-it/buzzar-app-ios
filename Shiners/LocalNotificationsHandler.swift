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
    var activeView: AppView = .Posts
    var activeViewId: String?
    private var newEvents = Dictionary<AppView, NotificationCounter>()
    
    let bannerBackgroundColor = UIColor(red: 0, green: 122/255.0, blue: 1, alpha: 1)
    
    func showBanner(title: String, subtitle: String){
        let banner = Banner(title: title, subtitle: subtitle, image: nil, backgroundColor: self.bannerBackgroundColor, didTapBlock: nil)
        banner.dismissesOnTap = true
        ThreadHelper.runOnMainThread({
            banner.show(duration: 1.0)
        })
    }
    
    func getTotalEventCount() -> Int {
        return newEvents.values.reduce(0, combine: { (i, counter) -> Int in
            return i + counter.totalCount
        })
    }
    
    func getNewEventCount(view: AppView) -> Int {
        let event = self.newEvents[view]!
        return event.totalCount
    }
    
    func reportNewEvent(view: AppView, count: Int = 1, id: String? = nil, messageTitle: String? = nil, messageSubtitle: String? = nil){
        let event = self.newEvents[view]!
        event.addCounter(count, id: id)
        
        if self.activeView == .Posts && view == .Posts {
            event.subtractCounter()
        } else {
            self.sendLocalNotification(view, count: event.totalCount)
            if !self.isActive(view, id: id), let msgTitle = messageTitle, msgSubtitle = messageSubtitle {
                self.showBanner(msgTitle, subtitle: msgSubtitle)
            }
        }
    }
    
    func reportEventSeen(view: AppView, id: String? = nil){
        let event = self.newEvents[view]!
        event.subtractCounter(id)
        
        self.sendLocalNotification(view, count: event.totalCount)
    }
    
    func reportActiveView(view: AppView, id: String? = nil){
        self.activeView = view
        self.activeViewId = id
    }
    
    func isActive(view: AppView, id: String? = nil) -> Bool{
        return self.activeView == view && self.activeViewId == id
    }
    
    private func sendLocalNotification(view: AppView, count: Int){
        UIApplication.sharedApplication().applicationIconBadgeNumber = self.getTotalEventCount()
        let notificationEvent = LocalNotificationEvent(view: view, count: count)
        NotificationManager.sendNotification(NotificationManager.Name.ServerEventNotification, object: notificationEvent)
    }
    
    private class func isAppInForeground() -> Bool{
        return UIApplication.sharedApplication().applicationState == .Active
    }
    
    //singleton
    private init(){
        for view in [AppView.Posts, AppView.Messages, AppView.MyPosts] {
            self.newEvents[view] = NotificationCounter(view: view)
        }
    }
    
    private static let instance: LocalNotificationsHandler = LocalNotificationsHandler();
    class var Instance: LocalNotificationsHandler {
        return instance;
    }
    
    private class NotificationCounter{
        var totalCount: Int = 0
        var individualCounters = Array<String>()
        let view: AppView
        
        init(view: AppView){
            self.view = view
        }
        
        func addCounter(count: Int = 1, id: String? = nil){
            self.totalCount += count
            if let _id = id  {
                if !self.individualCounters.contains(_id){
                    self.individualCounters.append(_id)
                }
                self.totalCount = self.individualCounters.count
            }
        }
        
        func subtractCounter(id:String? = nil){
            if let _id = id {
                if let index = self.individualCounters.indexOf(_id){
                    self.individualCounters.removeAtIndex(index)
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
    case Posts, Messages, MyPosts, Other
}