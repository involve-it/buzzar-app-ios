//
//  SettingsMainViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/13/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit

class SettingsMainViewController: UITableViewController {
    override func viewDidLoad() {
        self.fillUserData()
        NotificationCenter.default.addObserver(self, selector: #selector(fillUserData), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fillUserData), name: NSNotification.Name(rawValue: NotificationManager.Name.UserUpdated.rawValue), object: nil)
    }
    
    @IBOutlet weak var sendNearbyNotificationsSwitch: UISwitch!
    func fillUserData(){
        if UIApplication.shared.isRegisteredForRemoteNotifications, let currentUser = AccountHandler.Instance.currentUser, (currentUser.enableNearbyNotifications ?? false) {
            self.sendNearbyNotificationsSwitch.isOn = true
        } else {
            self.sendNearbyNotificationsSwitch.isOn = false
        }
    }
    
    @IBAction func cbNotifications_Changed(_ sender: UISwitch) {
        if self.isNetworkReachable(), let currentUser = AccountHandler.Instance.currentUser {
            if sender.isOn && !UIApplication.shared.isRegisteredForRemoteNotifications{
                self.showAlert(NSLocalizedString("Notifications", comment: "Alert title, Notifications"), message: NSLocalizedString("To receive notifications, please allow this in device Settings.", comment: "Alert message, to receive notifications, please allow this in device Settings."));
                sender.isOn = false
            } else {
                let initialState = currentUser.enableNearbyNotifications
                currentUser.enableNearbyNotifications = sender.isOn
                
                AccountHandler.Instance.saveUser(currentUser) { (success, errorMessage) in
                    if (!success){
                        ThreadHelper.runOnMainThread({
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("An error occurred while saving.", comment: "Title message, an error occurred while saving."))
                            currentUser.enableNearbyNotifications = initialState
                            sender.isOn = initialState ?? false
                        })
                    }
                }
            }
        }
    }
}
