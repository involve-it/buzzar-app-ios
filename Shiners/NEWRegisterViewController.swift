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
    
    
    @IBOutlet weak var btnRegister: UIBarButtonItem!

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLoading(false, rightBarButtonItem: self.btnRegister)
        
        self.tableView.separatorColor = UIColor.clearColor()
        textFieldConfigure([textFieldUsername, textFieldEmailAddress, textFieldPassword, textFieldConfirmPassword])
        leftPaddingToTextField([textFieldUsername, textFieldEmailAddress, textFieldPassword, textFieldConfirmPassword])
    }
    
    func textFieldConfigure(textField: [UITextField]) {
        for item in textField {
            item.layer.cornerRadius = 4.0
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.textFieldUsername.becomeFirstResponder();
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.processLogin), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
    }
    
    @objc private func processLogin(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        ThreadHelper.runOnMainThread({
            if AccountHandler.Instance.currentUser == nil {
                self.setLoading(false, rightBarButtonItem: self.btnRegister)
                self.showAlert(self.txtTitleRegistrationError, message: ResponseHelper.getDefaultErrorMessage())
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }
    
    private func register() {
        if self.textFieldPassword.text == self.textFieldConfirmPassword.text {
           
            //username
            let username = self.textFieldUsername.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            //password
            let password = self.textFieldPassword.text
            //email and check
            var email: String? = self.textFieldEmailAddress.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            email = email!.isValidEmail() ? email : nil
            
            let user = RegisterUser(username: username, email: email, password: password);
            if (user.isValid()){
                self.setLoading(true)
                
                AccountHandler.Instance.register(user, callback: { (success, errorId, errorMessage, result) in
                    if (success){
                        AccountHandler.Instance.login(user.username!, password: user.password!, callback: { (success, errorId, errorMessage, result) in
                            ThreadHelper.runOnMainThread({
                                if !success {
                                    self.setLoading(false, rightBarButtonItem: self.btnRegister)
                                    self.showAlert(self.txtTitleRegistrationError, message: errorMessage)
                                }
                            })
                        })
                    } else {
                        ThreadHelper.runOnMainThread({
                            self.setLoading(false, rightBarButtonItem: self.btnRegister)
                            self.showAlert(self.txtTitleRegistrationError, message: errorMessage)
                        })
                    }
                })
                
                return
            }
        }
        
        //todo: add validation messages
        self.showAlert(NSLocalizedString("Validation failed", comment: "Alert title, Validation failed"), message: NSLocalizedString("Form validation valied", comment: "Alert message, Form validation valied"))
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
