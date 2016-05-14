//
//  SettingsTableViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController{
    @IBAction func btnSave_Click(sender: UIBarButtonItem) {
        self.view.endEditing(true)
    }
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var lblLoginOrRegister: UILabel!
    
    private var userName: String?;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(userUpdated), name: NotificationManager.Name.UserUpdated.rawValue, object: nil)
    }
    
    func userUpdated(object: AnyObject?){
        self.refreshUser()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        if let currentUser = ConnectionHandler.Instance.users.currentUser{
            if (currentUser.username != self.userName){
                self.refreshUser();
            }
            self.tableView.reloadData();
        } else if self.userName != nil{
            self.refreshUser();
            self.tableView.reloadData();
        }
    }
    
    func refreshUser(){
        if let currentUser = ConnectionHandler.Instance.users.currentUser{
            self.userName = currentUser.username;
            if let firstName = ConnectionHandler.Instance.users.currentUser?.getProfileDetailValue(.FirstName),
                lastName = ConnectionHandler.Instance.users.currentUser?.getProfileDetailValue(.LastName) {
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
        if (section > 0 && self.userName == nil){
            return 0.1;
        } else {
            return super.tableView(tableView, heightForFooterInSection: section);
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section > 0 && self.userName == nil){
            return 0.1;
        } else {
            return super.tableView(tableView, heightForFooterInSection: section);
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section > 0 && self.userName == nil){
            return 0;
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section > 0 && self.userName == nil){
            return nil;
        } else {
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if (indexPath.section == 1){
            return nil;
        } else {
            return indexPath;
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == 0){
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if (self.userName == nil){
                let vc = storyboard.instantiateViewControllerWithIdentifier("loginNavigationController")
                self.presentViewController(vc, animated: true, completion: nil);
            } else {
                let vc = storyboard.instantiateViewControllerWithIdentifier("profileController")
                self.navigationController?.pushViewController(vc, animated: true);
            }
        }
        else if (indexPath.section == 2){
            let alertViewController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .ActionSheet)
            alertViewController.addAction(UIAlertAction(title: "Log out", style: .Destructive, handler: { (_) in
                ConnectionHandler.Instance.users.logoff(){ success in
                    if (success){
                        self.userName = nil;
                        self.refreshUser();
                        dispatch_async(dispatch_get_main_queue(), {
                            self.tableView.reloadData();
                        })
                    }
                };
            }))
            
            alertViewController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.presentViewController(alertViewController, animated: true, completion: nil)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
