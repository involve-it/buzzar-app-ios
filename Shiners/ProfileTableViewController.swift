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
    
    @IBOutlet weak var profileImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contactStackViewVerticatConstraint: NSLayoutConstraint!
    @IBOutlet weak var contactStackView: UIStackView!
    var extUser: User?
    var postId: String?
    fileprivate var currentUser: User!
    
    struct TableViewIdentifierCell {
        static let cellUserProfileNib = "cellUserProfile"
        static let cellAboutMe = "cellAboutMe"
    }
    
    @IBOutlet weak var phoneRowVisible: UITableViewCell!
    @IBOutlet weak var skypeRowVisible: UITableViewCell!
    //@IBOutlet weak var vkRowVisible: UITableViewCell!
    //@IBOutlet weak var facebookRowVisible: UITableViewCell!
    
    var modalSpinner: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationItem.title = NSLocalizedString("Settings", comment: "Navigation title, Settings")
        
        self.btnCallToUser.isEnabled = false
        self.btnMessageToUser.isEnabled = false
        self.btnCallToUser.centerTextButton()
        self.btnMessageToUser.centerTextButton()
        
        
        self.phoneRowVisible.isHidden = false
        self.skypeRowVisible.isHidden = false
        //self.vkRowVisible.hidden = false
        //self.facebookRowVisible.hidden = false
        
        tabelViewEstimatedRowHeight()
        fillUserData()
        
        if extUser == nil {
            if let index = self.navigationItem.leftBarButtonItems?.index(of: self.btnCloseVC){
                self.navigationItem.leftBarButtonItems?.remove(at: index)
            }
            self.contactStackView.isHidden = true
            self.contactStackViewVerticatConstraint.constant = 0
            self.isStatusLabel.isHidden = true
            self.profileImageHeightConstraint.constant = 140
            self.profileImageWidthConstraint.constant = 140
        } else {
            if let firstName = self.extUser!.getProfileDetailValue(.FirstName), let lastName = self.extUser!.getProfileDetailValue(.LastName){
                self.navigationItem.title = "\(firstName) \(lastName)"
            } else {
                self.navigationItem.title = self.extUser!.username
            }
        }
        
        self.imgUserAvatar.layer.cornerRadius = self.profileImageHeightConstraint.constant / 2
        self.imgUserAvatar.clipsToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(fillUserData), name: NSNotification.Name(rawValue: NotificationManager.Name.AccountUpdated.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fillUserData), name: NSNotification.Name(rawValue: NotificationManager.Name.UserUpdated.rawValue), object: nil)
    }
    
    @IBAction func cendMessageToUser(_ sender: UIButton) {
        AppAnalytics.logEvent(.ProfileScreen_Message)
        let alertController = UIAlertController(title: NSLocalizedString("New message", comment: "Alert title, New message"), message: nil, preferredStyle: .alert);
        
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Message", comment: "Placeholder, Message")
        }
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Send", comment: "Alert title, Send"), style: .default, handler: { (action) in
            AppAnalytics.logEvent(.ProfileScreen_Msg_Send)
            if let text = alertController.textFields?[0].text, text != "" {
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
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert, title, Cancel"), style: .cancel, handler: {action in
            AppAnalytics.logEvent(.ProfileScreen_Msg_Cancel)
            alertController.resignFirstResponder()
        }));
        self.present(alertController, animated: true) {
            alertController.textFields![0].becomeFirstResponder()
        }
    }
    
    @IBAction func callToUser(_ sender: UIButton) {
        AppAnalytics.logEvent(.ProfileScreen_Call)
        if let phoneNumber = self.phoneRowLabel.text {
            callNumberToUser(phoneNumber)
        }
    }
    
    func callNumberToUser(_ phoneNumber: String) {
        if let url =  URL(string: "tel://\(phoneNumber)") {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func closeVC(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func cbNearbyNotifications_Changed(_ sender: UISwitch) {
        AppAnalytics.logEvent(.SettingsLoggedInScreen_Notify_Change)
        if sender.isOn && !UIApplication.shared.isRegisteredForRemoteNotifications{
            self.showAlert(NSLocalizedString("Notifications", comment: "Alert title, Notifications"), message: NSLocalizedString("To receive notifications, please allow this in device Settings.", comment: "Alert message, to receive notifications, please allow this in device Settings."));
            sender.isOn = false
        } else {
            let initialState = currentUser.enableNearbyNotifications
            currentUser.enableNearbyNotifications = sender.isOn
            
            AccountHandler.Instance.saveUser(currentUser) { (success, errorMessage) in
                if (!success){
                    ThreadHelper.runOnMainThread({
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: NSLocalizedString("An error occurred while saving.", comment: "Title message, an error occurred while saving."))
                        self.currentUser?.enableNearbyNotifications = initialState
                        sender.isOn = initialState ?? false
                    })
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        //Phone
        if (indexPath.section == 0 && indexPath.row == 0) {
            return !self.phoneRowVisible.isHidden ? 44 : 0.0
        } else if(indexPath.section == 0 && indexPath.row == 1) {
            return !self.skypeRowVisible.isHidden ? 44 : 0.0
        }
//        } else if (indexPath.section == 1 && indexPath.row == 2) {
//            return !self.vkRowVisible.hidden ? 44 : 0.0
//        } else if (indexPath.section == 1 && indexPath.row == 3) {
//            return !self.facebookRowVisible.hidden ? 44 : 0.0
//        }
        
        return UITableViewAutomaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return !(self.extUser != nil) ? 3 : 1
    }
    
    func tabelViewEstimatedRowHeight() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            AppAnalytics.logEvent(.SettingsLoggedInScreen_Logout)
            let alertViewController = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Alert title, Are you sure?"), message: nil, preferredStyle: .actionSheet)
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Log out", comment: "Alert title, Log out"), style: .destructive, handler: { (_) in
                AppAnalytics.logEvent(.SettingsLoggedInScreen_DoLogout)
                self.doLogout()
            }))
            
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert title, Cancel"), style: .cancel, handler: { (_) in
                AppAnalytics.logEvent(.SettingsLoggedInScreen_CancelLogout)
            }))
            
            self.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    func doLogout(){
        if !self.isNetworkReachable(){
            return
        }
        if self.modalSpinner == nil {
            self.modalSpinner = self.displayModalAlert(NSLocalizedString("Logging out...", comment: "Alert title, logging out..."))
        }
        
        if ConnectionHandler.Instance.isConnected() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            AccountHandler.Instance.logoff(){ success in
                ThreadHelper.runOnMainThread({
                    self.modalSpinner!.dismiss(animated: true, completion: { 
                        if (success){
                            let mainViewController = (self.parent as! ProfileMainViewController)
                            mainViewController.typeSwitch.selectedSegmentIndex = 0
                            mainViewController.switch_ValueChanged(mainViewController.typeSwitch)
                        } else {
                            self.showAlert(NSLocalizedString("Error", comment: "Alert, Error"), message: NSLocalizedString("An error occurred", comment: "Alert message, An error occurred"))
                        }
                    })
                })
            }
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(doLogout), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }
    
    func fillUserData() {
        var user: User!
        user = (extUser ?? AccountHandler.Instance.currentUser) ?? CachingHandler.Instance.currentUser
        
        if user != nil {
            self.currentUser = user
            
            //Username
            if let firstName = self.currentUser?.getProfileDetailValue(.FirstName),
               let lastName = self.currentUser?.getProfileDetailValue(.LastName), firstName != "" || lastName != "" {
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
                self.isStatusLabel.textColor = UIColor.red
            }
            
    
            //Phone
            if let isPhone = self.currentUser.getProfileDetailValue(.Phone), isPhone != "" {
                self.phoneRowLabel.text = isPhone
                self.btnCallToUser.isEnabled = true
            } else {
                self.phoneRowVisible.isHidden = true
                self.btnCallToUser.isEnabled = false
            }
            
            //Skype
            if let isSkype = self.currentUser.getProfileDetailValue(.Skype), isSkype != "" {
                self.skypeRowLabel.text = isSkype
            } else {
                self.skypeRowVisible.isHidden = true
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
                    DispatchQueue.main.async(execute: {
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
           self.btnMessageToUser.isEnabled = true
        } else {
           self.btnMessageToUser.isEnabled = false
        }
        
        if self.skypeRowVisible.isHidden{
            self.phoneRowVisible.separatorInset = UIEdgeInsets.zero
            self.phoneRowVisible.layoutMargins = UIEdgeInsets.zero
            //self.phoneRowVisible.preservesSuperviewLayoutMargins = false
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "editProfile"{
            return self.isNetworkReachable() && AccountHandler.Instance.status == .completed
        }
        
        return true
    }
}
