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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textFieldEmailAddress.becomeFirstResponder()
    }
    

    // TODO: - duplication code
    func leftPaddingToTextField(_ array: [UITextField]) {
        for textField in array {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.always
        }
        
    }
    
    func enableFields(_ enable: Bool){
        self.textFieldEmailAddress.isEnabled = enable
        self.btnResetPassword.isEnabled = enable
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.resetPassword(textField)
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let oldText: NSString = textField.text! as NSString
        let newText: NSString = oldText.replacingCharacters(in: range, with: string) as NSString
        
        btnResetPassword.isEnabled = (newText.length > 0)
        
        return true
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
    
    // MARK: - Action
    @IBAction func resetPassword(_ sender: AnyObject) {
        AppAnalytics.logEvent(.ResetPasswordScreen_ResetPassword)
        if !self.isNetworkReachable(){
            return
        }
        if let email = self.textFieldEmailAddress.text, email != "" && email.isValidEmail() {
            self.setLoading(true)
            self.enableFields(false)
            self.doResetPassword()
        } else {
            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("Email address is not valid", comment: "Alert message, email address cannot be empty"))
            self.textFieldEmailAddress.becomeFirstResponder()
        }
    }
    
    func doResetPassword(){
        if ConnectionHandler.Instance.isNetworkConnected() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
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
            NotificationCenter.default.addObserver(self, selector: #selector(doResetPassword), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }
}
