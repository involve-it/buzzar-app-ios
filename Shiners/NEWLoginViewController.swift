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
        self.loginBtnCenter.tintColor = UIColor.white
        self.loginBtnCenter.backgroundColor = blueColorCustom
        self.loginBtnCenter.layer.cornerRadius = 4.0
        self.loginBtnCenter.setTitle(NSLocalizedString("Log in", comment: "Log in"), for: UIControlState())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textFieldUsername.becomeFirstResponder();
    }
    
    
    // TODO: - duplication code
    func leftPaddingToTextField(_ array: [UITextField]) {
        
        for textField in array {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.always
        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "login_ResetPassword" {
            AppAnalytics.logEvent(.LoginScreen_BtnResetPassword_Click)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldAnimationBackgroundShow(textField, alpha: 1)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldAnimationBackgroundShow(textField, alpha: 0.5)
    }
    
    func textFieldAnimationBackgroundShow(_ textField: UITextField, alpha: CGFloat) {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            textField.backgroundColor = UIColor(white: 1, alpha: alpha)
        }, completion: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag: NSInteger = textField.tag + 1;
        if let nextResponder: UIResponder? = textField.superview!.viewWithTag(nextTag){
            nextResponder?.becomeFirstResponder()
        } else {
            let text: NSString = textField.text! as NSString
            if text.length == 0 {
                textFieldUsername.becomeFirstResponder()
            } else {
                self.login();
                textField.resignFirstResponder()
            }
        }
        
        return false
    }
    
    func enableFields(_ enable: Bool){
        self.textFieldUsername.isEnabled = enable
        self.textFieldPassword.isEnabled = enable
        self.loginBtn.isEnabled = enable
        self.loginBtnCenter.isEnabled = enable
        self.btnForgotPassword.isEnabled = enable
    }
    
    func login(){
        if !self.isNetworkReachable(){
            return
        }
        if let userName = textFieldUsername.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), userName != "",
           let password = textFieldPassword.text, password != "" {
            ThreadHelper.runOnMainThread({ 
                self.setLoading(true)
                self.enableFields(false)
            })
            if ConnectionHandler.Instance.isNetworkConnected() {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(self.processLogin), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountLoaded.rawValue), object: nil)
                AccountHandler.Instance.login(userName, password: password, callback: { (success, errorId, errorMessage, result) in
                    if !success {
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.AccountLoaded.rawValue), object: nil)
                        ThreadHelper.runOnMainThread({
                            self.enableFields(true)
                            self.setLoading(false, rightBarButtonItem: self.loginBtn)
                            self.showAlert(self.txtTitleLogInFaild, message: errorMessage)
                        })
                    }
                })
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(self.login), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            }
        } else {
            ThreadHelper.runOnMainThread({ 
                self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("Please fill in both, username and password", comment: "Alert message, please fill in both, username and password"))
            })
        }
    }
    
    func processLogin(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.AccountLoaded.rawValue), object: nil)
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
    
    
    @IBAction func LogInCenter_Done(_ sender: UIButton) {
        AppAnalytics.logEvent(.LoginScreen_BtnLogin_Click)
        self.login()
    }
    
    @IBAction func LogIn_Done(_ sender: AnyObject) {
        AppAnalytics.logEvent(.LoginScreen_BtnLogin_Click)
        self.login();
    }
    
    @IBAction func btnCancel_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.LoginScreen_BtnCancel_Click)
        self.dismissSelf();
    }
    
    @IBAction func Register_Click(_ sender: UIButton) {
        //self.presentingViewController
        
        let storyboardMain = UIStoryboard(name: "Main", bundle: nil)
        let nc = storyboardMain.instantiateViewController(withIdentifier: "SignUpNavigationController") as! UINavigationController
        self.present(nc, animated: true, completion: nil)
    }
    
    fileprivate func dismissSelf(){
       self.navigationController?.dismiss(animated: true, completion: nil)
        
    }
    
}

extension UINavigationBar {
    func setGradientTeamColor() {
        barTintColor = UIColor(netHex: 0x2E9AE2)
        tintColor = UIColor.white
        titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
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

