//
//  SettingsTableViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class SettingsTableViewController: UITableViewController{
    @IBAction func btnSave_Click(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
    }
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var lblLoginOrRegister: UILabel!
    
    @IBOutlet weak var cbNotifications: UISwitch!
    fileprivate var currentUser: User?
    fileprivate var meteorLoaded = false
    fileprivate var accountDetailsPending = false
    
    @IBAction func cbNotifications_Changed(_ sender: UISwitch) {
        if let currentUser = self.currentUser {
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
                            self.currentUser?.enableNearbyNotifications = initialState
                            sender.isOn = initialState ?? false
                        })
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
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
                let vc = storyboard.instantiateViewController(withIdentifier: "profileController")
                self.navigationController?.pushViewController(vc, animated: true);
            }
        }
    }
    
    func refreshUser(){
        if let currentUser = self.currentUser {
            if let firstName = self.currentUser?.getProfileDetailValue(.FirstName),
                let lastName = self.currentUser?.getProfileDetailValue(.LastName) {
                lblName.text = "\(firstName) \(lastName)"
            } else {
                lblName.text = currentUser.username;
            }
            lblEmail.text = currentUser.email;
            lblEmail.isHidden = false;
            lblName.isHidden = false;
            lblLoginOrRegister.isHidden = true;
            
            if let imageUrl = currentUser.imageUrl{
                ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
                    DispatchQueue.main.async(execute: {
                        let cell = self.tableView.cellForRow(at: IndexPath(item: 0, section: 0));
                        self.imgPhoto.image = image;
                        cell?.layoutIfNeeded()
                    })
                })
            } else {
                imgPhoto.image = ImageCachingHandler.defaultAccountImage;
            }
            
            if let enableNearbyNotifications = self.currentUser?.enableNearbyNotifications{
                self.cbNotifications.isOn = enableNearbyNotifications
            } else {
                self.cbNotifications.isOn = false
            }
        } else {
            imgPhoto.image = ImageCachingHandler.defaultAccountImage;
            lblEmail.isHidden = true;
            lblName.isHidden = true;
            lblLoginOrRegister.isHidden = false;
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section > Section.social && self.currentUser == nil || section == Section.social && self.currentUser != nil){
            return 0.1;
        } else {
            return super.tableView(tableView, heightForFooterInSection: section);
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section > Section.social && self.currentUser == nil || section == Section.social && self.currentUser != nil){
            return 0.1;
        } else {
            return super.tableView(tableView, heightForFooterInSection: section);
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section > Section.social && self.currentUser == nil || section == Section.social && self.currentUser != nil){
            return 0;
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section > Section.social && self.currentUser == nil || section == Section.social && self.currentUser != nil){
            return nil;
        } else {
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if (indexPath.section == Section.settings){
            return nil;
        } else {
            return indexPath;
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == Section.account){
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if (self.currentUser == nil){
                let vc = storyboard.instantiateViewController(withIdentifier: "loginNavigationController")
                self.present(vc, animated: true, completion: nil);
            } else {
                if AccountHandler.Instance.status != .completed {
                    self.setLoading(true)
                    self.accountDetailsPending = true
                } else {
                    let vc = storyboard.instantiateViewController(withIdentifier: "profileController")
                    self.navigationController?.pushViewController(vc, animated: true);
                }
            }
        }
        else if (indexPath.section == Section.logOut){
            let alertViewController = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Alert title, Are you sure?"), message: nil, preferredStyle: .actionSheet)
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Log out", comment: "Alert title, Log out"), style: .destructive, handler: { (_) in
                AccountHandler.Instance.logoff(){ success in
                    if (success){
                        self.currentUser = nil;
                        self.refreshUser();
                        DispatchQueue.main.async(execute: {
                            self.tableView.reloadData();
                        })
                    }
                };
            }))
            
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert title, Cancel"), style: .cancel, handler: nil))
            
            self.present(alertViewController, animated: true, completion: nil)
        } else if indexPath.section == Section.social{
            //facebook
            if indexPath.row == 0{
                //AccountHandler.Instance.loginFacebook(Bundle.main.infoDictionary!["FacebookAppID"] as! String, viewController: self)
                
                /*if let token = FBSDKAccessToken.currentAccessToken(){
                    AccountHandler.Instance.loginFacebook(token.appID, viewController: self)
                } else {
                    FBSDKLoginManager().logInWithReadPermissions(["email", "public_profile"], fromViewController: self, handler: { (loginResult, error) in
                        if error != nil || loginResult.isCancelled {
                            self.showAlertErrorLoginFacebook()
                        } else {
                            AccountHandler.Instance.loginFacebook(loginResult.token.userID, viewController: self)
                        }
                    })
                }*/
                /*FBSDKLoginManager().logInWithPublishPermissions(["email", "public_profile"], fromViewController: self, handler: { (loginResult, error) in
                    if error != nil || loginResult.isCancelled {
                        self.showAlertErrorLoginFacebook()
                    } else {
                        let params = ["fields": "id,name,email"]
                        FBSDKGraphRequest(graphPath: "me", parameters: params).startWithCompletionHandler({ (connection, result, error) in
                            if error != nil, let email = result.valueForKey("email") as? String, id = result.valueForKey("id") as? String {
                                
                                //let user = RegisterUser(username: email, email: email, password: id)
                                
                                //self.setLoading(true)
                                AccountHandler.Instance.register(user, callback: { (success, errorId, errorMessage, result) in
                                    if (success){
                                        AccountHandler.Instance.login(user.username!, password: user.password!, callback: { (success, errorId, errorMessage, result) in
                                            if (success){
                                                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.processLogin), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
                                            } else {
                                                self.showAlertErrorLoginFacebook()
                                            }
                                        })
                                    } else {
                                        self.setLoading(false)
                                        self.showAlertErrorLoginFacebook()
                                    }
                                })

                            } else {
                                self.showAlertErrorLoginFacebook()
                            }
                        })
                    }
                })*/
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    fileprivate func showAlertErrorLoginFacebook(){
        self.showAlert(NSLocalizedString("Facebook Login", comment: "Alert title, Facebook Login"), message: NSLocalizedString("Error occurred while logging in with Facebook", comment: "Alert message, Error occurred while logging in with Facebook"))
    }
    
    @objc fileprivate func processLogin(_ notification: Notification){
        ThreadHelper.runOnMainThread {
            self.setLoading(false)
            self.refreshUser()
        }
    }
    
    fileprivate struct Section{
        static let account = 0
        static let social = 1
        static let settings = 2
        static let logOut = 3
    }
}
