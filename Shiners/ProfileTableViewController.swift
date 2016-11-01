//
//  ProfileTableViewController.swift
//  
//
//  Created by Вячеслав on 8/16/16.
//
//

import UIKit

class ProfileTableViewController: UITableViewController {
    
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var txtUserName: UILabel!
    @IBOutlet weak var phoneRowLabel: UILabel!
    @IBOutlet weak var skypeRowLabel: UILabel!
    //@IBOutlet weak var vkRowLabel: UILabel!
    //@IBOutlet weak var facebookRowLabel: UILabel!
   
    
    @IBOutlet weak var btnMessageToUser: UIButton!
    @IBOutlet weak var btnCallToUser: UIButton!
    @IBOutlet weak var isStatusLabel: UILabel!
    @IBOutlet weak var btnCloseVC: UIBarButtonItem!
    @IBOutlet weak var editProfile: UIBarButtonItem!
    
    var extUser: User?
    var postId: String?
    private var currentUser: User!
    
    struct TableViewIdentifierCell {
        static let cellUserProfileNib = "cellUserProfile"
        static let cellAboutMe = "cellAboutMe"
    }
    
    @IBOutlet weak var phoneRowVisible: UITableViewCell!
    @IBOutlet weak var skypeRowVisible: UITableViewCell!
    //@IBOutlet weak var vkRowVisible: UITableViewCell!
    //@IBOutlet weak var facebookRowVisible: UITableViewCell!
    @IBOutlet weak var cbNearbyNotifications: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("Settings", comment: "Navigation title, Settings")
        
        self.imgUserAvatar.layer.cornerRadius = self.imgUserAvatar.frame.width / 2
        self.imgUserAvatar.clipsToBounds = true
        self.imgUserAvatar.contentMode = .ScaleAspectFill
        
        self.btnCallToUser.enabled = false
        self.btnMessageToUser.enabled = false
        self.btnCallToUser.centerTextButton()
        self.btnMessageToUser.centerTextButton()
        
        
        self.phoneRowVisible.hidden = false
        self.skypeRowVisible.hidden = false
        //self.vkRowVisible.hidden = false
        //self.facebookRowVisible.hidden = false
        
        tabelViewEstimatedRowHeight()
        fillUserData()
        
        if extUser == nil {
            if let index = self.navigationItem.leftBarButtonItems?.indexOf(self.btnCloseVC){
                self.navigationItem.leftBarButtonItems?.removeAtIndex(index)
            }
        } else {
            if let index = self.navigationItem.rightBarButtonItems?.indexOf(self.editProfile){
                self.navigationItem.rightBarButtonItems?.removeAtIndex(index)
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(meteorLoaded), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(meteorLoaded), name: NotificationManager.Name.UserUpdated.rawValue, object: nil)
    }
    
