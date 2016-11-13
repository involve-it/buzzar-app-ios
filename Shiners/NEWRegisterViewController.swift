//
//  NEWRegisterViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import Foundation

public class NEWRegisterViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldEmailAddress: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var textFieldConfirmPassword: UITextField!
    
    let txtTitleRegistrationError = NSLocalizedString("Registration error", comment: "Alert title, registration error")
    
    
    
    @IBOutlet var btnRegister: UIBarButtonItem!

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLoading(false, rightBarButtonItem: self.btnRegister)
        
        self.tableView.separatorColor = UIColor.clearColor()
        textFieldConfigure([textFieldUsername, textFieldEmailAddress, textFieldPassword, textFieldConfirmPassword])
        leftPaddingToTextField([textFieldUsername, textFieldEmailAddress, textFieldPassword, textFieldConfirmPassword])
        
        self.navigationController?.navigationBar.setGradientTeamColor()
        configureBackgroundTableView()
    }
    
    func configureBackgroundTableView() {
        let view: GradientView = {
           let v = GradientView()
            v.frame = self.tableView.bounds
            //v.setGradientBlueColor()
            v.backgroundColor = UIColor(netHex: 0x57B8F5)
            return v
        }()
        
        self.tableView.backgroundView = view
    }
    
    func textFieldConfigure(textField: [UITextField]) {
        for item in textField {
            item.layer.cornerRadius = 4.0
        }
    }
    
    public func textFieldDidBeginEditing(textField: UITextField) {
        textFieldAnimationBackgroundShow(textField, alpha: 1)
    }
    
    public func textFieldDidEndEditing(textField: UITextField) {
        textFieldAnimationBackgroundShow(textField, alpha: 0.5)
    }
    
    func textFieldAnimationBackgroundShow(textField: UITextField, alpha: CGFloat) {
        UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
            textField.backgroundColor = UIColor(white: 1, alpha: alpha)
            }, completion: nil)
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.textFieldUsername.becomeFirstResponder();
    }
    
    @objc private func processLogin(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
        ThreadHelper.runOnMainThread({
            if AccountHandler.Instance.currentUser == nil {
                self.setLoading(false, rightBarButtonItem: self.btnRegister)
                self.showAlert(self.txtTitleRegistrationError, message: ResponseHelper.getDefaultErrorMessage())
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }
    
    private func isFormValid() -> Bool {
        var message: String?
        var valid = true
        if self.textFieldUsername.text == nil || self.textFieldUsername.text == "" {
            valid = false
            message = NSLocalizedString("Username cannot be empty", comment: "Alert message, username cannot be empty")
            self.textFieldUsername.becomeFirstResponder()
        } else if self.textFieldEmailAddress.text == nil || self.textFieldEmailAddress == "" || !self.textFieldEmailAddress.text!.isValidEmail() {
            valid = false
            message = NSLocalizedString("Email address is not valid", comment: "Alert message, email address cannot be empty")
            self.textFieldEmailAddress.becomeFirstResponder()
        } else if self.textFieldPassword.text == nil || self.textFieldPassword.text == "" {
            valid = false
            message = NSLocalizedString("Password cannot be empty", comment: "Alert message, password cannot be empty")
            self.textFieldPassword.becomeFirstResponder()
        } else if self.textFieldPassword.text != self.textFieldConfirmPassword.text {
            valid = false
            message = NSLocalizedString("Password and confirmation are not equal", comment: "Alert message, password and confirmation are not equal")
            self.textFieldConfirmPassword.becomeFirstResponder()
        }
        
        if !valid {
            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: message)
        }
        
        return valid
    }
    
    func enableFields(enable: Bool){
        self.textFieldUsername.enabled = enable
        self.textFieldPassword.enabled = enable
        self.textFieldEmailAddress.enabled = enable
        self.textFieldConfirmPassword.enabled = enable
        self.btnRegister.enabled = enable
    }
    
    @objc private func register() {
        if !self.isNetworkReachable(){
            return
        }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        if self.isFormValid() {
            //username
            let username = self.textFieldUsername.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            //password
            let password = self.textFieldPassword.text
            //email and check
            let email = self.textFieldEmailAddress.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            let user = RegisterUser(username: username, email: email, password: password);
        
            ThreadHelper.runOnMainThread({ 
                self.setLoading(true)
                self.enableFields(false)
            })
            
            if ConnectionHandler.Instance.status == .Connected {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
                self.registerUser(user)
            } else {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(register), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            }
        }
    }
    
    private func registerUser(user: RegisterUser){
        AccountHandler.Instance.register(user, callback: { (success, errorId, errorMessage, result) in
            if (success){
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.processLogin), name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
                AccountHandler.Instance.login(user.username!, password: user.password!, callback: { (success, errorId, errorMessage, result) in
                    ThreadHelper.runOnMainThread({
                        if !success {
                            self.enableFields(true)
                            NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
                            self.setLoading(false, rightBarButtonItem: self.btnRegister)
                            self.showAlert(self.txtTitleRegistrationError, message: errorMessage)
                        }
                    })
                })
            } else {
                ThreadHelper.runOnMainThread({
                    self.enableFields(true)
                    self.setLoading(false, rightBarButtonItem: self.btnRegister)
                    self.showAlert(self.txtTitleRegistrationError, message: errorMessage)
                })
            }
        })
    }

    
    // TODO: - duplication code
    public func leftPaddingToTextField(array: [UITextField]) {
        
        for textField in array {
            let paddingView = UIView(frame: CGRectMake(0, 0, 15, textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.Always
        }
        
    }
    
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        //TODO: Make check textField isEmpty
        if (textField === self.textFieldUsername){
            self.textFieldEmailAddress.becomeFirstResponder()
        } else if textField === self.textFieldEmailAddress {
            self.textFieldPassword.becomeFirstResponder()
        } else if textField === self.textFieldPassword {
            self.textFieldConfirmPassword.becomeFirstResponder()
        } else if textField === self.textFieldConfirmPassword {
            self.register()
            textField.resignFirstResponder()
        }
        
        return false
    }

    
    @IBAction func btnRegister_Click(sender: AnyObject) {
        self.register()
    }
    
    @IBAction func btn_Cancel(sender: UIBarButtonItem) {
        //self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func btn_LogIn(sender: UIButton) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("NEWloginNavigationController")
        self.presentViewController(vc!, animated: true, completion: nil)
    }

}


