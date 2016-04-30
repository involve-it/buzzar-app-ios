//
//  LaunchViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class LaunchViewController : UIViewController{
    public override func viewDidLoad() {
        ConnectionHandler.Instance.onConnected { 
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("mainViewController")
            self.presentViewController(vc, animated: false, completion: nil)
        }
    }
}
