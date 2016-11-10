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
    
    let txtTitleRegistrationError = NSLocalizedString("Registration error", comment: "Alert title, registration error")
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public override func viewDidLoad() {
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
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.txtUsername.becomeFirstResponder();
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.processLogin), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
    }
    
    @objc private func processLogin(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        dispatch_async(dispatch_get_main_queue(), {
            self.setLoading(false)
            if AccountHandler.Instance.currentUser != nil {
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            } else {
                self.showAlert("Registration error", message: ResponseHelper.getDefaultErrorMessage())
            }
        })
    }
    
    private func register(){
        if self.txtPassword.text == self.txtConfirmPassword.text {
            let user = RegisterUser(username: self.txtUsername.text, email: self.txtEmail.text, password: self.txtPassword.text);
            if (user.isValid()){
                self.setLoading(true)
                
                AccountHandler.Instance.register(user, callback: { (success, errorId, errorMessage, result) in
                    self.setLoading(false)
                    if (success){
                        AccountHandler.Instance.login(user.username!, password: user.password!, callback: { (success, errorId, errorMessage, result) in
                            if !success {
                                self.showAlert(self.txtTitleRegistrationError, message: errorMessage)
                            }
                        })
                    } else {
                        self.showAlert(self.txtTitleRegistrationError, message: errorMessage)
                    }
                })
                
                return
            }
        }
        
        //todo: add validation messages
        self.showAlert(NSLocalizedString("Validation failed", comment: "Alert title, Validation failed"), message: NSLocalizedString("Form validation valied", comment: "Alert message, Form validation valied"))
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
