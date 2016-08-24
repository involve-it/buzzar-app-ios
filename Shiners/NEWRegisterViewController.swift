//
//  NEWRegisterViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class NEWRegisterViewController: UITableViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldEmailAddress: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var textFieldConfirmPassword: UITextField!
    
    @IBOutlet weak var btnDone: UIBarButtonItem!

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLoading(false, rightBarButtonItem: self.btnDone)
        
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
        dispatch_async(dispatch_get_main_queue(), {
            self.setLoading(false)
            if AccountHandler.Instance.currentUser != nil {
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            } else {
                self.showAlert("Registration error", message: ResponseHelper.getDefaultErrorMessage())
            }
        })
        
    }
    
    private func register() {
        if self.textFieldPassword.text == self.textFieldConfirmPassword.text {
            let user = RegisterUser(username: self.textFieldUsername.text, email: self.textFieldEmailAddress.text, password: self.textFieldPassword.text);
            if (user.isValid()){
                self.setLoading(true)
                
                AccountHandler.Instance.register(user, callback: { (success, errorId, errorMessage, result) in
                    if (success){
                        AccountHandler.Instance.login(user.username!, password: user.password!, callback: { (success, errorId, errorMessage, result) in
                            if !success {
                                self.showAlert("Registration error", message: errorMessage)
                            }
                        })
                    } else {
                        self.setLoading(false)
                        self.showAlert("Registration error", message: errorMessage)
                    }
                })
                
                return
            }
        }
        
        //todo: add validation messages
        self.showAlert("Validation failed", message: "Form validation valied")
    }

    
    // TODO: - duplication code
    func leftPaddingToTextField(array: [UITextField]) {
        
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

    
    
    // MARK: Action
    
    @IBAction func btn_Done(sender: UIBarButtonItem) {
        self.register()
    }
    
    @IBAction func btn_Cancel(sender: UIBarButtonItem) {
        //self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func btn_LogIn(sender: UIButton) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("NEWloginNavigationController")
        self.presentViewController(vc!, animated: true, completion: nil)
    }

}
