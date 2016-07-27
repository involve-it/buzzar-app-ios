//
//  PushNotificationsHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 7/17/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit

class PushNotificationsHandler{
    private static let PUSH_TOKEN = "shiners:push-token"
    
    private static let CHAT = "chat"
    private static let COMMENT = "comment"
    private static let POST = "post"
    private static let DEFAULT = "default"
    
    
    class func saveToken(deviceToken: NSData) -> String{
        let token = deviceToken.hexString
        NSUserDefaults.standardUserDefaults().setObject(token, forKey: PUSH_TOKEN)
        return token
    }
    
    class func getToken() -> String?{
        return NSUserDefaults.standardUserDefaults().objectForKey(PUSH_TOKEN) as? String
    }
    
    class func handleNotification(payloadString: String, rootViewController: MainViewController){
        
        
        if let payload = Payload(payload: payloadString), payloadType = payload.type {
            switch payloadType {
            case CHAT:
                if let chatId = payload.id{
                    let messagesNavigationController = rootViewController.viewControllers![1] as! UINavigationController
                    let messagesViewController = messagesNavigationController.viewControllers[0] as! MessagesViewController
                    messagesViewController.pendingChatId = chatId
                    
                    rootViewController.popNavigationControllerToRoot = 1
                    rootViewController.selectedIndex = 1
                    if messagesNavigationController.visibleViewController !== messagesViewController {
                        messagesNavigationController.visibleViewController?.performSegueWithIdentifier("unwindMessages", sender: nil)
                    }
                }
            case COMMENT:
                if let postId = payload.id{
                    rootViewController.selectedIndex = 3
                    let navigationController = rootViewController.viewControllers![3] as! UINavigationController
                    let myPostsViewController = navigationController.viewControllers[0] as? MyPostsViewController
                    myPostsViewController?.pendingPostId = postId
                    
                    if navigationController.visibleViewController !== myPostsViewController {
                        navigationController.visibleViewController?.performSegueWithIdentifier("unwindMyPosts", sender: nil)
                    }
                }
            case POST:
                if let postId = payload.id{
                    rootViewController.selectedIndex = 0
                    let navigationController = rootViewController.viewControllers![0] as! UINavigationController
                    let postsViewController = navigationController.viewControllers[0] as? PostsViewController
                    postsViewController?.pendingPostId = postId
                    
                    if navigationController.visibleViewController !== postsViewController {
                        navigationController.visibleViewController?.performSegueWithIdentifier("unwindPosts", sender: nil)
                    }
                }
            default:
                break
            }
        }
    }
    
    private class Payload{
        let type: String?
        let id: String?
        
        init?(payload: String){
            if let data = payload.dataUsingEncoding(NSUTF8StringEncoding), dict = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? NSDictionary{
                self.type = dict?["type"] as? String
                self.id = dict?["id"] as? String
            } else {
                return nil
            }
        }
    }
}