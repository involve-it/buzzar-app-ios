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

class SettingsViewController: UIViewController, LogInViewControllerDelegate {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var logoView: UIStackView!
    @IBOutlet weak var dismissViewController: UIButton!
    
    var isBtnDismiss = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dissmisImage = UIImage(named: "expand_arrow")?.withRenderingMode(.alwaysTemplate)
        dismissViewController.setImage(dissmisImage, for: UIControlState())
        dismissViewController.tintColor = UIColor(netHex: 0xFFFFFF)
        dismissViewController.backgroundColor = UIColor(white: 1, alpha: 0.2)
        dismissViewController.layer.cornerRadius = 4.0
        dismissViewController.isHidden = !self.isBtnDismiss

        configNavigationToolBar()
        
        applyMotionEffect(toView: backgroundImageView, magnitude: 10)
        applyMotionEffect(toView: logoView, magnitude: -15)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.SettingsLoggedOut)
        if (AccountHandler.Instance.isLoggedIn()){
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func applyMotionEffect (toView view:UIView, magnitude:Float) {
        let xMotion = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = -magnitude
        xMotion.maximumRelativeValue = magnitude
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = -magnitude
        yMotion.maximumRelativeValue = magnitude
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [xMotion, yMotion]
        
        view.addMotionEffect(group)
    }

    func configNavigationToolBar() {
        self.navigationController?.tabBarController?.tabBar.isTranslucent = true
        self.navigationController?.tabBarController?.tabBar.backgroundImage = UIImage.imageWithColor(UIColor.clear)
        let frost = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        
        if let bottomBar = self.navigationController?.tabBarController {
            frost.frame = bottomBar.tabBar.bounds
            frost.autoresizingMask = .flexibleWidth
            bottomBar.tabBar.insertSubview(frost, at: 0)
        }
        
        
    }
    
    func presentRegistration() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignUpNavigationController")
        self.present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Action
    @IBAction func clickToLogin(_ sender: UIButton) {
        //loginNavigationController
        let storyboardMain = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboardMain.instantiateViewController(withIdentifier: "NEWloginNavigationController") as! UINavigationController
        let loginVc = vc.viewControllers[0] as! NEWLoginViewController
        loginVc.loginControllerDelegate = self
        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func clickToRegister(_ sender: UIButton) {
        self.presentRegistration()
    }
    
    @IBAction func click_dismissViewController(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension UIImage {
    class func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
