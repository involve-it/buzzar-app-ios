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
    @IBOutlet weak var vkRowLabel: UILabel!
    @IBOutlet weak var facebookRowLabel: UILabel!
    
    @IBOutlet weak var isStatusLabel: UILabel!
    
    
    
    private var currentUser: User?
    
    struct TableViewIdentifierCell {
        static let cellUserProfileNib = "cellUserProfile"
        static let cellAboutMe = "cellAboutMe"
    }
    
    @IBOutlet weak var phoneRowVisible: UITableViewCell!
    @IBOutlet weak var skypeRowVisible: UITableViewCell!
    @IBOutlet weak var vkRowVisible: UITableViewCell!
    @IBOutlet weak var facebookRowVisible: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("Profile", comment: "Navigation title, Profile")
        
        
//        tableView.registerNib(UINib(nibName: TableViewIdentifierCell.cellUserProfileNib, bundle: nil), forCellReuseIdentifier: TableViewIdentifierCell.cellUserProfileNib)
//        
//        tableView.registerNib(UINib(nibName: TableViewIdentifierCell.cellAboutMe, bundle: nil), forCellReuseIdentifier: TableViewIdentifierCell.cellAboutMe)
//        
//        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.phoneRowVisible.hidden = false
        self.skypeRowVisible.hidden = false
        self.vkRowVisible.hidden = false
        self.facebookRowVisible.hidden = false
        
        fillUserData()
        tabelViewEstimatedRowHeight()
        
        
    }

    
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//
//        if (indexPath.section == 0) {
//            if (indexPath.row == 0) {
//                let cell = tableView.dequeueReusableCellWithIdentifier(TableViewIdentifierCell.cellUserProfileNib, forIndexPath: indexPath) as! cellUserProfile
//                return cell
//            } else if (indexPath.row == 1) {
//                let cell = tableView.dequeueReusableCellWithIdentifier(TableViewIdentifierCell.cellAboutMe, forIndexPath: indexPath) as! cellAboutMe
//                return cell
//            }
//        } else if (indexPath.section == 1) {
//            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
//            return cell
//        }

//        return tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
//    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        //Phone
        if (indexPath.section == 1 && indexPath.row == 0) {
            return !self.phoneRowVisible.hidden ? 44 : 0.0
        } else if(indexPath.section == 1 && indexPath.row == 1) {
            return !self.skypeRowVisible.hidden ? 44 : 0.0
        } else if (indexPath.section == 1 && indexPath.row == 2) {
            return !self.vkRowVisible.hidden ? 44 : 0.0
        } else if (indexPath.section == 1 && indexPath.row == 3) {
            return !self.facebookRowVisible.hidden ? 44 : 0.0
        }
        
        return UITableViewAutomaticDimension
    }
    
    
    func tabelViewEstimatedRowHeight() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 4 {
            let alertViewController = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Alert title, Are you sure?"), message: nil, preferredStyle: .ActionSheet)
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Log out", comment: "Alert title, Log out"), style: .Destructive, handler: { (_) in
                AccountHandler.Instance.logoff(){ success in
                    if (success){
                        /*self.currentUser = nil;
                         self.refreshUser();
                         dispatch_async(dispatch_get_main_queue(), {
                         self.tableView.reloadData();
                         })*/
                        
                        
                        //Segue to postViewController
                        self.navigationController?.popViewControllerAnimated(true)
                        
                        
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert, Error"), message: NSLocalizedString("An error occurred", comment: "Alert message, An error occurred"))
                    }
                };
            }))
            
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert title, Cancel"), style: .Cancel, handler: nil))
            
            self.presentViewController(alertViewController, animated: true, completion: nil)
        }
    }
    
    func fillUserData() {
        if let currentUser = AccountHandler.Instance.currentUser {
            
            //Username
            if let firstName = self.currentUser?.getProfileDetailValue(.FirstName),
                lastName = self.currentUser?.getProfileDetailValue(.LastName) {
                txtUserName.text = "\(firstName) \(lastName)"
            } else {
                txtUserName.text = currentUser.username;
            }
            
            if currentUser.isOnline() {
                self.isStatusLabel.text = "online"
                self.isStatusLabel.textColor = UIColor(red: 50/255, green: 185/255, blue: 91/255, alpha: 1)
            } else {
                self.isStatusLabel.text = "offline"
                self.isStatusLabel.textColor = UIColor.redColor()
            }
            
    
            //Phone
            if let isPhone = currentUser.getProfileDetailValue(.Phone) where isPhone != "" {
                self.phoneRowLabel.text = isPhone
                
                //Call
                
                
            } else {
                self.phoneRowVisible.hidden = true
            }
            
            //Skype
            if let isSkype = currentUser.getProfileDetailValue(.Skype) where isSkype != "" {
                self.skypeRowLabel.text = isSkype
            } else {
                self.skypeRowVisible.hidden = true
            }
            
            //VKontakte
            if let isVK = currentUser.getProfileDetailValue(.Vk) where isVK != "" {
                self.vkRowLabel.text = isVK
            } else {
                self.vkRowVisible.hidden = true
            }
            
            //Facebook
            if let isFacebook = currentUser.getProfileDetailValue(.Facebook) where isFacebook != "" {
                self.facebookRowLabel.text = isFacebook
            } else {
                self.facebookRowVisible.hidden = true
            }
            
            //Avatar
            if let imageUrl = currentUser.imageUrl{
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
            
            //UserStatus: online/ofline
            
            
        } else {
            //Load user default data
            imgUserAvatar.image = ImageCachingHandler.defaultAccountImage;
        }
    }
    
    
}
