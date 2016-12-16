//
//  ChangePasswordTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

open class ChangePasswordTableViewController: UITableViewController, UITextFieldDelegate {

    
    @IBOutlet weak var textFieldCurrentPassword: UITextField!
    @IBOutlet weak var textFieldNewPassword: UITextField!
    @IBOutlet weak var textFieldConfirmNewPassword: UITextField!
    
    @IBOutlet weak var btnSave: UIBarButtonItem!
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.setLoading(false, rightBarButtonItem: self.btnSave)
        
        self.tableView.separatorColor = UIColor.clear
        textFieldConfigure([self.textFieldCurrentPassword, self.textFieldNewPassword, self.textFieldConfirmNewPassword])
        leftPaddingToTextField([self.textFieldCurrentPassword, self.textFieldNewPassword, self.textFieldConfirmNewPassword])
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    open func textFieldConfigure(_ textField: [UITextField]) {
        for item in textField {
            item.layer.cornerRadius = 4.0
        }
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
        if (textField === self.textFieldCurrentPassword){
            self.textFieldNewPassword.becomeFirstResponder()
        } else if textField === self.textFieldNewPassword {
            self.textFieldConfirmNewPassword.becomeFirstResponder()
        } else if textField === self.textFieldConfirmNewPassword {
            self.changePassword()
            textField.resignFirstResponder()
        }
        
        return false
    }

    fileprivate func changePassword() {
        
    }
    
    
    // MARK: Action
    @IBAction func btn_Save(_ sender: UIBarButtonItem) {
        self.changePassword()
    }
    
    @IBAction func btn_Cancel(_ sender: UIBarButtonItem) {
            self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btn_ForgotPassword(_ sender: UIButton) { }
    
}
