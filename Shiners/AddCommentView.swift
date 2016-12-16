//
//  AddCommentView.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/4/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class AddCommentView: UIView, UITextViewDelegate {
    var parentViewHeight: CGFloat!
    var keyboardHeight: CGFloat! = 0
    
    @IBOutlet weak var lblPlaceholder: UILabel!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var txtComment: UITextView!
    var typing = false
    fileprivate var timer:Timer?
    
    var delegate: AddCommentDelegate?
    var statusBarHeight:CGFloat = 0
    
    @IBAction func btnSend_Click(_ sender: AnyObject) {
        self.delegate?.sendButtonPressed(self.txtComment.text)
    }
    
    func setSendButtonEnabled(_ enabled: Bool){
        self.btnSend.isEnabled = enabled
    }
    
    func enableControls(_ enable: Bool){
        self.btnSend.isEnabled = enable
        self.txtComment.isEditable = enable
    }
    
    func clearMessageText(){
        self.txtComment.text = ""
        self.lblPlaceholder.isHidden = false
        self.textViewDidChange(self.txtComment)
    }
    
    func statusBarHeightChanged(){
        self.statusBarHeight = UIApplication.shared.statusBarFrame.height - 20
        self.frame.origin.y = self.parentViewHeight - self.keyboardHeight - self.statusBarHeight - self.frame.height
    }
    
    func setupView(_ parentViewHeight: CGFloat, parentViewWidth: CGFloat, delegate: AddCommentDelegate? = nil){
        self.delegate = delegate
        self.parentViewHeight = parentViewHeight
        self.backgroundColor = UIColor.white
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(red:222/255.0, green:225/255.0, blue:227/255.0, alpha: 1.0).cgColor
        
        self.btnSend.setTitle(NSLocalizedString("Send", comment: "Send comment"), for: UIControlState())
        
        let borderColor = UIColor(colorLiteralRed:204.0/255.0, green:204.0/255.0, blue:204.0/255.0, alpha:1.0)
        self.txtComment.layer.borderColor = borderColor.cgColor;
        self.txtComment.layer.borderWidth = 1.0;
        self.txtComment.layer.cornerRadius = 5.0;
        self.txtComment.delegate = self
        self.txtComment.isScrollEnabled = false
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(self.keyboardNotification),
                                                         name: NSNotification.Name.UIKeyboardWillChangeFrame,
                                                         object: nil)
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(self.statusBarHeightChanged),
                                                         name: NSNotification.Name.UIApplicationDidChangeStatusBarFrame,
                                                         object: nil)
        
        //self.layoutSubviews()
        self.frame.size.height = 43
        self.frame.size.width = parentViewWidth
        self.statusBarHeightChanged()
    }
    
    func setNotTyping(){
        self.typing = false
    }
    
    func keyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as?     NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions().rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            //var originY: CGFloat!
            if endFrame?.origin.y >= UIScreen.main.bounds.size.height {
                //self.keyboardHeightLayoutConstraint?.constant = 0.0
                //originY = self.parentViewHeight - self.frame.height
                //self.frame.origin.y = 0
                self.keyboardHeight = 0
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(setNotTyping), userInfo: nil, repeats: false)
            } else {
                if let timer = self.timer {
                    timer.invalidate()
                    self.timer = nil
                }
                self.typing = true
                //originY = self.parentViewHeight - (endFrame?.size.height ?? 0) - self.frame.height
                self.keyboardHeight = endFrame?.size.height ?? 0
            }
            
            
            let originY = self.parentViewHeight - self.keyboardHeight - self.statusBarHeight - self.frame.height
            UIView.animate(withDuration: duration,
                                       delay: TimeInterval(0),
                                       options: animationCurve,
                                       animations: {
                                        self.frame.origin.y = originY
                                            //self.parentViewHeight - (endFrame?.size.height ?? 0) - self.frame.height
                                        self.delegate?.updateInsets(self.frame.height)
                },
                                       completion: nil)
            
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.lblPlaceholder.isHidden = textView.text != ""
        
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
            self.txtComment.isScrollEnabled = false
            self.delegate?.updateInsets(self.keyboardHeight + contentHeight + 10)
        } else {
            self.txtComment.isScrollEnabled = true
        }
    }
    
}

protocol AddCommentDelegate {
    func sendButtonPressed(_ comment: String)
    func updateInsets(_ height: CGFloat)
}
