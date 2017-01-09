//
//  KeyboardManager.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class KeyboardManager: NSObject {
    
    /**
     The parent view that the toolbar should be added to.
     Should normally be the top-level view of a UIViewController
     */
    weak var view: UIView?
    
    /**
     The toolbar that will be shown and hidden.
     */
    var toolbar: UIToolbar
    
    init(view: UIView, toolbar: UIToolbar) {
        self.view = view
        self.toolbar = toolbar
    }
    
    /**
     Starts monitoring for keyboard notifications in order to show/hide the toolbar
     */
    func beginMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardManager.keyboardWillShowOrHide(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardManager.keyboardWillShowOrHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /**
     Stops monitoring for keyboard notifications
     */
    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /**
     Called when a keyboard notification is recieved. Takes are of handling the showing or hiding of the toolbar
     */
    func keyboardWillShowOrHide(_ notification: Notification) {
        
        let info = notification.userInfo ?? [:]
        let duration = TimeInterval((info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.floatValue ?? 0.25)
        let curve = UInt((info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0)
        let options = UIViewAnimationOptions(rawValue: curve)
        let keyboardRect = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        
        
        if notification.name == NSNotification.Name.UIKeyboardWillShow {
            self.view?.addSubview(self.toolbar)
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                if let view = self.view {
                    self.toolbar.frame.origin.y = view.frame.height - (keyboardRect.height + self.toolbar.frame.height)
                }
                }, completion: nil)
            
            
        } else if notification.name == NSNotification.Name.UIKeyboardWillHide {
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                if let view = self.view {
                    self.toolbar.frame.origin.y = view.frame.height
                }
                }, completion: nil)
        }
    }
}
