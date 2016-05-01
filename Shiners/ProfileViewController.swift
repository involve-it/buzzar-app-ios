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
    
    private let imagePickerController = UIImagePickerController();
    
    override public func scrollViewDidScroll(scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        //self.tableView.reloadRowsAtIndexPaths([NSIndex], withRowAnimation: <#T##UITableViewRowAnimation#>)
    }
    
    @IBAction func btnChangeImage_Click(sender: AnyObject) {
        var alertViewController = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .ActionSheet)
        var index = 0;
        if UIImagePickerController.isSourceTypeAvailable(.Camera){
            alertViewController.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { (_) in
                self.imagePickerController.sourceType = .Camera
                self.presentViewController(self.imagePickerController, animated: true, completion: nil);
            }));
            index += 1;
        }
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            alertViewController.addAction(UIAlertAction(title: "Photo Library", style: .Default, handler: { (_) in
                self.imagePickerController.sourceType = .PhotoLibrary
                self.presentViewController(self.imagePickerController, animated: true, completion: nil);
            }));
            index += 1;
        }
        alertViewController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil));
        if (index == 0){
            alertViewController = UIAlertController(title: "Permissions", message: "Please allow access to Camera or Photo Library in Privacy Settings", preferredStyle: .Alert);
            alertViewController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil));
            
        }
        self.presentViewController(alertViewController, animated: true, completion: nil)
    }
    @IBAction func btnSave_Click(sender: AnyObject) {
        
    }
    var currentUser: User?;
    override public func viewDidLoad() {
        self.imagePickerController.delegate = self;
        self.txtFirstName.delegate = self;
        self.txtLastName.delegate = self;
        self.txtLocation.delegate = self;
        self.txtPhoneNumber.delegate = self;
        self.txtSkype.delegate = self;
        if self.currentUser == nil || self.currentUser! !== ConnectionHandler.Instance.currentUser{
            self.currentUser = ConnectionHandler.Instance.currentUser
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
