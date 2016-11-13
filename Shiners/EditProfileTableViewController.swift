//
//  EditProfileTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/18/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import AWSS3

public class EditProfileTableViewController: UITableViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{

    
    @IBOutlet weak var fNameView: UIView!
    @IBOutlet weak var firstNameLabel: UITextField!
    @IBOutlet weak var lastNameLabel: UITextField!
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var txtPhoneLabel: UITextField!
    @IBOutlet weak var txtEmailLabel: UITextField!
    @IBOutlet weak var txtUsernameLabel: UILabel!
    @IBOutlet weak var txtSkypeLabel: UITextField!
    
    @IBOutlet weak var txtAddressLocationLabel: UITextField!
    
    private var imagePickerHandler: ImagePickerHandler?
    
    @IBOutlet var btnSave: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    var currentUser: User?
    
    @IBOutlet weak var txtBioPlaceholder: UITextView!
    
    let txtBioPlaceholderText = NSLocalizedString("Bio (optional)", comment: "Placeholder, Bio (optional)")
    let txtPlaceHolderColor = UIColor.lightGrayColor()
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        //txtBioPlaceholder.delegate = self
        
        self.imagePickerHandler = ImagePickerHandler(viewController: self, delegate: self)
        
        //Placeholder bio
        /*txtBioPlaceholder.text = txtBioPlaceholderText
        txtBioPlaceholder.textColor = txtPlaceHolderColor*/
        
        /*txtPlaceholderSelectedTextRange(txtBioPlaceholder)*/

        if self.currentUser == nil || self.currentUser! !== AccountHandler.Instance.currentUser{
            self.currentUser = AccountHandler.Instance.currentUser
            self.refreshUserData()
        }
        
    }
    
    @IBAction func btnSave_Click(sender: AnyObject) {
        if !self.isNetworkReachable(){
            return
        }
        self.setLoading(true)
        let user = self.getUser();
        AccountHandler.Instance.saveUser(user) { (success, errorMessage) in
            ThreadHelper.runOnMainThread({
                self.setLoading(false, rightBarButtonItem: self.btnSave)
                if (success){
                    self.dismissSelf()
                } else {
                    self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("An error occurred while saving.", comment: "Alert message, An error occurred while saving."))
                }
            })
        }
    }
    
    private func getUser() -> User {
        let user = AccountHandler.Instance.currentUser!;
        user.setProfileDetail(.FirstName, value: self.firstNameLabel.text)
        user.setProfileDetail(.LastName, value: self.lastNameLabel.text)
        user.setProfileDetail(.City, value: self.txtAddressLocationLabel.text)
        user.setProfileDetail(.Phone, value: self.txtPhoneLabel.text)
        self.txtUsernameLabel.text = user.username
        user.setProfileDetail(.Skype, value: self.txtSkypeLabel.text)
        user.imageUrl = self.currentUser?.imageUrl
        user.email = self.txtEmailLabel.text
        
        return user;
    }
    
    private func refreshUserData(){
        self.txtUsernameLabel.text = self.currentUser!.username
        self.firstNameLabel.text = self.currentUser?.getProfileDetailValue(.FirstName)
        self.lastNameLabel.text = self.currentUser?.getProfileDetailValue(.LastName)
        self.txtAddressLocationLabel.text = self.currentUser?.getProfileDetailValue(.City)
        self.txtPhoneLabel.text = self.currentUser?.getProfileDetailValue(.Phone)
        self.txtEmailLabel.text = self.currentUser?.email
        self.txtSkypeLabel.text = self.currentUser?.getProfileDetailValue(.Skype)
        
        if let imageUrl = self.currentUser?.imageUrl{
            ImageCachingHandler.Instance.getImageFromUrl(imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.imgUserAvatar.image = image;
                })
            })
        } else {
            self.imgUserAvatar.image = ImageCachingHandler.defaultAccountImage
        }
    }
    
    override public func viewDidLayoutSubviews() {
        // Creates the bottom border
        //TODO: Make a function
        let borderBottom = CALayer()
        let borderWidth = CGFloat(1.0)
        let borderColor = UIColor(red: 164/255, green: 162/255, blue: 169/255, alpha: 0.3).CGColor
        
        borderBottom.borderColor = borderColor
        borderBottom.frame = CGRect(x: 0, y: fNameView.frame.height - 0.5, width: fNameView.frame.width , height: fNameView.frame.height - 0.5)
        borderBottom.borderWidth = borderWidth
        
        fNameView.layer.addSublayer(borderBottom)
        fNameView.layer.masksToBounds = true
    }
    
    @IBAction func btnChangeImage_Click(sender: AnyObject) {
        self.imagePickerHandler?.displayImagePicker()
    }
    
    private func dismissSelf(){
        self.navigationController?.popViewControllerAnimated(true)
    }

    // MARK: Cancel action
    @IBAction func btn_Cancel(sender: UIBarButtonItem) {
        /*
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("settingsUserProfile")
        self.navigationController?.pushViewController(vc, animated: true)
         */
        
        self.dismissSelf()
    }
    
    /*public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let currentText: NSString = txtBioPlaceholder.text
        let updateText = currentText.stringByReplacingCharactersInRange(range, withString: text)
        
        if updateText.isEmpty {
            txtBioPlaceholder.text = txtBioPlaceholderText
            txtBioPlaceholder.textColor = txtPlaceHolderColor
            
           txtPlaceholderSelectedTextRange(txtBioPlaceholder)
            
            return false
        } else if (txtBioPlaceholder.textColor == txtPlaceHolderColor && !text.isEmpty)  {
            txtBioPlaceholder.text = nil
            txtBioPlaceholder.textColor = UIColor.blackColor()
        }
        
        
        return true
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        if self.view.window != nil {
            if txtBioPlaceholder.textColor == txtPlaceHolderColor {
                txtPlaceholderSelectedTextRange(txtBioPlaceholder)
            }
        }
    }*/
    
    func txtPlaceholderSelectedTextRange(placeholder: UITextView) -> () {
        placeholder.selectedTextRange = placeholder.textRangeFromPosition(placeholder.beginningOfDocument, toPosition: placeholder.beginningOfDocument)
    }
    
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        self.setLoading(true)
        let rotatedImage = image.correctlyOrientedImage().resizeImage()
        let currentImage = self.imgUserAvatar.image
        self.imgUserAvatar.image = rotatedImage
        self.cancelButton.enabled = false
        ImageCachingHandler.Instance.saveImage(rotatedImage) { (success, imageUrl) in
            ThreadHelper.runOnMainThread({
                self.setLoading(false, rightBarButtonItem: self.btnSave)
                self.cancelButton.enabled = true
                if success {
                    self.currentUser?.imageUrl = imageUrl
                } else {
                    self.imgUserAvatar.image = currentImage
                    self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("Error uploading photo", comment: "Alert message, Error uploading photo"))
                }
            })
        }
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.reloadData()
    }
    
    
    
}



