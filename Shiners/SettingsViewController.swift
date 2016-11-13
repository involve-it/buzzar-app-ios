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
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var logoView: UIStackView!
    @IBOutlet weak var dismissViewController: UIButton!
    
    var isBtnDismiss = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dissmisImage = UIImage(named: "expand_arrow")?.imageWithRenderingMode(.AlwaysTemplate)
        dismissViewController.setImage(dissmisImage, forState: .Normal)
        dismissViewController.tintColor = UIColor(netHex: 0xFFFFFF)
        dismissViewController.backgroundColor = UIColor(white: 1, alpha: 0.2)
        dismissViewController.layer.cornerRadius = 4.0
        dismissViewController.hidden = !self.isBtnDismiss

        configNavigationToolBar()
        
        applyMotionEffect(toView: backgroundImageView, magnitude: 10)
        applyMotionEffect(toView: logoView, magnitude: -15)
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (AccountHandler.Instance.isLoggedIn()){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func applyMotionEffect (toView view:UIView, magnitude:Float) {
        let xMotion = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = -magnitude
        xMotion.maximumRelativeValue = magnitude
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = -magnitude
        yMotion.maximumRelativeValue = magnitude
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [xMotion, yMotion]
        
        view.addMotionEffect(group)
    }

    func configNavigationToolBar() {
        
        self.navigationController?.tabBarController?.tabBar.backgroundImage = UIImage.imageWithColor(UIColor.clearColor())
        let frost = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        
        if let bottomBar = self.navigationController?.tabBarController {
            frost.frame = bottomBar.tabBar.bounds
            frost.autoresizingMask = .FlexibleWidth
            bottomBar.tabBar.insertSubview(frost, atIndex: 0)
        }
        
        
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
    
    @IBAction func click_dismissViewController(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
