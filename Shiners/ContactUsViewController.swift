//
//  ContactUsViewController.swift
//  Shiners
//
//  Created by Вячеслав on 02/11/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class ContactUsViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {

    var currentUser: User!
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtSubject: UITextField!
    @IBOutlet weak var txtMessage: UITextView!
    
    @IBOutlet var btn_Send: UIBarButtonItem!

    @IBOutlet weak var btn_Cancel: UIBarButtonItem!
    @IBAction func btnCancel_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.ContactUsScreen_BtnCancel_Click)
        self.view.endEditing(true)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSend_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.ContactUsScreen_BtnSend_Click)
        if let email = txtEmail.text, let subject = txtSubject.text, let message = txtMessage.text, email != "" && subject != "" && message != "" {
            self.setFieldsEnabled(false)
            ConnectionHandler.Instance.users.contactUs(email, subject: subject, message: message, callback: { (success, errorId, errorMessage, result) in
                ThreadHelper.runOnMainThread({
                    self.setFieldsEnabled(true)
                    if success {
                        self.view.endEditing(true)
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Title error"), message: NSLocalizedString("Internal error occurred", comment: "Internal error occurred"))
                    }
                })
            })
        } else {
            self.showAlert(NSLocalizedString("Error", comment: "Title error"), message: NSLocalizedString("Please fill in all the fields", comment: "Please fill in all the fields"))
        }
    }
    
    func setFieldsEnabled(_ enabled: Bool){
        self.btn_Cancel.isEnabled = enabled
        self.txtEmail.isEnabled = enabled
        self.txtSubject.isEnabled = enabled
        self.txtMessage.isEditable = enabled
        
        if enabled{
            self.setLoading(false, rightBarButtonItem: self.btn_Send)
        } else {
            self.view.endEditing(true)
            self.setLoading(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("Contact us", comment: "Title contact us")
        
        textFieldConfigure([self.txtEmail, self.txtSubject])
        leftPaddingToTextField([self.txtEmail, self.txtSubject])
        self.txtMessage.layer.cornerRadius = 4.0
        
        fillUserData()
        AppAnalytics.logEvent(.SettingsLoggedInScreen_ContactUs)
    }
    
    func fillUserData() {
        self.currentUser = AccountHandler.Instance.currentUser ?? CachingHandler.Instance.currentUser
        
        if self.currentUser != nil {
            if let email = self.currentUser.email {
                self.txtEmail.text = email
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let email = self.txtEmail.text, email != "" {
            self.txtSubject.becomeFirstResponder()
        } else {
            self.txtEmail.becomeFirstResponder()
        }
    }
    
    func textFieldConfigure(_ textField: [UITextField]) {
        for item in textField {
            item.layer.cornerRadius = 4.0
        }
    }
    
    // TODO: - duplication code
    func leftPaddingToTextField(_ array: [UITextField]) {
        for textField in array {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.always
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //TODO: Make check textField isEmpty
        if (textField === self.txtEmail){
            self.txtSubject.becomeFirstResponder()
        } else if textField === self.txtSubject {
            self.txtMessage.becomeFirstResponder()
        }
        
        return false
    }
}
