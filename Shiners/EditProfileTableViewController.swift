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

open class EditProfileTableViewController: UITableViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{

    
    @IBOutlet weak var fNameView: UIView!
    @IBOutlet weak var firstNameLabel: UITextField!
    @IBOutlet weak var lastNameLabel: UITextField!
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var txtPhoneLabel: UITextField!
    @IBOutlet weak var txtEmailLabel: UITextField!
    @IBOutlet weak var txtUsernameLabel: UILabel!
    @IBOutlet weak var txtSkypeLabel: UITextField!
    
    @IBOutlet weak var txtAddressLocationLabel: UITextField!
    
    fileprivate var imagePickerHandler: ImagePickerHandler?
    
    @IBOutlet var btnSave: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    var currentUser: User?
    
    @IBOutlet weak var txtBioPlaceholder: UITextView!
    
    let txtBioPlaceholderText = NSLocalizedString("Bio (optional)", comment: "Placeholder, Bio (optional)")
    let txtPlaceHolderColor = UIColor.lightGray
    
    var uploadDelegate: ImageCachingHandler.UploadDelegate?
    var uploadAlertController: UIAlertController?
    var aborting = false
    var tryingLowerQuality = false
    var previousImage: UIImage?
    var lastRequestId: String!
    
    override open func viewDidLoad() {
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
        AppAnalytics.logEvent(.SettingsLoggedInScreen_BtnEdit_Click)
    }
    
    @IBAction func btnSave_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.EditProfileScreen_BtnSave_Click)
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
    
    fileprivate func getUser() -> User {
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
    
    fileprivate func refreshUserData(){
        self.txtUsernameLabel.text = self.currentUser!.username
        self.firstNameLabel.text = self.currentUser?.getProfileDetailValue(.FirstName)
        self.lastNameLabel.text = self.currentUser?.getProfileDetailValue(.LastName)
        self.txtAddressLocationLabel.text = self.currentUser?.getProfileDetailValue(.City)
        self.txtPhoneLabel.text = self.currentUser?.getProfileDetailValue(.Phone)
        self.txtEmailLabel.text = self.currentUser?.email
        self.txtSkypeLabel.text = self.currentUser?.getProfileDetailValue(.Skype)
        
        if let imageUrl = self.currentUser?.imageUrl{
            ImageCachingHandler.Instance.getImageFromUrl(imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                DispatchQueue.main.async(execute: {
                    self.imgUserAvatar.image = image;
                })
            })
        } else {
            self.imgUserAvatar.image = ImageCachingHandler.defaultAccountImage
        }
    }
    
    override open func viewDidLayoutSubviews() {
        // Creates the bottom border
        //TODO: Make a function
        let borderBottom = CALayer()
        let borderWidth = CGFloat(1.0)
        let borderColor = UIColor(red: 164/255, green: 162/255, blue: 169/255, alpha: 0.3).cgColor
        
        borderBottom.borderColor = borderColor
        borderBottom.frame = CGRect(x: 0, y: fNameView.frame.height - 0.5, width: fNameView.frame.width , height: fNameView.frame.height - 0.5)
        borderBottom.borderWidth = borderWidth
        
        fNameView.layer.addSublayer(borderBottom)
        fNameView.layer.masksToBounds = true
    }
    
    @IBAction func btnChangeImage_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.EditProfileScreen_ChangePhoto_Click)
        self.imagePickerHandler?.displayImagePicker()
    }
    
    fileprivate func dismissSelf(){
        self.navigationController?.popViewController(animated: true)
    }

    // MARK: Cancel action
    @IBAction func btn_Cancel(_ sender: UIBarButtonItem) {
        /*
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("settingsUserProfile")
        self.navigationController?.pushViewController(vc, animated: true)
         */
        AppAnalytics.logEvent(.EditProfileScreen_BtnCancel_Click)
        
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
    
    func txtPlaceholderSelectedTextRange(_ placeholder: UITextView) -> () {
        placeholder.selectedTextRange = placeholder.textRange(from: placeholder.beginningOfDocument, to: placeholder.beginningOfDocument)
    }
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismiss(animated: true, completion: nil)
        
        let rotatedImage = image.correctlyOrientedImage().resizeImage()
        self.previousImage = self.imgUserAvatar.image
        self.imgUserAvatar.image = rotatedImage
        self.tryingLowerQuality = false
        self.doUpload()
        self.aborting = false
    }
    
    func doUpload(){
        self.setLoading(true)
        self.cancelButton.isEnabled = false
        
        self.lastRequestId = UUID().uuidString
        self.aborting = false
        self.uploadDelegate = ImageCachingHandler.Instance.saveImage(self.imgUserAvatar.image!, uploadId: lastRequestId) { (success, uploadId, imageUrl) in
            ThreadHelper.runOnMainThread({
                if self.lastRequestId == uploadId {
                    self.setLoading(false, rightBarButtonItem: self.btnSave)
                    self.cancelButton.isEnabled = true
                    self.uploadAlertController?.dismiss(animated: true, completion: nil)
                    if success {
                        self.currentUser?.imageUrl = imageUrl
                        self.previousImage = nil
                    } else  {
                        self.imgUserAvatar.image = self.previousImage
                        self.previousImage = nil
                        if !self.aborting{
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("Error uploading photo", comment: "Alert message, Error uploading photo"))
                        }
                    }
                }
            })
        }
        
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(displayUploadingLongTime), userInfo: nil, repeats: false)
    }
    
    func displayUploadingLongTime(_ timer: Timer){
        self.uploadAlertController = UIAlertController(title: NSLocalizedString("Uploading photo...", comment: "Alert title, Uploading photo"), message: NSLocalizedString("Looks like upload is taking longer then usual. We are still trying to upload, but if you wish, you may continue waiting, cancel, retry and attempt to upload image with lower quality.", comment: "Alert message, Looks like upload is taking longer then usual. We are still trying to upload, but if you wish, you may continue waiting, cancel, retry and attempt to upload image with lower quality."), preferredStyle: .alert)
        self.uploadAlertController?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            self.aborting = true
            self.uploadDelegate?.abort()
        }))
        self.uploadAlertController?.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action) in
            self.aborting = true
            self.uploadDelegate?.abort()
            self.doUpload()
        }))
        if !self.tryingLowerQuality {
            self.uploadAlertController?.addAction(UIAlertAction(title: "Try lower quality", style: .default, handler: { (action) in
                self.aborting = true
                self.tryingLowerQuality = true
                self.uploadDelegate?.abort()
                self.imgUserAvatar.image = self.imgUserAvatar.image?.resizeImage(320, maxHeight: 320, quality: 0.5)
                self.doUpload()
            }))
        }
        self.present(self.uploadAlertController!, animated: true, completion: nil)
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadData()
    }
    
    
    
}



