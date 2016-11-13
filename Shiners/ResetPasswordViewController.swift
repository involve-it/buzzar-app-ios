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
    @IBOutlet weak var btnResetPassword: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        leftPaddingToTextField([textFieldEmailAddress])
        
        //Set gradient color
        self.gradientView.setGradientBlueColor()
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
    @IBAction func resetPassword(sender: AnyObject) {}
    
}
