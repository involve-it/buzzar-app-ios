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
    @IBAction func btnSave_Click(sender: UIBarButtonItem) {
        self.view.endEditing(true)
    }
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var lblLoginOrRegister: UILabel!
    
    private var currentUser: User?
    private var meteorLoaded = false
    private var accountDetailsPending = false
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        if ConnectionHandler.Instance.status == .Connected {
            self.accountUpdated(nil)
        } else {
            if CachingHandler.Instance.status != .Complete {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
            } else if let currentUser = CachingHandler.Instance.currentUser {
                self.currentUser = currentUser
                self.refreshUser()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(accountUpdated), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(accountUpdated), name: NotificationManager.Name.UserUpdated.rawValue, object: nil)
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
    
    func accountUpdated(object: AnyObject?){
        self.meteorLoaded = true
        self.currentUser = AccountHandler.Instance.currentUser
        self.refreshUser()
        ThreadHelper.runOnMainThread { 
            self.tableView.reloadData()
            
            if self.accountDetailsPending {
                self.setLoading(false)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("profileController")
                self.navigationController?.pushViewController(vc, animated: true);
            }
        }
    }
    
    func refreshUser(){
        if let currentUser = self.currentUser {
            if let firstName = self.currentUser?.getProfileDetailValue(.FirstName),
                lastName = self.currentUser?.getProfileDetailValue(.LastName) {
                lblName.text = "\(firstName) \(lastName)"
            } else {
                lblName.text = currentUser.username;
            }
            lblEmail.text = currentUser.email;
            lblEmail.hidden = false;
            lblName.hidden = false;
            lblLoginOrRegister.hidden = true;
            
            if let imageUrl = currentUser.imageUrl{
                ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
                    dispatch_async(dispatch_get_main_queue(), {
                        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forItem: 0, inSection: 0));
                        self.imgPhoto.image = image;
                        cell?.layoutIfNeeded()
                    })
                })
            } else {
                imgPhoto.image = ImageCachingHandler.defaultAccountImage;
            }
        } else {
            imgPhoto.image = ImageCachingHandler.defaultAccountImage;
            lblEmail.hidden = true;
            lblName.hidden = true;
            lblLoginOrRegister.hidden = false;
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section > Section.social && self.currentUser == nil || section == Section.social && self.currentUser != nil){
            return 0.1;
        } else {
            return super.tableView(tableView, heightForFooterInSection: section);
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section > Section.social && self.currentUser == nil || section == Section.social && self.currentUser != nil){
            return 0.1;
        } else {
            return super.tableView(tableView, heightForFooterInSection: section);
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section > Section.social && self.currentUser == nil || section == Section.social && self.currentUser != nil){
            return 0;
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section > Section.social && self.currentUser == nil || section == Section.social && self.currentUser != nil){
            return nil;
        } else {
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if (indexPath.section == Section.settings){
            return nil;
        } else {
            return indexPath;
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == Section.account){
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if (self.currentUser == nil){
                let vc = storyboard.instantiateViewControllerWithIdentifier("loginNavigationController")
                self.presentViewController(vc, animated: true, completion: nil);
            } else {
                if AccountHandler.Instance.status != .Completed {
                    self.setLoading(true)
                    self.accountDetailsPending = true
                } else {
                    let vc = storyboard.instantiateViewControllerWithIdentifier("profileController")
                    self.navigationController?.pushViewController(vc, animated: true);
                }
            }
        }
        else if (indexPath.section == Section.logOut){
            let alertViewController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .ActionSheet)
            alertViewController.addAction(UIAlertAction(title: "Log out", style: .Destructive, handler: { (_) in
                AccountHandler.Instance.logoff(){ success in
                    if (success){
                        self.currentUser = nil;
                        self.refreshUser();
                        dispatch_async(dispatch_get_main_queue(), {
                            self.tableView.reloadData();
                        })
                    }
                };
            }))
            
            alertViewController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.presentViewController(alertViewController, animated: true, completion: nil)
        } else if indexPath.section == Section.social{
            //facebook
            if indexPath.row == 0{
                AccountHandler.Instance.loginFacebook(NSBundle.mainBundle().infoDictionary!["FacebookAppID"] as! String, viewController: self)
                
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
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    private func showAlertErrorLoginFacebook(){
        self.showAlert("Facebook Login", message: "Error occurred while logging in with Facebook")
    }
    
    @objc private func processLogin(notification: NSNotification){
        ThreadHelper.runOnMainThread {
            self.setLoading(false)
            self.refreshUser()
        }
    }
    
    private struct Section{
        static let account = 0
        static let social = 1
        static let settings = 2
        static let logOut = 3
    }
}