    func meteorLoaded(){
        self.fillUserData()
        if let editPorfileButton = self.editProfile{
            editPorfileButton.enabled = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if AccountHandler.Instance.status != .Completed {
            //self.editProfile.enabled = false
        } else {
            //self.editProfile.enabled = true
        }
    }

    @IBAction func cendMessageToUser(sender: UIButton) {
        let alertController = UIAlertController(title: NSLocalizedString("New message", comment: "Alert title, New message"), message: nil, preferredStyle: .Alert);
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = NSLocalizedString("Message", comment: "Placeholder, Message")
        }
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Send", comment: "Alert title, Send"), style: .Default, handler: { (action) in
            if let text = alertController.textFields?[0].text where text != "" {
                alertController.resignFirstResponder()
                let message = MessageToSend()
                message.destinationUserId = self.extUser!.id
                message.message = alertController.textFields![0].text
                message.associatedPostId = self.postId
                ConnectionHandler.Instance.messages.sendMessage(message){ success, errorId, errorMessage, result in
                    if success {
                        AccountHandler.Instance.updateMyChats()
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                    }
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert, title, Cancel"), style: .Cancel, handler: {action in
            alertController.resignFirstResponder()
        }));
        self.presentViewController(alertController, animated: true) {
            alertController.textFields![0].becomeFirstResponder()
        }
    }
    
    @IBAction func callToUser(sender: UIButton) {
        if let phoneNumber = self.phoneRowLabel.text {
            callNumberToUser(phoneNumber)
        }
    }
    
    func callNumberToUser(phoneNumber: String) {
        if let url =  NSURL(string: "tel://\(phoneNumber)") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func closeVC(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func cbNearbyNotifications_Changed(sender: UISwitch) {
        if sender.on && !UIApplication.sharedApplication().isRegisteredForRemoteNotifications(){
            self.showAlert(NSLocalizedString("Notifications", comment: "Alert title, Notifications"), message: NSLocalizedString("To receive notifications, please allow this in device Settings.", comment: "Alert message, to receive notifications, please allow this in device Settings."));
            sender.on = false
        } else {
            let initialState = currentUser.enableNearbyNotifications
            currentUser.enableNearbyNotifications = sender.on
            
            AccountHandler.Instance.saveUser(currentUser) { (success, errorMessage) in
                if (!success){
                    ThreadHelper.runOnMainThread({
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("An error occurred while saving.", comment: "Title message, an error occurred while saving."))
                        self.currentUser?.enableNearbyNotifications = initialState
                        sender.on = initialState ?? false
                    })
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        //Phone
        if (indexPath.section == 0 && indexPath.row == 0) {
            return !self.phoneRowVisible.hidden ? 44 : 0.0
        } else if(indexPath.section == 0 && indexPath.row == 1) {
            return !self.skypeRowVisible.hidden ? 44 : 0.0
        }
//        } else if (indexPath.section == 1 && indexPath.row == 2) {
//            return !self.vkRowVisible.hidden ? 44 : 0.0
//        } else if (indexPath.section == 1 && indexPath.row == 3) {
//            return !self.facebookRowVisible.hidden ? 44 : 0.0
//        }
        
        return UITableViewAutomaticDimension
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return !(self.extUser != nil) ? 4 : 1
    }
    
    func tabelViewEstimatedRowHeight() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 3 {
            let alertViewController = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Alert title, Are you sure?"), message: nil, preferredStyle: .ActionSheet)
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Log out", comment: "Alert title, Log out"), style: .Destructive, handler: { (_) in
                AccountHandler.Instance.logoff(){ success in
                    if (!success){
                        ThreadHelper.runOnMainThread({ 
                            self.showAlert(NSLocalizedString("Error", comment: "Alert, Error"), message: NSLocalizedString("An error occurred", comment: "Alert message, An error occurred"))
                        })
                    }
                };
            }))
            
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert title, Cancel"), style: .Cancel, handler: nil))
            
            self.presentViewController(alertViewController, animated: true, completion: nil)
        }
    }
    
    func fillUserData() {
        var user: User!
        user = (extUser ?? AccountHandler.Instance.currentUser) ?? CachingHandler.Instance.currentUser
        
        if user != nil {
            self.currentUser = user
            
            if UIApplication.sharedApplication().isRegisteredForRemoteNotifications() && (currentUser.enableNearbyNotifications ?? false){
                self.cbNearbyNotifications.on = true
            } else {
                self.cbNearbyNotifications.on = false
            }
            
            //Username
            if let firstName = self.currentUser?.getProfileDetailValue(.FirstName),
               lastName = self.currentUser?.getProfileDetailValue(.LastName) where firstName != "" || lastName != "" {
                if (lastName != ""){
                    txtUserName.text = "\(firstName) \(lastName)"
                } else {
                    txtUserName.text = "\(firstName)"
                }
            } else {
                txtUserName.text = self.currentUser.username
            }
            
            if self.currentUser.isOnline() {
                self.isStatusLabel.text = "online"
                self.isStatusLabel.textColor = UIColor(red: 50/255, green: 185/255, blue: 91/255, alpha: 1)
            } else {
                self.isStatusLabel.text = "offline"
                self.isStatusLabel.textColor = UIColor.redColor()
            }
            
    
            //Phone
            if let isPhone = self.currentUser.getProfileDetailValue(.Phone) where isPhone != "" {
                self.phoneRowLabel.text = isPhone
                self.btnCallToUser.enabled = true
            } else {
                self.phoneRowVisible.hidden = true
                self.btnCallToUser.enabled = false
            }
            
            //Skype
            if let isSkype = self.currentUser.getProfileDetailValue(.Skype) where isSkype != "" {
                self.skypeRowLabel.text = isSkype
            } else {
                self.skypeRowVisible.hidden = true
            }
            
            //VKontakte
            /*if let isVK = currentUser.getProfileDetailValue(.Vk) where isVK != "" {
                self.vkRowLabel.text = isVK
            } else {
                self.vkRowVisible.hidden = true
            }*/
            
            //Facebook
            /*if let isFacebook = currentUser.getProfileDetailValue(.Facebook) where isFacebook != "" {
                self.facebookRowLabel.text = isFacebook
            } else {
                self.facebookRowVisible.hidden = true
            }*/
            
            //Avatar
            if let imageUrl = self.currentUser.imageUrl{
                ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.imgUserAvatar.image = image
                    })
                })
            } else {
                imgUserAvatar.image = ImageCachingHandler.defaultAccountImage;
            }
            
            //Location
//            if let userLocation = currentUser.locations?.first {
//                txtUserLocation.text = userLocation.name
//            } else {
//                txtUserLocation.text = NSLocalizedString("Location is hidden", comment: "Text, Location is hidden")
//            }

            
            
        } else {
            //Load user default data
            imgUserAvatar.image = ImageCachingHandler.defaultAccountImage;
        }
        
        if self.postId != nil && self.extUser != nil {
           self.btnMessageToUser.enabled = true
        } else {
           self.btnMessageToUser.enabled = false
        }
        
        if self.skypeRowVisible.hidden{
            self.phoneRowVisible.separatorInset = UIEdgeInsetsZero
            self.phoneRowVisible.layoutMargins = UIEdgeInsetsZero
            //self.phoneRowVisible.preservesSuperviewLayoutMargins = false
        }
    }
}
