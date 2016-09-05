//
//  SWLeftMenuTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 9/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class SWLeftMenuTableViewController: UITableViewController {
    
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var txtUsernameLabel: UILabel!
    
    let textColorCell = UIColor(white: 255, alpha: 0.9)
    
    var gradientLayer: CAGradientLayer!
    var currentUser: User?
    
    struct InitialNameViewControllers {
        static let postsViewController = "postsViewController"
        static let settingsUserProfile = "settingsUserProfile"
        static let settingsLogInUser = "settingsLogInUser"
        static let settingsLogOutUser = "settingsLogOutUser"
        static let myPosts = "myPostsViewController"
        static let myMessages = "myMessagesViewController"
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if self.currentUser == nil || self.currentUser! !== AccountHandler.Instance.currentUser {
            self.currentUser = AccountHandler.Instance.currentUser
            self.refreshUserData()
        }
        
        configLeftNavigationCell()
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        createGradientLayer()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func refreshUserData() {
        
        //Username
        if let firstName = self.currentUser?.getProfileDetailValue(.FirstName),
            lastName = self.currentUser?.getProfileDetailValue(.LastName) {
            txtUsernameLabel.text = "\(firstName) \(lastName)"
        } else {
            txtUsernameLabel.text = currentUser!.username
        }
        
        //Avatar
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
    
    func configLeftNavigationCell() {
        //Clear separator tableview
        self.tableView.separatorColor = UIColor(white: 255, alpha: 0.3)
        
        self.imgUserAvatar.layer.cornerRadius = 4.0
        //self.txtUsernameLabel.text = ""
        self.txtUsernameLabel.textColor = textColorCell
        
    }
    
    func createGradientLayer() {
        
        let colorSets: Dictionary<String, CGColor> = [
            "end": UIColor(red: 84/255, green: 84/255, blue: 97/255, alpha: 1).CGColor,
            "start": UIColor(red: 100/255, green: 100/255, blue: 127/255, alpha: 1).CGColor
        ]
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: self.tableView.bounds.height)
        gradientLayer.colors = [colorSets["start"]!, colorSets["end"]!]
        
        let backgroundView = UIView(frame: self.gradientLayer.frame)
        backgroundView.layer.insertSublayer(gradientLayer, atIndex: 0)
        self.tableView.backgroundView = backgroundView
        //self.view.layer.addSublayer(gradientLayer)
        
        
        /*
         let gradientLayer = CAGradientLayer()
         gradientLayer.colors = gradientBackgroundColors
         gradientLayer.frame = sender.tableView.bounds
         
         let backgroundView = UIView(frame: sender.tableView.bounds)
         backgroundView.layer.insertSublayer(gradientLayer, atIndex: 0)
         sender.tableView.backgroundView = backgroundView
         */
        
    }
    
    func changeViewControllers() {
        
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textColor = textColorCell
        
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 87/255, green: 87/255, blue: 110/255, alpha: 1)
        cell.selectedBackgroundView = selectedView
        
        //Disabled cell
        if indexPath.item == 2 || indexPath.item == 3 || indexPath.item == 6 {
            cell.textLabel?.enabled = false
        }
        
    }
    
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        
        //Profile
        if indexPath.item == 0 {
            
            var vc: UIViewController?
            if currentUser != nil {
                vc = storyBoard.instantiateViewControllerWithIdentifier(InitialNameViewControllers.settingsLogInUser)
            } else {
                vc = storyBoard.instantiateViewControllerWithIdentifier(InitialNameViewControllers.settingsLogOutUser)
            }
            
            self.pushSelectFrontViewController(vc)
        }
        
        //Main
        if indexPath.item == 1 {
            let vc = storyBoard.instantiateViewControllerWithIdentifier(InitialNameViewControllers.postsViewController)
            
            //let navigationController:UINavigationController = UINavigationController(rootViewController: vc)
            //self.revealViewController().setFrontViewController(navigationController, animated: true)
            
            self.pushSelectFrontViewController(vc)
        }
        
        //Map
        if indexPath.item == 2 {
            
        }
        
        //Favorites
        if indexPath.item == 3 {}
        
        //My posts
        if indexPath.item == 4 {
            
            /*let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.1)*/
            
            let vc = storyBoard.instantiateViewControllerWithIdentifier(InitialNameViewControllers.myPosts)
            self.pushSelectFrontViewController(vc)
        }
        
        //My messages
        if indexPath.item == 5 {
            let vc = storyBoard.instantiateViewControllerWithIdentifier(InitialNameViewControllers.myMessages)
            self.pushSelectFrontViewController(vc)
        }
        
        //Feddback
        if indexPath.item == 6 {}
        
        //Settings UserProfile
        if indexPath.item == 7 {
            let vc = storyBoard.instantiateViewControllerWithIdentifier(InitialNameViewControllers.settingsUserProfile)
            
            let navigationController:UINavigationController = UINavigationController(rootViewController: vc)
            self.revealViewController().pushFrontViewController(navigationController, animated: true)
        
            //let s = SWRevealViewControllerSeguePushController.init(identifier: "settingsUserProfile", source: self, destination: vc)
            //s.perform()
        }

        tableView.reloadData()
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor(red: 87/255, green: 87/255, blue: 110/255, alpha: 1)
        
        //tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func pushSelectFrontViewController(viewController: UIViewController?) {
        self.revealViewController().pushFrontViewController(viewController, animated: true)
    }

}


