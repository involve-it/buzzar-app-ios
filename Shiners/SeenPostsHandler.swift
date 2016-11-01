//
//  SeenPostsHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 10/31/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class SeenPostsHandler{
    class func updateSeenCounter(id: String) -> (incrementToday: Bool, incrementTotal: Bool){
        var incrementTotal = false
        if CachingHandler.Instance.seenPostIds == nil || CachingHandler.Instance.seenPostIds!.indexOf(id) == nil{
            incrementTotal = true
        }
        if let lastSeenPostReport = CachingHandler.Instance.lastSeenPostIdReport where !NSCalendar.currentCalendar().isDateInToday(lastSeenPostReport) {
            CachingHandler.Instance.todaySeenPostIds = nil
        }
        var incrementToday = false
        if CachingHandler.Instance.todaySeenPostIds == nil || CachingHandler.Instance.todaySeenPostIds!.indexOf(id) == nil{
            incrementToday = true
        }
        if CachingHandler.Instance.status == .Complete && incrementTotal {
            print ("Updating seen counter for post: \(id)")
            ConnectionHandler.Instance.posts.incrementSeenCounters(id, incrementTotal: incrementTotal, incrementToday: incrementToday, callback: { (success, errorId, errorMessage, result) in
                if success {
                    var seenPostIds = CachingHandler.Instance.seenPostIds ?? [String]()
                    if seenPostIds.indexOf(id) == nil {
                        seenPostIds.append(id)
                        CachingHandler.Instance.saveSeenPostIds(seenPostIds)
                    }
                    
                    var todaySeenPostIds = CachingHandler.Instance.todaySeenPostIds ?? [String]()
                    if todaySeenPostIds.indexOf(id) == nil {
                        todaySeenPostIds.append(id)
                        CachingHandler.Instance.saveTodaySeenPostIds(todaySeenPostIds)
                    }
                    
                    print ("Successfully updated seen counter for post: \(id)")
                } else {
                    print ("Seen counter update failed for post: \(id)")
                }
            })
        }
        
        return (incrementToday, incrementTotal)
    }
}