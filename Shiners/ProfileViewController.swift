//
//  ProfileViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/28/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import AWSS3

open class ProfileViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{
    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var txtLocation: UITextField!
    @IBOutlet weak var txtPhoneNumber: UITextField!
    @IBOutlet weak var txtSkype: UITextField!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var cellFacebook: UITableViewCell!
    
    fileprivate var imagePickerHandler: ImagePickerHandler?
    
    let txtTitleLogOut = NSLocalizedString("Log out", comment: "Alert title, Log out")
    
    var currentUser: User?;
    
    @IBOutlet weak var btnSave: UIBarButtonItem!
    fileprivate var cancelButton: UIBarButtonItem?
    
    @IBAction func btnCancel_Click(_ sender: AnyObject) {
        self.dismissSelf();
    }
    
    //refreshing profile image
    @objc open override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }
    
    @objc open override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }
    
    fileprivate func dismissSelf(){
        self.navigationController?.popViewController(animated: true)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.Profile)
    }
    
    @IBAction func btnSave_Click(_ sender: AnyObject) {
        self.setLoading(true)
        let user = self.getUser();
        AccountHandler.Instance.saveUser(user) { (success, errorMessage) in
            ThreadHelper.runOnMainThread({ 
                self.setLoading(false, rightBarButtonItem: self.cancelButton)
                if (success){
                    self.dismissSelf()
                } else {
                    self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("An error occurred while saving.", comment: "Alert message, An error occurred while saving."))
                }
            })
        }
    }
    
    fileprivate func getUser() -> User{
        let user = AccountHandler.Instance.currentUser!;
        user.setProfileDetail(.FirstName, value: self.txtFirstName.text)
        user.setProfileDetail(.LastName, value: self.txtLastName.text)
        user.setProfileDetail(.City, value: self.txtLocation.text)
        user.setProfileDetail(.Phone, value: self.txtPhoneNumber.text)
        user.setProfileDetail(.Skype, value: self.txtSkype.text)
        
        user.imageUrl = self.currentUser?.imageUrl
        return user;
    }
    
    @IBAction func btnChangeImage_Click(_ sender: AnyObject) {
        self.imagePickerHandler?.displayImagePicker()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.cancelButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "Alert title, Cancel"), style: .plain, target: self, action: #selector(btnCancel_Click));
        
        self.setLoading(false, rightBarButtonItem: self.cancelButton)
        
        //self.navigationItem.backBarButtonItem?.title = "Save"
        self.imagePickerHandler = ImagePickerHandler(viewController: self, delegate: self)
        self.txtFirstName.delegate = self;
        self.txtLastName.delegate = self;
        self.txtLocation.delegate = self;
        self.txtPhoneNumber.delegate = self;
        self.txtSkype.delegate = self;
        if self.currentUser == nil || self.currentUser! !== AccountHandler.Instance.currentUser{
            self.currentUser = AccountHandler.Instance.currentUser
            self.refreshUserData()
        }
        
        self.refreshSocialState()
    }
    
    fileprivate func refreshSocialState(){
        if let _ = FBSDKAccessToken.current() {
            cellFacebook.accessoryType = UITableViewCellAccessoryType.none
            cellFacebook.detailTextLabel?.text = NSLocalizedString("Connected", comment: "Label text, Connected")
        } else {
            cellFacebook.detailTextLabel?.text = ""
        }
    }
    
    fileprivate func refreshUserData(){
        self.txtFirstName.text = self.currentUser?.getProfileDetailValue(.FirstName)
        self.txtLastName.text = self.currentUser?.getProfileDetailValue(.LastName)
        self.txtLocation.text = self.currentUser?.getProfileDetailValue(.City)
        self.txtPhoneNumber.text = self.currentUser?.getProfileDetailValue(.Phone)
        self.txtSkype.text = self.currentUser?.getProfileDetailValue(.Skype)
        if let imageUrl = self.currentUser?.imageUrl{
            ImageCachingHandler.Instance.getImageFromUrl(imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                DispatchQueue.main.async(execute: {
                    self.imgPhoto.image = image;
                })
            })
        } else {
            self.imgPhoto.image = ImageCachingHandler.defaultAccountImage
        }
    }
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var animated = false
        
        if indexPath.section == 2{
            //facebook
            if indexPath.row == 0 {
                self.loginFacebook()
            }
            animated = true
        }
        self.tableView.deselectRow(at: indexPath, animated: animated)
        
        self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }
    
    fileprivate func loginFacebook(){
        if let _ = FBSDKAccessToken.current() {
            let alertController = UIAlertController(title: NSLocalizedString("Facebook", comment: "Facebook"), message: NSLocalizedString("Do you wish to log out?", comment: "Alert message, Do you wish to log out?"), preferredStyle: .alert);
            alertController.addAction(UIAlertAction(title: self.txtTitleLogOut, style: .destructive, handler: { (action) in
                FBSDKLoginManager().logOut()
                ThreadHelper.runOnMainThread({ 
                    self.refreshSocialState()
                })
            }))
            alertController.addAction(UIAlertAction(title: self.txtTitleLogOut, style: .cancel, handler: nil));
            
            self.present(alertController, animated: true, completion: nil)
        } else {
            FBSDKLoginManager().logIn(withPublishPermissions: ["publish_actions"], from: self) { (loginResult, error) in
                if error != nil || (loginResult?.isCancelled)! {
                    self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("Error logginig in to Facebook", comment: "Alert message, Error logginig in to Facebook"))
                }
            }
        }
    }
    
    override open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if (indexPath.section == 2){
            return indexPath;
        } else {
            return nil
        }
    }
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismiss(animated: true, completion: nil)
        self.setLoading(true)
        let rotatedImage = image.correctlyOrientedImage().resizeImage()
        let currentImage = self.imgPhoto.image
        self.imgPhoto.image = rotatedImage
        self.btnSave.isEnabled = false
        ImageCachingHandler.Instance.saveImage(rotatedImage, uploadId: "") { (success, uploadId, imageUrl) in
            ThreadHelper.runOnMainThread({
                self.setLoading(false, rightBarButtonItem: self.cancelButton)
                self.btnSave.isEnabled = true
                if success {
                    self.currentUser?.imageUrl = imageUrl
                } else {
                    self.imgPhoto.image = currentImage
                    self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("Error uploading photo", comment: "Alert message, Error uploading photo"));
                }
            })
        }
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
}
