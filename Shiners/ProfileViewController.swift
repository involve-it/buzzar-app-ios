//
//  ProfileViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/28/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import AWSS3

public class ProfileViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{
    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var txtLocation: UITextField!
    @IBOutlet weak var txtPhoneNumber: UITextField!
    @IBOutlet weak var txtSkype: UITextField!
    @IBOutlet weak var imgPhoto: UIImageView!
    
    private var imagePickerHandler: ImagePickerHandler?
    
    var currentUser: User?;
    
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
            self.setLoading(false, rightBarButtonItem: self.cancelButton)
            if (success){
                self.dismissSelf()
            } else {
                self.showAlert("Error", message: "An error occurred while saving.")
            }
        }
    }
    
    private func getUser() -> User{
        let user = AccountHandler.Instance.currentUser!;
        user.setProfileDetail(.FirstName, value: self.txtFirstName.text)
        user.setProfileDetail(.LastName, value: self.txtLastName.text)
        user.setProfileDetail(.City, value: self.txtLocation.text)
        user.setProfileDetail(.Phone, value: self.txtPhoneNumber.text)
        user.setProfileDetail(.Skype, value: self.txtSkype.text)
        uploadPhoto();
//        user.imageUrl =
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
    
    override public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if (indexPath.section == 2){
            return indexPath;
        } else {
            return nil
        }
    }
    
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        //        self.setLoading(true)
        
        self.imgPhoto.image = image;
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    
    private func uploadPhoto() {
        // See https://www.codementor.io/tips/5748713276/how-to-upload-images-to-aws-s3-in-swift
        // Setup a new swift project in Xcode and run pod install. Then open the created Xcode workspace.
        // Once AWSS3 framework is ready, we need to configure the authentication:
        
        // configure S3
        let S3BucketName = "shiners/v1.0/public/images";
        
        // configure authentication with Cognito
//        let cognitoPoolID = "us-east-1_ckxes1C2W";
        let cognitoPoolID = "us-east-1:611e9556-43f7-465d-a35b-57a31e11af8b";
        let region = AWSRegionType.USEast1;
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:region,
                                                                identityPoolId:cognitoPoolID)
        let configuration = AWSServiceConfiguration(region:region, credentialsProvider:credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration;
        
        //Add any image to your project and get its URL like this:
        let ext = "png"
        let imageURL = NSBundle.mainBundle().URLForResource("lock_open", withExtension: ext)!;
        
        // Prepare the actual uploader:
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.body = imageURL
        uploadRequest.key = NSProcessInfo.processInfo().globallyUniqueString + "." + ext
        uploadRequest.bucket = S3BucketName
        uploadRequest.contentType = "image/" + ext
        
        // push img to server:
        let transferManager = AWSS3TransferManager.defaultS3TransferManager();
        transferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                print("Upload failed ❌ (\(error))");
            }
            if let exception = task.exception {
                print("Upload failed ❌ (\(exception))");
            }
            if task.result != nil {
            
                let s3URL = NSURL(string: "http://s3.amazonaws.com/\(S3BucketName)/\(uploadRequest.key!)")!;
                print("Uploaded to:\n\(s3URL)");
                let data = NSData(contentsOfURL: s3URL);
                let image = UIImage(data: data!);
                
            }
            else {
                print("Unexpected empty result.")
            }
            return nil
        }
        
    }
}
