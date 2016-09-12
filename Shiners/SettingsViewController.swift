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

    let storyboardMain = UIStoryboard(name: "Main", bundle: nil)
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configNavigationToolBar()
        
        //conf. LeftMenu
        self.configureOfLeftMenu()
        self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
       
        
        if AccountHandler.Instance.isLoggedIn() {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyBoard.instantiateViewControllerWithIdentifier("postsViewController")
            self.revealViewController().pushFrontViewController(vc, animated: false)
            
           self.navigationController?.dismissViewControllerAnimated(false, completion: nil)
        }
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
        let vc = storyboardMain.instantiateViewControllerWithIdentifier("NEWloginNavigationController")
        self.presentViewController(vc, animated: true, completion: nil)
    }

    @IBAction func clickToRegister(sender: UIButton) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("SignUpViewController")
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
