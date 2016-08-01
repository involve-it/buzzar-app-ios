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

public class ProfileViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{
    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var txtLocation: UITextField!
    @IBOutlet weak var txtPhoneNumber: UITextField!
    @IBOutlet weak var txtSkype: UITextField!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var cellFacebook: UITableViewCell!
    
    private var imagePickerHandler: ImagePickerHandler?
    
    var currentUser: User?;
    
    @IBOutlet weak var btnSave: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem?
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.dismissSelf();
    }
    
    //refreshing profile image
    @objc public override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
    }
    
    @objc public override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
    }
    
    private func dismissSelf(){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func btnSave_Click(sender: AnyObject) {
        self.setLoading(true)
        let user = self.getUser();
        AccountHandler.Instance.saveUser(user) { (success, errorMessage) in
            ThreadHelper.runOnMainThread({ 
                self.setLoading(false, rightBarButtonItem: self.cancelButton)
                if (success){
                    self.dismissSelf()
                } else {
                    self.showAlert("Error", message: "An error occurred while saving.")
                }
            })
        }
    }
    
    private func getUser() -> User{
        let user = AccountHandler.Instance.currentUser!;
        user.setProfileDetail(.FirstName, value: self.txtFirstName.text)
        user.setProfileDetail(.LastName, value: self.txtLastName.text)
        user.setProfileDetail(.City, value: self.txtLocation.text)
        user.setProfileDetail(.Phone, value: self.txtPhoneNumber.text)
        user.setProfileDetail(.Skype, value: self.txtSkype.text)
        
        user.imageUrl = self.currentUser?.imageUrl
        return user;
    }
    
    @IBAction func btnChangeImage_Click(sender: AnyObject) {
        self.imagePickerHandler?.displayImagePicker()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(btnCancel_Click));
        
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
    
    private func refreshSocialState(){
        if let _ = FBSDKAccessToken.currentAccessToken() {
            cellFacebook.accessoryType = UITableViewCellAccessoryType.None
            cellFacebook.detailTextLabel?.text = "Connected"
        } else {
            cellFacebook.detailTextLabel?.text = ""
        }
    }
    
    private func refreshUserData(){
        self.txtFirstName.text = self.currentUser?.getProfileDetailValue(.FirstName)
        self.txtLastName.text = self.currentUser?.getProfileDetailValue(.LastName)
        self.txtLocation.text = self.currentUser?.getProfileDetailValue(.City)
        self.txtPhoneNumber.text = self.currentUser?.getProfileDetailValue(.Phone)
        self.txtSkype.text = self.currentUser?.getProfileDetailValue(.Skype)
        if let imageUrl = self.currentUser?.imageUrl{
            ImageCachingHandler.Instance.getImageFromUrl(imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.imgPhoto.image = image;
                })
            })
        } else {
            self.imgPhoto.image = ImageCachingHandler.defaultAccountImage
        }
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var animated = false
        
        if indexPath.section == 2{
            //facebook
            if indexPath.row == 0 {
                self.loginFacebook()
            }
            animated = true
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
    }
    
    private func loginFacebook(){
        if let _ = FBSDKAccessToken.currentAccessToken() {
            let alertController = UIAlertController(title: "Facebook", message: "Do you wish to log out?", preferredStyle: .Alert);
            alertController.addAction(UIAlertAction(title: "Log out", style: .Destructive, handler: { (action) in
                FBSDKLoginManager().logOut()
                ThreadHelper.runOnMainThread({ 
                    self.refreshSocialState()
                })
            }))
            alertController.addAction(UIAlertAction(title: "Log out", style: .Cancel, handler: nil));
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            FBSDKLoginManager().logInWithPublishPermissions(["publish_actions"], fromViewController: self) { (loginResult, error) in
                if error != nil || loginResult.isCancelled {
                    self.showAlert("Error", message: "Error logginig in to Facebook")
                }
            }
        }
    }
    
    override public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        if (indexPath.section == 2){
            return indexPath;
        } else {
            return nil
        }
    }
    
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        self.setLoading(true)
        let rotatedImage = image.correctlyOrientedImage().resizeImage()
        let currentImage = self.imgPhoto.image
        self.imgPhoto.image = rotatedImage
        self.btnSave.enabled = false
        ImageCachingHandler.Instance.saveImage(rotatedImage) { (success, imageUrl) in
            ThreadHelper.runOnMainThread({
                self.setLoading(false, rightBarButtonItem: self.cancelButton)
                self.btnSave.enabled = true
                if success {
                    self.currentUser?.imageUrl = imageUrl
                } else {
                    self.imgPhoto.image = currentImage
                    self.showAlert("Error", message: "Error uploading photo");
                }
            })
        }
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
}
