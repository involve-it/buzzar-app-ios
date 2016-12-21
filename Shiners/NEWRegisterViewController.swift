//
//  NEWRegisterViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import Foundation

open class NEWRegisterViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldEmailAddress: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var textFieldConfirmPassword: UITextField!
    
    let txtTitleRegistrationError = NSLocalizedString("Registration error", comment: "Alert title, registration error")
    
    
    
    @IBOutlet var btnRegister: UIBarButtonItem!

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLoading(false, rightBarButtonItem: self.btnRegister)
        
        self.tableView.separatorColor = UIColor.clear
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
    
    func textFieldConfigure(_ textField: [UITextField]) {
        for item in textField {
            item.layer.cornerRadius = 4.0
        }
    }
    
    open func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldAnimationBackgroundShow(textField, alpha: 1)
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldAnimationBackgroundShow(textField, alpha: 0.5)
    }
    
    func textFieldAnimationBackgroundShow(_ textField: UITextField, alpha: CGFloat) {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            textField.backgroundColor = UIColor(white: 1, alpha: alpha)
            }, completion: nil)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textFieldUsername.becomeFirstResponder();
    }
    
    @objc fileprivate func processLogin(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.AccountLoaded.rawValue), object: nil)
        ThreadHelper.runOnMainThread({
            if AccountHandler.Instance.currentUser == nil {
                self.setLoading(false, rightBarButtonItem: self.btnRegister)
                self.showAlert(self.txtTitleRegistrationError, message: ResponseHelper.getDefaultErrorMessage())
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    fileprivate func isFormValid() -> Bool {
        var message: String?
        var valid = true
        if self.textFieldUsername.text == nil || self.textFieldUsername.text == "" {
            valid = false
            message = NSLocalizedString("Username cannot be empty", comment: "Alert message, username cannot be empty")
            self.textFieldUsername.becomeFirstResponder()
        } else if self.textFieldEmailAddress.text == nil || self.textFieldEmailAddress.text == "" || !self.textFieldEmailAddress.text!.isValidEmail() {
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
    
    func enableFields(_ enable: Bool){
        self.textFieldUsername.isEnabled = enable
        self.textFieldPassword.isEnabled = enable
        self.textFieldEmailAddress.isEnabled = enable
        self.textFieldConfirmPassword.isEnabled = enable
        self.btnRegister.isEnabled = enable
    }
    
    @objc fileprivate func register() {
        if !self.isNetworkReachable(){
            return
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        if self.isFormValid() {
            //username
            let username = self.textFieldUsername.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            //password
            let password = self.textFieldPassword.text
            //email and check
            let email = self.textFieldEmailAddress.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            let user = RegisterUser(username: username, email: email, password: password);
        
            ThreadHelper.runOnMainThread({ 
                self.setLoading(true)
                self.enableFields(false)
            })
            
            if ConnectionHandler.Instance.isNetworkConnected() {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
                self.registerUser(user)
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(register), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            }
        }
    }
    
    fileprivate func registerUser(_ user: RegisterUser){
        AccountHandler.Instance.register(user, callback: { (success, errorId, errorMessage, result) in
            if (success){
                NotificationCenter.default.addObserver(self, selector: #selector(self.processLogin), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountLoaded.rawValue), object: nil)
                AccountHandler.Instance.login(user.username!, password: user.password!, callback: { (success, errorId, errorMessage, result) in
                    ThreadHelper.runOnMainThread({
                        if !success {
                            self.enableFields(true)
                            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.AccountLoaded.rawValue), object: nil)
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

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.Register)
    }
    
    // TODO: - duplication code
    open func leftPaddingToTextField(_ array: [UITextField]) {
        
        for textField in array {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.always
        }
        
    }
    
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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

    
    @IBAction func btnRegister_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.RegisterScreen_BtnRegister_Click)
        self.register()
    }
    
    @IBAction func btn_Cancel(_ sender: UIBarButtonItem) {
        AppAnalytics.logEvent(.RegisterScreen_BtnCancel_Click)
        //self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btn_LogIn(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "NEWloginNavigationController")
        self.present(vc!, animated: true, completion: nil)
    }

}


