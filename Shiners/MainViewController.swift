//
//  ViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController, UITabBarControllerDelegate {
    
    var popNavigationControllerToRoot: Int?
    var allViewControllers: [UIViewController]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.allViewControllers = self.viewControllers
        
        self.updateLoggedIn()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(pushRegistrationFailed), name: NotificationManager.Name.PushRegistrationFailed.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateLoggedIn), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedLocalNotification), name: NotificationManager.Name.ServerEventNotification.rawValue, object: nil)
        
        //buttonCreatePost()
    }
    
    func receivedLocalNotification(notification: NSNotification){
        if AccountHandler.Instance.isLoggedIn() {
            let notificaionEvent = notification.object as! LocalNotificationEvent
            var index: Int
            switch notificaionEvent.view {
            case .Posts:
                index = 0
            case .Messages:
                index = 1
            case .MyPosts:
                index = 3
            default:
                index = -1
            }
            if index > -1 {
                self.setBadgeValue(index, count: notificaionEvent.count)
            }
        }
    }
    
    private func setBadgeValue(index: Int, count: Int){
        ThreadHelper.runOnMainThread { 
            if count == 0 {
                self.tabBar.items![index].badgeValue = nil
            } else {
                self.tabBar.items![index].badgeValue = "\(count)"
            }
        }
    }
    
    //Custom button CreatePost
    func buttonCreatePost() {
        let createPostItemWidth = self.view.frame.size.width / 5
        let createPostItemHeight = self.tabBar.frame.size.height
        let createPostButton = UIButton(frame: CGRectMake(createPostItemWidth * 2, self.view.frame.size.height - createPostItemHeight, createPostItemWidth, createPostItemHeight))
        createPostButton.setBackgroundImage(UIImage(named: "createPostButton.png"), forState: .Normal)
        createPostButton.adjustsImageWhenHighlighted = false
        createPostButton.addTarget(self, action: #selector(createPostAdd), forControlEvents: .TouchUpInside)
        self.view.addSubview(createPostButton)
    }
    
    func createPostAdd(sender: UIButton) {
        //self.selectedIndex = 2
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var controller: UIViewController
        if AccountHandler.Instance.isLoggedIn(){
            controller = storyboard.instantiateViewControllerWithIdentifier("addPost");
        } else {
            controller = storyboard.instantiateViewControllerWithIdentifier("NEWloginNavigationController");
        }
        self.presentViewController(controller, animated: true, completion: nil)
        
    }
    
    func updateLoggedIn(){
        if AccountHandler.Instance.isLoggedIn() {
            if self.viewControllers!.count != 5 {
                self.viewControllers = [self.allViewControllers[0], self.allViewControllers[1], self.allViewControllers[2], self.allViewControllers[3], self.allViewControllers[5]]
                self.selectedIndex = 0
            }
            
            self.setBadgeValue(0, count: 0)
            self.setBadgeValue(1, count: 0)
            self.setBadgeValue(3, count: 0)
        } else {
            if self.viewControllers!.count != 3 {
                self.viewControllers = [self.allViewControllers[0], self.allViewControllers[2], self.allViewControllers[4]]
                self.selectedIndex = 0
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if viewController.title == "addPostPlaceholder" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            var controller: UIViewController
            if AccountHandler.Instance.isLoggedIn(){
                controller = storyboard.instantiateViewControllerWithIdentifier("addPost");
            } else {
                controller = storyboard.instantiateViewControllerWithIdentifier("NEWloginNavigationController");
            }
            self.presentViewController(controller, animated: true, completion: nil)
            return false;
        }
        return true;
    }

    @objc private func pushRegistrationFailed(object: AnyObject?){
        if AccountHandler.Instance.isLoggedIn() {
            AccountHandler.Instance.currentUser?.enableNearbyNotifications = false
            NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
        }
        
        /*ThreadHelper.runOnMainThread {
            self.showAlert("Error", message: "Error subscribing to notifications");
        }*/
    }
    //unwind close newPostViewController
    @IBAction func closeNewPostViewControlle(segue: UIStoryboardSegue) {}

    /*func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if self.popNavigationControllerToRoot == self.selectedIndex, let navController = viewController as? UINavigationController {
            navController.popToRootViewControllerAnimated(false)
            self.popNavigationControllerToRoot = nil
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.popNavigationControllerToRoot == self.selectedIndex, let navController = self.selectedViewController as? UINavigationController {
            navController.popToRootViewControllerAnimated(false)
            self.popNavigationControllerToRoot = nil
        }
    }*/
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if AccountHandler.Instance.isLoggedIn(){
            let index = self.allViewControllers.indexOf(viewController)!
            switch index {
            case 0:
                LocalNotificationsHandler.Instance.reportActiveView(.Posts)
                self.setBadgeValue(0, count: 0)
            case 1:
                LocalNotificationsHandler.Instance.reportActiveView(.Messages)
            case 3:
                LocalNotificationsHandler.Instance.reportActiveView(.MyPosts)
            default:
                LocalNotificationsHandler.Instance.reportActiveView(.Other)
            }
        }
    }
}

