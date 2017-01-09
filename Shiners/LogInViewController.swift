//
//  LogInViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class LogInViewController: UITableViewController, UITextFieldDelegate{
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    fileprivate let registerButton = UIBarButtonItem(title: NSLocalizedString("Register", comment: "Button title, Register"), style: .plain, target: nil, action: #selector(btnRegister_Click));
    
    let txtTitleLogInFaild = NSLocalizedString("Log in failed", comment: "Alert title, Log in failed")
    
    @IBAction func btnRegister_Click(_ sender: AnyObject) {
        let presentingViewController = self.presentingViewController;
        self.navigationController?.dismiss(animated: true, completion: { 
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "registerNavigationController")
            presentingViewController!.present(vc, animated: true, completion: nil)
        })
    }
    @IBAction func btnCancel_Click(_ sender: AnyObject) {
        self.dismissSelf();
    }
    
    fileprivate func dismissSelf(){
        self.navigationController?.dismiss(animated: true, completion: nil);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.LoginScreen)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.txtUsername.becomeFirstResponder();
        NotificationCenter.default.addObserver(self, selector: #selector(self.processLogin), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
    }
    
    override func viewDidLoad() {
        //register button
        self.setLoading(false, rightBarButtonItem: self.registerButton);
        self.txtPassword.delegate = self;
        self.txtUsername.delegate = self;
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 2 && indexPath.row == 0{
            return indexPath;
        } else {
            return nil;
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0{
            tableView.deselectRow(at: indexPath, animated: false)
            
            self.login();
        } 
    }
    
    func processLogin(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
        DispatchQueue.main.async(execute: {
            self.setLoading(false, rightBarButtonItem: self.registerButton)
            if AccountHandler.Instance.currentUser != nil {
                //AccountHandler.Instance.requestPushNotifications()
                self.dismissSelf();
            } else {
                self.showAlert(self.txtTitleLogInFaild, message: ResponseHelper.getDefaultErrorMessage())
            }
        })
    }
    
    func login(){
        if let userName = txtUsername.text, userName != "", let password = txtPassword.text, password != "" {
            setLoading(true, rightBarButtonItem: self.registerButton)
            
            AccountHandler.Instance.login(userName, password: password, callback: { (success, errorId, errorMessage, result) in
                if !success {
                    ThreadHelper.runOnMainThread({
                        self.showAlert(self.txtTitleLogInFaild, message: errorMessage)
                    })
                }
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField === self.txtPassword){
            self.login()
        } else if (textField === self.txtUsername){
            self.txtPassword.becomeFirstResponder()
        }
        return false;
    }
}
