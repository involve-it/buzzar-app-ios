//
//  ResetPasswordViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/22/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {

    
    
    @IBOutlet weak var textFieldEmailAddress: UITextField!
    @IBOutlet weak var btnResetPassword: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textFieldEmailAddress.becomeFirstResponder()
        leftPaddingToTextField([textFieldEmailAddress])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    
    
    // MARK: - Action
    @IBAction func resetPassword(sender: AnyObject) {}
    
}
