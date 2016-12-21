//
//  RegisterViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

open class RegisterViewController: UITableViewController, UITextFieldDelegate{
    
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    
    let txtTitleRegistrationError = NSLocalizedString("Registration error", comment: "Alert title, registration error")
    
    @IBAction func btnCancel_Click(_ sender: AnyObject) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    open override func viewDidLoad() {
        self.setLoading(false);
        
        self.txtUsername.delegate = self;
        self.txtEmail.delegate = self;
        self.txtPassword.delegate = self;
        self.txtConfirmPassword.delegate = self;
    }
    
    open override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if (indexPath.section == 1){
            return indexPath;
        } else {
            return nil
        }
    }
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.tableView.deselectRow(at: indexPath, animated: true);
            self.register()
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.Register)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.txtUsername.becomeFirstResponder();
        NotificationCenter.default.addObserver(self, selector: #selector(self.processLogin), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
    }
    
    @objc fileprivate func processLogin(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
        DispatchQueue.main.async(execute: {
            self.setLoading(false)
            if AccountHandler.Instance.currentUser != nil {
                self.navigationController?.dismiss(animated: true, completion: nil)
            } else {
                self.showAlert("Registration error", message: ResponseHelper.getDefaultErrorMessage())
            }
        })
    }
    
    fileprivate func register(){
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
        self.showAlert(NSLocalizedString("Validation failed", comment: "Alert title, Validation failed"), message: NSLocalizedString("Form validation failed", comment: "Alert message, Form validation failed"))
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
