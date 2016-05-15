//
//  UIViewControllerExtensions.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public extension UIViewController{
    public func setLoading(loading: Bool, rightBarButtonItem: UIBarButtonItem? = nil){
        if (loading){
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray);
            activityIndicator.startAnimating();
            activityIndicator.hidden = false;
            let rightItem = UIBarButtonItem(customView: activityIndicator);
            self.navigationItem.rightBarButtonItem = rightItem;
        } else {
            self.navigationItem.rightBarButtonItem = rightBarButtonItem
        }
    }
    
    public func showAlert(title: String, message: String?){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert);
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil));
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    public func showConnecting(connecting: Bool){
        
    }
}
