//
//  ResetPasswordViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/22/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet weak var gradientView: GradientView!
    
    @IBOutlet weak var textFieldEmailAddress: UITextField!
    @IBOutlet var btnResetPassword: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        leftPaddingToTextField([textFieldEmailAddress])
        
        //Set gradient color
        self.gradientView.setGradientBlueColor()
        self.textFieldEmailAddress.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textFieldEmailAddress.becomeFirstResponder()
    }
    

    // TODO: - duplication code
    func leftPaddingToTextField(array: [UITextField]) {
        for textField in array {
            let paddingView = UIView(frame: CGRectMake(0, 0, 15, textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.Always
        }
        
    }
    
    func enableFields(enable: Bool){
        self.textFieldEmailAddress.enabled = enable
        self.btnResetPassword.enabled = enable
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.resetPassword(textField)
        textField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let oldText: NSString = textField.text!
        let newText: NSString = oldText.stringByReplacingCharactersInRange(range, withString: string)
        
        btnResetPassword.enabled = (newText.length > 0)
        
        return true
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
    
    // MARK: - Action
    @IBAction func resetPassword(sender: AnyObject) {
        AppAnalytics.logEvent(.ResetPasswordScreen_BtnResetPassword_Click)
        if !self.isNetworkReachable(){
            return
        }
        if let email = self.textFieldEmailAddress.text where email != "" && email.isValidEmail() {
            self.setLoading(true)
            self.enableFields(false)
            self.doResetPassword()
        } else {
            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("Email address is not valid", comment: "Alert message, email address cannot be empty"))
            self.textFieldEmailAddress.becomeFirstResponder()
        }
    }
    
    func doResetPassword(){
        if ConnectionHandler.Instance.status == .Connected {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            ConnectionHandler.Instance.users.resetPassword(self.textFieldEmailAddress.text!, callback: { (success, errorId, errorMessage, result) in
                ThreadHelper.runOnMainThread({ 
                    self.enableFields(true)
                    self.setLoading(false)
                    
                    if success {
                        self.showAlert(NSLocalizedString("Password reset", comment: "Alert title, password reset"), message: "If you entered correct email address that exists in our system, you should receive an email with password reset instructions within few minutes.")
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: errorMessage)
                    }
                })
            })
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(doResetPassword), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        }
    }
}
