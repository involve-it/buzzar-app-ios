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
    
    @IBOutlet weak var btn_Send: UIBarButtonItem!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Contact us"
        
        textFieldConfigure([self.txtEmail, self.txtSubject])
        leftPaddingToTextField([self.txtEmail, self.txtSubject])
        self.txtMessage.layer.cornerRadius = 4.0
        
        fillUserData()
        
    }
    
    func fillUserData() {
        self.currentUser = AccountHandler.Instance.currentUser ?? CachingHandler.Instance.currentUser
        
        if self.currentUser != nil {
            if let email = self.currentUser.email {
                self.txtEmail.text = email
            }
        }
    }
    
    func textFieldConfigure(textField: [UITextField]) {
        for item in textField {
            item.layer.cornerRadius = 4.0
        }
    }
    
    // TODO: - duplication code
    func leftPaddingToTextField(array: [UITextField]) {
        for textField in array {
            let paddingView = UIView(frame: CGRectMake(0, 0, 15, textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.Always
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //TODO: Make check textField isEmpty
        if (textField === self.txtEmail){
            self.txtSubject.becomeFirstResponder()
        } else if textField === self.txtSubject {
            self.txtMessage.becomeFirstResponder()
        }
        
        return false
    }
    
    
}
