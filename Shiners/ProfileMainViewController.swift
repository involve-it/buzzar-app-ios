//
//  ProfileMainViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/13/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit

class ProfileMainViewController: UIViewController {
    lazy var profileViewController: ProfileTableViewController! = {
        var viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("profileViewController") as! ProfileTableViewController
        if let rect = self.navigationController?.navigationBar.frame {
            let y = rect.size.height + rect.origin.y
            viewController.tableView.contentInset = UIEdgeInsetsMake( y, 0, 0, 0)
            viewController.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(y, 0, 0, 0)
        }
        return viewController
    }()
    
    lazy var myPostsViewController: MyPostsViewController! = {
        var viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("myPostsViewController") as! MyPostsViewController
        return viewController
    }()
    
    @IBOutlet weak var typeSwitch: UISegmentedControl!
    
    @IBOutlet var btnAdd: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.switch_ValueChanged(self.typeSwitch)
    }
    
    @IBAction func switch_ValueChanged(sender: UISegmentedControl) {
        var viewController: UIViewController!
        if sender.selectedSegmentIndex == 1{
            viewController = self.profileViewController
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
        } else {
            viewController = self.myPostsViewController
            self.navigationItem.leftBarButtonItem = viewController.editButtonItem()
            self.navigationItem.rightBarButtonItem = btnAdd
        }
        self.addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
        self.view.addSubview(viewController.view)
    }
}