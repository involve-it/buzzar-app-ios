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
        
        NotificationCenter.default.addObserver(self, selector: #selector(pushRegistrationFailed), name: NSNotification.Name(rawValue: NotificationManager.Name.PushRegistrationFailed.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoggedIn), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocalNotification), name: NSNotification.Name(rawValue: NotificationManager.Name.ServerEventNotification.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(displaySettings), name: NSNotification.Name(rawValue: NotificationManager.Name.DisplaySettings.rawValue), object: nil)
        //buttonCreatePost()
    }
    
    func displaySettings(){
        if AccountHandler.Instance.isLoggedIn() {
            self.selectedIndex = 4
        } else {
            self.selectedIndex = 2
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !AccountHandler.Instance.isLoggedIn() && !AccountHandler.hasSeenWelcomeScreen() {
            let storyboardMain = UIStoryboard(name: "Main", bundle: nil)
            let welcomeViewController = storyboardMain.instantiateViewController(withIdentifier: "welcomeScreen")
            self.present(welcomeViewController, animated: true, completion: nil)
            AccountHandler.setSeenWelcomeScreen(true)
        }
        
        if ExceptionHandler.hasLastCrash() {
            let alertController = UIAlertController(title: NSLocalizedString("Oops", comment: "Alert title, Oops"), message: NSLocalizedString("Looks like we crashed last time. Would you like to help developers and send crash report?", comment: "Alert message, Looks like we crashed last time. Would you like to help developers and send crash report?"), preferredStyle: .alert);
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Sure!", comment: "Alert title, Yes"), style: .default, handler:{ (action) in
                ExceptionHandler.submitReport()
                alertController.dismiss(animated: true, completion: nil)
            }));
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: "Alert title, Cancel"), style: .cancel, handler: { (action) in
                ExceptionHandler.cleanUp()
            }));
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func receivedLocalNotification(_ notification: Notification){
        if AccountHandler.Instance.isLoggedIn() {
            let notificaionEvent = notification.object as! LocalNotificationEvent
            var index: Int
            switch notificaionEvent.view {
            case .posts:
                index = 0
            case .messages:
                index = 3
            case .myPosts:
                index = 1
            default:
                index = -1
            }
            if index > -1 {
                self.setBadgeValue(index, count: notificaionEvent.count)
            }
        }
    }
    
    fileprivate func setBadgeValue(_ index: Int, count: Int){
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
        let createPostButton = UIButton(frame: CGRect(x: createPostItemWidth * 2, y: self.view.frame.size.height - createPostItemHeight, width: createPostItemWidth, height: createPostItemHeight))
        createPostButton.setBackgroundImage(UIImage(named: "createPostButton.png"), for: UIControlState())
        createPostButton.adjustsImageWhenHighlighted = false
        createPostButton.addTarget(self, action: #selector(createPostAdd), for: .touchUpInside)
        self.view.addSubview(createPostButton)
    }
    
    func createPostAdd(_ sender: UIButton) {
        //self.selectedIndex = 2
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var controller: UIViewController
        if AccountHandler.Instance.isLoggedIn(){
            controller = storyboard.instantiateViewController(withIdentifier: "addPost");
        } else {
            controller = storyboard.instantiateViewController(withIdentifier: "NEWloginNavigationController");
        }
        self.present(controller, animated: true, completion: nil)
        
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
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.title == "addPostPlaceholder" {
            if AccountHandler.Instance.isLoggedIn(){
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "addPost");
                self.present(controller, animated: true, completion: nil)
            } else {
                //controller = storyboard.instantiateViewControllerWithIdentifier("NEWloginNavigationController");
                self.selectedIndex = 2
            }
            return false;
        }
        return true;
    }

    @objc fileprivate func pushRegistrationFailed(_ object: AnyObject?){
        if AccountHandler.Instance.isLoggedIn() {
            AccountHandler.Instance.currentUser?.enableNearbyNotifications = false
            NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
        }
        
        /*ThreadHelper.runOnMainThread {
            self.showAlert("Error", message: "Error subscribing to notifications");
        }*/
    }
    //unwind close newPostViewController
    @IBAction func closeNewPostViewControlle(_ segue: UIStoryboardSegue) {}

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
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let index = self.allViewControllers.index(of: viewController)!
        switch index {
        case 0:
            if AccountHandler.Instance.isLoggedIn(){
                LocalNotificationsHandler.Instance.reportActiveView(.posts)
            }
            self.setBadgeValue(0, count: 0)
        case 3:
            if AccountHandler.Instance.isLoggedIn(){
                LocalNotificationsHandler.Instance.reportActiveView(.messages)
            }
        case 1:
            if AccountHandler.Instance.isLoggedIn(){
                LocalNotificationsHandler.Instance.reportActiveView(.myPosts)
            }
        case 4:
            break
        case 5:
            break
        default:
            if AccountHandler.Instance.isLoggedIn(){
                LocalNotificationsHandler.Instance.reportActiveView(.other)
            }
        }
        
    }
}

