//
//  SettingsProfileTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/17/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class SettingsProfileTableViewController: UITableViewController {

    fileprivate var currentUser: User?
    fileprivate var meteorLoaded = false
    fileprivate var accountDetailsPending = false
    
    
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var txtUsername: UILabel!
    
    var modalSpinner: UIAlertController?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if ConnectionHandler.Instance.status == .connected {
            self.accountUpdated(nil)
        } else {
            if CachingHandler.Instance.status != .complete {
                NotificationCenter.default.addObserver(self, selector: #selector(showOfflineData), name: NSNotification.Name(rawValue: NotificationManager.Name.OfflineCacheRestored.rawValue), object: nil)
            } else if let currentUser = CachingHandler.Instance.currentUser {
                self.currentUser = currentUser
                self.refreshUser()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(accountUpdated), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accountUpdated), name: NSNotification.Name(rawValue: NotificationManager.Name.UserUpdated.rawValue), object: nil)
        
        getUserData()
        
        //conf. LeftMenu
        //self.configureOfLeftMenu()
        //self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func getUserData() {
        if let currentUser = self.currentUser {

            //Username
            if let firstName = self.currentUser?.getProfileDetailValue(.FirstName),
                let lastName = self.currentUser?.getProfileDetailValue(.LastName) {
                txtUsername.text = "\(firstName) \(lastName)"
            } else {
                txtUsername.text = currentUser.username
            }
            
            //Avatar
            if let imageUrl = currentUser.imageUrl{
                ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
                    DispatchQueue.main.async(execute: {
                        self.imgUserAvatar.image = image
                    })
                })
            } else {
                imgUserAvatar.image = ImageCachingHandler.defaultAccountImage;
            }
            
            //
            
        }
    }
    
    
    func showOfflineData(){
        if !self.meteorLoaded {
            self.currentUser = CachingHandler.Instance.currentUser
            self.refreshUser()
            ThreadHelper.runOnMainThread {
                self.tableView.reloadData()
            }
        }
    }
    
    func accountUpdated(_ object: AnyObject?){
        self.meteorLoaded = true
        self.currentUser = AccountHandler.Instance.currentUser
        self.refreshUser()
        ThreadHelper.runOnMainThread {
            self.tableView.reloadData()
            
            if self.accountDetailsPending {
                self.setLoading(false)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "editProfileController")
                self.navigationController?.pushViewController(vc, animated: true);
            }
        }
    }
    
    func refreshUser(){
        if let currentUser = self.currentUser {
            
            if let imageUrl = currentUser.imageUrl{
                ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
                    DispatchQueue.main.async(execute: {
                        let cell = self.tableView.cellForRow(at: IndexPath(item: 0, section: 0));
                        self.imgUserAvatar.image = image;
                        cell?.layoutIfNeeded()
                    })
                })
            } else {
                imgUserAvatar.image = ImageCachingHandler.defaultAccountImage;
            }
        } else {
            imgUserAvatar.image = ImageCachingHandler.defaultAccountImage;
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 4 {
            AppAnalytics.logEvent(.SettingsLoggedInScreen_Logout)
            let alertViewController = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Alert title, Are you sure?"), message: nil, preferredStyle: .actionSheet)
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Log out", comment: "Alert title, Log out"), style: .destructive, handler: { (_) in
                AppAnalytics.logEvent(.SettingsLoggedInScreen_DoLogout)
                self.doLogout()
            }))
            
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert title, Cancel"), style: .cancel, handler: { (_) in
                AppAnalytics.logEvent(.SettingsLoggedInScreen_CancelLogout)
            }))
            
            self.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    func doLogout(){
        if self.modalSpinner == nil {
            self.modalSpinner = self.displayModalAlert("Logging out...")
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        if ConnectionHandler.Instance.status == .connected {
            AccountHandler.Instance.logoff(){ success in
                ThreadHelper.runOnMainThread({
                    self.modalSpinner?.dismiss(animated: true, completion: nil)
                    if (!success){
                        self.showAlert(NSLocalizedString("Error", comment: "Alert, Error"), message: NSLocalizedString("An error occurred", comment: "Alert message, An error occurred"))
                    }
                })
            }
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(doLogout), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }
    
    //MARK: - Action
   

    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     if segue.identifier == "settingToNotification" {
     let vc:NotificationsTableViewController = segue.destinationViewController as! NotificationsTableViewController
     }
     }
     */
}
