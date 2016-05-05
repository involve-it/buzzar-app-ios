//
//  ProfileViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/28/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class ProfileViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{
    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var txtLocation: UITextField!
    @IBOutlet weak var txtPhoneNumber: UITextField!
    @IBOutlet weak var txtSkype: UITextField!
    @IBOutlet weak var imgPhoto: UIImageView!
    
    private var imagePickerHandler: ImagePickerHandler?
    
    //refreshing profile image
    @objc public override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        NSLog("scrolled1")
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
    }
    
    @objc public override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        NSLog("scrolled2")
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
    }
    
    @IBAction func btnChangeImage_Click(sender: AnyObject) {
        self.imagePickerHandler?.displayImagePicker()
    }
    @IBAction func btnSave_Click(sender: AnyObject) {
        //todo: save
    }
    var currentUser: User?;
    override public func viewDidLoad() {
        self.imagePickerHandler = ImagePickerHandler(viewController: self, delegate: self)
        self.txtFirstName.delegate = self;
        self.txtLastName.delegate = self;
        self.txtLocation.delegate = self;
        self.txtPhoneNumber.delegate = self;
        self.txtSkype.delegate = self;
        if self.currentUser == nil || self.currentUser! !== ConnectionHandler.Instance.users.currentUser{
            self.currentUser = ConnectionHandler.Instance.users.currentUser
            self.refreshUserData()
        }
    }
    
    private func refreshUserData(){
        self.txtFirstName.text = self.currentUser?.getProfileDetail(.FirstName)
        self.txtLastName.text = self.currentUser?.getProfileDetail(.LastName)
        self.txtLocation.text = self.currentUser?.getProfileDetail(.City)
        self.txtPhoneNumber.text = self.currentUser?.getProfileDetail(.Phone)
        self.txtSkype.text = self.currentUser?.getProfileDetail(.Skype)
        if let imageUrl = self.currentUser?.imageUrl{
            ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.imgPhoto.image = image;
                })
            })
        } else {
            self.imgPhoto.image = ImageCachingHandler.defaultImage
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
        self.imgPhoto.image = image;
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
}
