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
    
    private func register(){
        if self.txtPassword.text == self.txtConfirmPassword.text {
            let user = RegisterUser(username: self.txtUsername.text, email: self.txtEmail.text, password: self.txtPassword.text);
            if (user.isValid()){
                self.setLoading(true)
                
                ConnectionHandler.Instance.users.register(user, callback: { (success, errorId, errorMessage, result) in
                    if (success){
                        ConnectionHandler.Instance.users.login(user.username!, password: user.password!, callback: { (success, errorId, errorMessage, result) in
                            if (success){
                                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                            } else {
                                //todo: add error message
                                self.showAlert("Registration error", message: errorMessage)
                            }
                        })
                    } else {
                        //todo: add error message
                        self.showAlert("Registration error", message: errorMessage)
                    }
                })
                
                return
            }
        }
        
        //todo: add validation messages
        self.showAlert("Validation failed", message: "Form validation valied")
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
