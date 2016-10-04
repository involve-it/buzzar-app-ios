//
//  LogInViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class LogInViewController: UITableViewController, UITextFieldDelegate{
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    private let registerButton = UIBarButtonItem(title: NSLocalizedString("Register", comment: "Button title, Register"), style: .Plain, target: nil, action: #selector(btnRegister_Click));
    
    let txtTitleLogInFaild = NSLocalizedString("Log in failed", comment: "Alert title, Log in failed")
    
    @IBAction func btnRegister_Click(sender: AnyObject) {
        let presentingViewController = self.presentingViewController;
        self.navigationController?.dismissViewControllerAnimated(true, completion: { 
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("registerNavigationController")
            presentingViewController!.presentViewController(vc, animated: true, completion: nil)
        })
    }
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.dismissSelf();
    }
    
    private func dismissSelf(){
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil);
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.txtUsername.becomeFirstResponder();
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.processLogin), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
    }
    
    override func viewDidLoad() {
        //register button
        self.setLoading(false, rightBarButtonItem: self.registerButton);
        self.txtPassword.delegate = self;
        self.txtUsername.delegate = self;
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 2 && indexPath.row == 0{
            return indexPath;
        } else {
            return nil;
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 && indexPath.row == 0{
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
            
            self.login();
        } 
    }
    
    func processLogin(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        dispatch_async(dispatch_get_main_queue(), {
            self.setLoading(false, rightBarButtonItem: self.registerButton)
            if AccountHandler.Instance.currentUser != nil {
                //AccountHandler.Instance.requestPushNotifications()
                self.dismissSelf();
            } else {
                self.showAlert(self.txtTitleLogInFaild, message: ResponseHelper.getDefaultErrorMessage())
            }
        })
    }
    
    func login(){
        if let userName = txtUsername.text where userName != "", let password = txtPassword.text where password != "" {
            setLoading(true, rightBarButtonItem: self.registerButton)
            
            AccountHandler.Instance.login(userName, password: password, callback: { (success, errorId, errorMessage, result) in
                if !success {
                    ThreadHelper.runOnMainThread({
                        self.showAlert(self.txtTitleLogInFaild, message: errorMessage)
                    })
                }
            })
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField === self.txtPassword){
            self.login()
        } else if (textField === self.txtUsername){
            self.txtPassword.becomeFirstResponder()
        }
        return false;
    }
}
