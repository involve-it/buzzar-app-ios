//
//  AddCommentView.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/4/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit

class AddCommentView: UIView, UITextViewDelegate {
    var parentViewHeight: CGFloat!
    var keyboardHeight: CGFloat! = 0
    
    @IBOutlet weak var lblPlaceholder: UILabel!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var txtComment: UITextView!
    
    var delegate: AddCommentDelegate?
    
    @IBAction func btnSend_Click(sender: AnyObject) {
        self.delegate?.sendButtonPressed(self.txtComment.text)
    }
    
    func setSendButtonEnabled(enabled: Bool){
        self.btnSend.enabled = enabled
    }
    
    func enableControls(enable: Bool){
        self.btnSend.enabled = enable
        self.txtComment.editable = enable
    }
    
    func clearMessageText(){
        self.txtComment.text = ""
        self.lblPlaceholder.hidden = false
        self.textViewDidChange(self.txtComment)
    }
    
    func setupView(parentViewHeight: CGFloat, delegate: AddCommentDelegate? = nil){
        self.delegate = delegate
        self.parentViewHeight = parentViewHeight
        self.backgroundColor = UIColor.whiteColor()
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(red:222/255.0, green:225/255.0, blue:227/255.0, alpha: 1.0).CGColor
        
        self.btnSend.setTitle(NSLocalizedString("Send", comment: "Send comment"), forState: .Normal)
        
        let borderColor = UIColor(colorLiteralRed:204.0/255.0, green:204.0/255.0, blue:204.0/255.0, alpha:1.0)
        self.txtComment.layer.borderColor = borderColor.CGColor;
        self.txtComment.layer.borderWidth = 1.0;
        self.txtComment.layer.cornerRadius = 5.0;
        self.txtComment.delegate = self
        self.txtComment.scrollEnabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.keyboardNotification(_:)),
                                                         name: UIKeyboardWillChangeFrameNotification,
                                                         object: nil)
        
        
        //self.layoutSubviews()
    }
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as?     NSValue)?.CGRectValue()
            let duration:NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            var originY: CGFloat!
            if endFrame?.origin.y >= UIScreen.mainScreen().bounds.size.height {
                //self.keyboardHeightLayoutConstraint?.constant = 0.0
                originY = self.parentViewHeight - self.frame.height
                //self.frame.origin.y = 0
            } else {
                originY = self.parentViewHeight - (endFrame?.size.height ?? 0) - self.frame.height
            }
            
            self.keyboardHeight = endFrame?.size.height ?? 0
            UIView.animateWithDuration(duration,
                                       delay: NSTimeInterval(0),
                                       options: animationCurve,
                                       animations: {
                                        self.frame.origin.y = originY
                                            //self.parentViewHeight - (endFrame?.size.height ?? 0) - self.frame.height
                                        self.delegate?.updateInsets(self.frame.height)
                },
                                       completion: nil)
            
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        self.lblPlaceholder.hidden = textView.text != ""
        
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: 1000))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: 1000))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        //textView.frame = newFrame;
        
        let contentHeight = newFrame.height
        if contentHeight < (self.parentViewHeight - self.keyboardHeight) / 3 {
            self.frame.size.height = contentHeight + 10
            self.frame.origin.y = self.parentViewHeight - contentHeight - 10 - self.keyboardHeight
            self.txtComment.scrollEnabled = false
            self.delegate?.updateInsets(self.keyboardHeight + contentHeight + 10)
        } else {
            self.txtComment.scrollEnabled = true
        }
    }
    
}

protocol AddCommentDelegate {
    func sendButtonPressed(comment: String)
    func updateInsets(height: CGFloat)
}
