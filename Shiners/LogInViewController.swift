//
//  LogInViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class LogInViewController: UITableViewController, UITextFieldDelegate{
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    private let registerButton = UIBarButtonItem(title: "Register", style: .Plain, target: nil, action: #selector(btnRegister_Click));
    
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
    
    override func viewDidLoad() {
        //register button
        self.setLoading(false, rightBarButtonItem: self.registerButton);
        self.txtUsername.becomeFirstResponder();
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
    
    func login(){
        if let userName = txtUsername.text where userName != "", let password = txtPassword.text where password != "" {
            setLoading(true, rightBarButtonItem: self.registerButton)
            
            ConnectionHandler.Instance.users.login(userName, password: password, callback: { (success, reason) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.setLoading(false, rightBarButtonItem: self.registerButton)
                    if success {
                        self.dismissSelf();
                    } else {
                        self.showAlert("Log in failed", message: reason)
                    }
                })
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
