//
//  SettingsViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/21/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        configNavigationToolBar()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func configNavigationToolBar() {
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.backgroundColor = UIColor.whiteColor()
        self.navigationController!.navigationBar.translucent = false
    }
    
    
    
    // MARK: - Action
    @IBAction func clickToLogin(sender: UIButton) {
        //loginNavigationController
        let storyboardMain = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboardMain.instantiateViewControllerWithIdentifier("NEWloginNavigationController")
        self.presentViewController(vc, animated: true, completion: nil)
    }

    @IBAction func clickToRegister(sender: UIButton) {
        let storyboardMain = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboardMain.instantiateViewControllerWithIdentifier("SignUpNavigationController")
        self.presentViewController(vc, animated: true, completion: nil)
    }
}
