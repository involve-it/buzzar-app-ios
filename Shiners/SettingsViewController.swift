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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configNavigationToolBar()
        applyMotionEffect(toView: backgroundImageView, magnitude: 10)
        applyMotionEffect(toView: logoView, magnitude: -15)
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
