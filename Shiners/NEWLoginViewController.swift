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
    
    @IBOutlet var loginBtn: UIBarButtonItem!
    @IBOutlet weak var loginBtnCenter: UIButton!
    
    @IBOutlet weak var btnForgotPassword: UIButton!
    //Team color
    let blueColorCustom = UIColor(netHex: 0x2E9AE2)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setLoading(false, rightBarButtonItem: self.loginBtn);
        leftPaddingToTextField([textFieldUsername, textFieldPassword])
    
        self.navigationController?.navigationBar.setGradientTeamColor()
        self.loginBtnCenter.tintColor = UIColor.whiteColor()
        self.loginBtnCenter.backgroundColor = blueColorCustom
        self.loginBtnCenter.layer.cornerRadius = 4.0
        self.loginBtnCenter.setTitle(NSLocalizedString("Log in", comment: "Log in"), forState: .Normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.textFieldUsername.becomeFirstResponder();
    }
    
    
    // TODO: - duplication code
    func leftPaddingToTextField(array: [UITextField]) {
        
        for textField in array {
            let paddingView = UIView(frame: CGRectMake(0, 0, 15, textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.Always
        }
    
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "login_ResetPassword" {
            AppAnalytics.logEvent(.LoginScreen_BtnResetPassword_Click)
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textFieldAnimationBackgroundShow(textField, alpha: 1)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        textFieldAnimationBackgroundShow(textField, alpha: 0.5)
    }
    
    func textFieldAnimationBackgroundShow(textField: UITextField, alpha: CGFloat) {
        UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
            textField.backgroundColor = UIColor(white: 1, alpha: alpha)
        }, completion: nil)
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
    
    func enableFields(enable: Bool){
        self.textFieldUsername.enabled = enable
        self.textFieldPassword.enabled = enable
        self.loginBtn.enabled = enable
        self.loginBtnCenter.enabled = enable
        self.btnForgotPassword.enabled = enable
    }
    
    func login(){
        if !self.isNetworkReachable(){
            return
        }
        if let userName = textFieldUsername.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) where userName != "",
           let password = textFieldPassword.text where password != "" {
            ThreadHelper.runOnMainThread({ 
                self.setLoading(true)
                self.enableFields(false)
            })
            if ConnectionHandler.Instance.status == .Connected {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.processLogin), name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
                AccountHandler.Instance.login(userName, password: password, callback: { (success, errorId, errorMessage, result) in
                    if !success {
                        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
                        ThreadHelper.runOnMainThread({
                            self.enableFields(true)
                            self.setLoading(false, rightBarButtonItem: self.loginBtn)
                            self.showAlert(self.txtTitleLogInFaild, message: errorMessage)
                        })
                    }
                })
            } else {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.login), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            }
        } else {
            ThreadHelper.runOnMainThread({ 
                self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("Please fill in both, username and password", comment: "Alert message, please fill in both, username and password"))
            })
        }
    }
    
    func processLogin(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.AccountLoaded.rawValue, object: nil)
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
    
    
    @IBAction func LogInCenter_Done(sender: UIButton) {
        AppAnalytics.logEvent(.LoginScreen_BtnLogin_Click)
        self.login()
    }
    
    @IBAction func LogIn_Done(sender: AnyObject) {
        AppAnalytics.logEvent(.LoginScreen_BtnLogin_Click)
        self.login();
    }
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        AppAnalytics.logEvent(.LoginScreen_BtnCancel_Click)
        self.dismissSelf();
    }
    
    @IBAction func Register_Click(sender: UIButton) {
        //self.presentingViewController
        
        let storyboardMain = UIStoryboard(name: "Main", bundle: nil)
        let nc = storyboardMain.instantiateViewControllerWithIdentifier("SignUpNavigationController") as! UINavigationController
        self.presentViewController(nc, animated: true, completion: nil)
    }
    
    private func dismissSelf(){
       self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
}

extension UINavigationBar {
    func setGradientTeamColor() {
        barTintColor = UIColor(netHex: 0x2E9AE2)
        tintColor = UIColor.whiteColor()
        titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
    }
}

class LeftPaddedTextField: UITextField {
   
    func textRectForBounds(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + 15, y: bounds.origin.y, width: bounds.width + 15, height: bounds.height)
    }
    
    func editingRectForBounds(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + 15, y: bounds.origin.y, width: bounds.width + 15, height: bounds.height)
    }
    
}

