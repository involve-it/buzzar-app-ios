//
//  RegisterViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class RegisterViewController: UITableViewController, UITextFieldDelegate{
    
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public override func viewDidLoad() {
        self.txtUsername.becomeFirstResponder();
        self.setLoading(false);
        
        self.txtUsername.delegate = self;
        self.txtEmail.delegate = self;
        self.txtPassword.delegate = self;
        self.txtConfirmPassword.delegate = self;
    }
    
    public override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if (indexPath.section == 1){
            return indexPath;
        } else {
            return nil
        }
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true);
            self.register()
        }
    }
    
    private func setLoading(loading: Bool){
        if (loading){
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray);
            activityIndicator.startAnimating();
            activityIndicator.hidden = false;
            let rightItem = UIBarButtonItem(customView: activityIndicator);
            self.navigationItem.rightBarButtonItem = rightItem;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
    
    private func register(){
        if self.txtPassword.text == self.txtConfirmPassword.text {
            let user = RegisterUser(username: self.txtUsername.text, email: self.txtEmail.text, password: self.txtPassword.text);
            if (user.isValid()){
                self.setLoading(true)
                
                ConnectionHandler.Instance.users.register(user, callback: { (success, errorId) in
                    if (success){
                        ConnectionHandler.Instance.users.login(user.username!, password: user.password!, callback: { (success, reason) in
                            if (success){
                                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                            } else {
                                //todo: add error message
                                self.showErrorMessage()
                            }
                        })
                    } else {
                        //todo: add error message
                        self.showErrorMessage()
                    }
                })
                
                return
            }
        }
        
        //todo: add validation messages
        self.showErrorMessage("Validation failed")
    }
    
    func showErrorMessage(message: String? = "Internal error occurred"){
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField === self.txtUsername){
            self.txtEmail.becomeFirstResponder()
        } else if textField === self.txtEmail {
            self.txtPassword.becomeFirstResponder()
        } else if textField === self.txtPassword {
            self.txtConfirmPassword.becomeFirstResponder()
        } else if textField === self.txtConfirmPassword {
            self.register()
        }
        return false;
    }
}
