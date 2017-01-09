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
    fileprivate static let PUSH_TOKEN = "shiners:push-token"
    
    fileprivate static let CHAT = "chat"
    fileprivate static let COMMENT = "comment"
    fileprivate static let POST = "post"
    fileprivate static let DEFAULT = "default"
    
    
    class func saveToken(_ deviceToken: Data) -> String{
        let token = deviceToken.hexString
        UserDefaults.standard.set(token, forKey: PUSH_TOKEN)
        return token
    }
    
    class func getToken() -> String?{
        return UserDefaults.standard.object(forKey: PUSH_TOKEN) as? String
    }
    
    class func handleNotification(_ payloadString: String, rootViewController: MainViewController){
        if let payload = Payload(payload: payloadString), let payloadType = payload.type {
            switch payloadType {
            case CHAT:
                if let chatId = payload.id{
                    AccountHandler.Instance.updateMyChats()
                    rootViewController.selectedIndex = 3
                    let messagesNavigationController = rootViewController.viewControllers![3] as! UINavigationController
                    let messagesViewController = messagesNavigationController.viewControllers[0] as! MessagesViewController
                    messagesViewController.pendingChatId = chatId
                    
                    rootViewController.popNavigationControllerToRoot = 1
                    if messagesNavigationController.visibleViewController !== messagesViewController {
                        messagesNavigationController.visibleViewController?.performSegue(withIdentifier: "unwindMessages", sender: nil)
                    }
                }
            case COMMENT:
                if let postId = payload.id{
                    AccountHandler.Instance.updateMyPosts()
                    rootViewController.selectedIndex = 1
                    let navigationController = rootViewController.viewControllers![1] as! UINavigationController
                    //let myPostsViewController = navigationController.viewControllers[0] as? MyPostsViewController
                    let mainViewController = navigationController.viewControllers[0] as? ProfileMainViewController
                    mainViewController?.typeSwitch.selectedSegmentIndex = 0
                    let myPostsViewController = mainViewController?.myPostsViewController
                    myPostsViewController?.pendingPostId = postId
                    
                    if navigationController.visibleViewController !== mainViewController {
                        //navigationController.visibleViewController?.performSegueWithIdentifier("unwindMyPosts", sender: nil)
                        navigationController.popViewController(animated: true)
                    }
                }
            case POST:
                if let postId = payload.id{
                    rootViewController.selectedIndex = 0
                    let navigationController = rootViewController.viewControllers![0] as! UINavigationController
                    let postsViewController = navigationController.viewControllers[0] as? PostsMainViewController
                    postsViewController?.pendingPostId = postId
                    
                    if navigationController.visibleViewController !== postsViewController {
                        navigationController.visibleViewController?.performSegue(withIdentifier: "unwindPosts", sender: nil)
                    }
                }
            default:
                break
            }
        }
    }
    
    fileprivate class Payload{
        let type: String?
        let id: String?
        
        init?(payload: String){
            if let data = payload.data(using: String.Encoding.utf8), let dict = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? NSDictionary{
                self.type = dict?["type"] as? String
                self.id = dict?["id"] as? String
            } else {
                return nil
            }
        }
    }
}
