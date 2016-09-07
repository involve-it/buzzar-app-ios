//
//  DescriptionViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import RichEditorView

public class DescriptionViewController: UIViewController{
    var editor: RichEditorView?
    var keyboardManager: KeyboardManager?
    var delegate: DescriptionViewControllerDelegate?
    var html: String = ""
    
    public override func viewDidLoad() {
        super.viewDidLoad();
        
        //self.view.bounds = CGRectMake(0, 10, self.view.frame.width, self.view.frame.height - 10)
        
        let toolbar = RichEditorToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44))
        toolbar.options = [RichEditorOptions.Bold, RichEditorOptions.Italic, RichEditorOptions.Underline]
        
        self.editor = RichEditorView(frame: CGRectMake(0, 0, self.view!.bounds.width, self.view!.bounds.height));
        //self.editor!.frame.origin = CGPoint(x: 0, y: 20)
        self.editor?.inputAccessoryView = toolbar
        
        //self.editor?.bounds = CGRectInset(self.editor!.frame, 10, 10)
        self.editor?.setHTML(self.html)
        
        toolbar.editor = self.editor
        
        self.view.addSubview(self.editor!)
        //self.keyboardManager = KeyboardManager(view: self.view)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    func keyboardWillShow (notification: NSNotification?){
        let keyboardInfo = (notification?.userInfo)! as NSDictionary;
        let frame = (keyboardInfo.valueForKey(UIKeyboardFrameBeginUserInfoKey) as? NSValue)?.CGRectValue();
        self.editor?.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height - frame!.height - 8)
        
    }
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if (self.html == ""){
            self.editor?.focus()
        }
    }
    
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.delegate?.htmlUpdated(self.editor?.getHTML(), text: self.editor?.getText())
    }
}

protocol DescriptionViewControllerDelegate {
    func htmlUpdated(html: String?, text: String?) -> Void
}