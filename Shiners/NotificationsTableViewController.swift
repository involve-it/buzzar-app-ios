//
//  NotificationsTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class NotificationsTableViewController: UITableViewController {

    
    @IBOutlet weak var cbNotifications: UISwitch!
    private var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AccountHandler.Instance.currentUser != nil {
            self.currentUser = AccountHandler.Instance.currentUser
        }

        //check notifications switch
        refreshNotification()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    @IBAction func cbNotifications_Changed(sender: UISwitch) {
        if let currentUser = self.currentUser {
            if sender.on && !UIApplication.sharedApplication().isRegisteredForRemoteNotifications(){
                self.showAlert(NSLocalizedString("Notifications", comment: "Alert title, Notifications"), message: NSLocalizedString("To receive notifications, please allow this in device Settings.", comment: "Alert message, to receive notifications, please allow this in device Settings."));
                sender.on = false
            } else {
                let initialState = currentUser.enableNearbyNotifications
                currentUser.enableNearbyNotifications = sender.on
                
                AccountHandler.Instance.saveUser(currentUser) { (success, errorMessage) in
                    if (!success){
                        ThreadHelper.runOnMainThread({
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("An error occurred while saving.", comment: "Alert message, an error occurred while saving."))
                            self.currentUser?.enableNearbyNotifications = initialState
                            sender.on = initialState ?? false
                        })
                    }
                }
            }
        }
    }
    
    func refreshNotification() {
         if let enableNearbyNotifications = self.currentUser?.enableNearbyNotifications {
            self.cbNotifications.on = enableNearbyNotifications
         } else {
            self.cbNotifications.on = false
         }
    }
    

}
