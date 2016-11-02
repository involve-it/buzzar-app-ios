//
//  NEWLoginViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/22/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class NEWLoginViewController: UIViewController, UITextFieldDelegate {

    let txtTitleLogInFaild = NSLocalizedString("Log in failed", comment: "Alert title, Log in failed")
    
    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet var loginBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setLoading(false, rightBarButtonItem: self.loginBtn);
        
        leftPaddingToTextField([textFieldUsername, textFieldPassword])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.textFieldUsername.becomeFirstResponder();
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.processLogin), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
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
        let nextTag: NSInteger = textField.tag + 1;
        if let nextResponder: UIResponder! = textField.superview!.viewWithTag(nextTag){
            nextResponder.becomeFirstResponder()
        } else {
            let text: NSString = textField.text!
            if text.length == 0 {
                textFieldUsername.becomeFirstResponder()
            } else {
                self.login();
                textField.resignFirstResponder()
            }
        }
        
        return false
    }
    
    func login(){
        if let userName = textFieldUsername.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) where userName != "",
           let password = textFieldPassword.text where password != "" {
            setLoading(true)
            
            AccountHandler.Instance.login(userName, password: password, callback: { (success, errorId, errorMessage, result) in
                if !success {
                    ThreadHelper.runOnMainThread({
                        self.setLoading(false, rightBarButtonItem: self.loginBtn)
                        self.showAlert(self.txtTitleLogInFaild, message: errorMessage)
                    })
                }
            })
        }
    }
    
    func processLogin(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        if AccountHandler.Instance.currentUser == nil {
            ThreadHelper.runOnMainThread({
                self.setLoading(false, rightBarButtonItem: self.loginBtn)
                self.showAlert(self.txtTitleLogInFaild, message: ResponseHelper.getDefaultErrorMessage())
            })
        } else {
            ThreadHelper.runOnMainThread({ 
                self.dismissSelf()
            })
        }
    }
    
    
    // MARK: - Action
    
    @IBAction func LogIn_Done(sender: AnyObject) {
        self.login();
    }
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.dismissSelf();
    }
    
    @IBAction func Register_Click(sender: UIButton) {
        let storyboardMain = UIStoryboard(name: "Main", bundle: nil)
        let nc = storyboardMain.instantiateViewControllerWithIdentifier("SignUpNavigationController") as! UINavigationController
        self.presentViewController(nc, animated: true, completion: nil)
    }
    
    private func dismissSelf(){
       self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
}
