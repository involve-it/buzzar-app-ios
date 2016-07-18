//
//  ViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(pushRegistrationFailed), name: NotificationManager.Name.PushRegistrationFailed.rawValue, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if viewController.title == "addPostPlaceholder" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewControllerWithIdentifier("addPost");
            self.presentViewController(controller, animated: true, completion: nil)
            return false;
        }
        return true;
    }

    @objc private func pushRegistrationFailed(object: AnyObject?){
        if UsersProxy.Instance.isLoggedIn() {
            AccountHandler.Instance.currentUser?.enableNearbyNotifications = false
            NotificationManager.sendNotification(NotificationManager.Name.AccountUpdated, object: nil)
        }
        
        /*ThreadHelper.runOnMainThread {
            self.showAlert("Error", message: "Error subscribing to notifications");
        }*/
    }
    //unwind close newPostViewController
    @IBAction func closeNewPostViewControlle(segue: UIStoryboardSegue) {}


}

