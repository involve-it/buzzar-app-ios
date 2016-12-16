//
//  CreatePostTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 09/10/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

//Устанавливаем лимит символов для текстового поля
var titleAllowCount:String = "50"
//Устанавливаем лимит символов для поля с описанием
var descriptionAllowCount:String = "1000"

let descriptionPlaceholderText = NSLocalizedString("Optional: Provide more details", comment: "Placeholder, Description (optional)")
let descriptionPlaceholderColor = UIColor.lightGrayColor()

class CreatePostTableViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate, LocationHandlerDelegate, SelectCategoryViewControllerDelegate, UIWebViewDelegate {

    //Title
    @IBOutlet weak var titleTextCount: UILabel!
    @IBOutlet var btn_next: UIBarButtonItem!
    @IBOutlet weak var titleNewPost: UITextField!
    
    private var currentLocationInfo: GeocoderInfo?
    private let locationHandler = LocationHandler()
    
    var post = Post()
    
    @IBOutlet weak var cellDescription: UITableViewCell!
    
    @IBOutlet weak var cellCategory: UITableViewCell!
    
    //Description
    @IBOutlet weak var titleCountOfDescription: UILabel!
    @IBOutlet weak var fieldDescriptionOfPost: UITextView!
    
    var webview: UIWebView!
    var webviewLoaded = false
    
    @IBAction func segmentedControl_Changed(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.setLoading(false, rightBarButtonItem: self.btn_next)
            UIView.animateWithDuration(0.2, animations: { 
                self.webview.alpha = 0
                }, completion: { (finished) in
                    self.webview.removeFromSuperview()
            })
        } else {
            
            self.webview.alpha = 0
            if !self.webviewLoaded {
                self.setLoading(true)
                self.webview.loadRequest(NSURLRequest(URL: NSURL(string: "https://shiners.mobi/request-location")!))
            }
            
            self.view.addSubview(self.webview)
            self.view.bringSubviewToFront(self.webview)
            UIView.animateWithDuration(0.2, animations: { 
                self.webview.alpha = 1
            })
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.setLoading(false, rightBarButtonItem: self.btn_next)
        self.webviewLoaded = true
    }
    
    @IBAction func titleFieldChanged(sender: UITextField) {
        let currentCountTitleTextField:Int = (titleNewPost.text?.characters.count)!
        titleTextCount.text = String( Int(titleAllowCount)! - currentCountTitleTextField )
        
        if let title = sender.text where title != "" {
            btn_next.enabled = true
        } else {
            btn_next.enabled = false
        }
    }
    
    @IBAction func closeCreatePostForm(sender: UIBarButtonItem) {
        AppAnalytics.logEvent(.NewPostWizard_TitleStep_BtnCancel_Click)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func textViewDidChange(textView: UITextView) {
        
        //Изменение titleCountOfDescription в зависимости от лимита
        let currentCountFieldDescriptionOfPost: Int = fieldDescriptionOfPost.text.characters.count
        titleCountOfDescription.text =  String(Int(descriptionAllowCount)! - currentCountFieldDescriptionOfPost)
        
        /*if currentCountFieldDescriptionOfPost > 0 {
            self.btn_next.enabled = true
        } else {
            self.btn_next.enabled = false
        }*/
    }
    
    
    
    func locationReported(geocoderInfo: GeocoderInfo) {
        self.currentLocationInfo = geocoderInfo
        //print("New post location reported")
        NotificationManager.sendNotification(NotificationManager.Name.NewPostLocationReported, object: self.currentLocationInfo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webview = UIWebView(frame: self.tableView.frame)
        self.webview.delegate = self
        
        /*NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)*/

        self.locationHandler.delegate = self
        if !self.locationHandler.getLocationOnce(true){
            self.currentLocationInfo = GeocoderInfo()
            self.currentLocationInfo!.denied = true
        } else if let location = LocationHandler.lastLocation {
            self.currentLocationInfo = GeocoderInfo()
            self.currentLocationInfo!.coordinate = location.coordinate
        }
        
        //Заполняем начальное значение при инициализации контроллера
        titleTextCount.text = String(titleAllowCount)
        // Устанавливаем начальное значение в метку счетчика разрешенного кол-во символов
        titleCountOfDescription.text = String(descriptionAllowCount)
        
        //Placeholder
        fieldDescriptionOfPost.text = descriptionPlaceholderText
        fieldDescriptionOfPost.textColor = descriptionPlaceholderColor
        
        txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
        
        //cellDescription.contentView.frame.height
        
        
        
    }

    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //Set focus to textfield
        titleNewPost.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
    
    
    /*
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            //self.view.frame.origin.y -= keyboardSize.height
            
            //print("keyboard size \(keyboardSize.height)")
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            //self.view.frame.origin.y += keyboardSize.height
            //print("keyboard hide \(keyboardSize.height)")
        }
        
    }*/
    
    
    //Textfield limit characters
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if range.length + range.location > titleNewPost.text!.characters.count {
            return false
        } else {
            let newlength = titleNewPost.text!.characters.count + string.characters.count - range.length
            return newlength <= Int(titleAllowCount)
        }
        
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        let currentText: NSString = fieldDescriptionOfPost.text
        let updateText = currentText.stringByReplacingCharactersInRange(range, withString: text)
        
        if updateText.isEmpty || range.length + range.location > fieldDescriptionOfPost.text.characters.count{
            fieldDescriptionOfPost.text = descriptionPlaceholderText
            fieldDescriptionOfPost.textColor = descriptionPlaceholderColor
            
            txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
            return false
            
        } else if (fieldDescriptionOfPost.textColor == descriptionPlaceholderColor && !text.isEmpty)  {
            fieldDescriptionOfPost.text = nil
            fieldDescriptionOfPost.textColor = UIColor.blackColor()
        } else {
            let newlength = fieldDescriptionOfPost.text.characters.count + text.characters.count - range.length
            return newlength <= Int(descriptionAllowCount)
        }

        return true
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        if self.view.window != nil {
            if fieldDescriptionOfPost.textColor == descriptionPlaceholderColor {
                txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
            }
        }
    }
    
    func txtPlaceholderSelectedTextRange(placeholder: UITextView) -> () {
        placeholder.selectedTextRange = placeholder.textRangeFromPosition(placeholder.beginningOfDocument, toPosition: placeholder.beginningOfDocument)
    }


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "chooseLocation" {
            AppAnalytics.logEvent(.NewPostWizard_BtnNext_Click)
            if let destination = segue.destinationViewController as? WhereViewController{
                //В свойство объекта title помещаем строку из titleNewPost
                post.title = titleNewPost.text
                
                //В свойство объекта desc помещаем строку из fieldDescriptionOfPost
                if let description = fieldDescriptionOfPost.text where description != descriptionPlaceholderText {
                    post.descr = description
                }
                
                //Передаем объект post следующему контроллеру
                destination.post = post

                destination.currentLocationInfo = self.currentLocationInfo
            }
        } else if segue.identifier == "selectCategory"{
            let navController = segue.destinationViewController as! UINavigationController
            let selectCategoryViewController = navController.viewControllers[0] as! SelectCategoryTableViewController
            selectCategoryViewController.currentCategory = post.type?.rawValue
            selectCategoryViewController.selectCategoryDelegate = self
        }
    }
    
    func categorySelected(category: String?, value: String) {
        if let cat = category {
            self.post.type = Post.AdType(rawValue: cat)
        } else {
            self.post.type = nil
        }
        self.cellCategory.detailTextLabel!.text = value
    }
}
