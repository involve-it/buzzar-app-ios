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
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Alert title, Dismiss"), style: .Default, handler: nil));
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    public func showConnecting(connecting: Bool){
        
    }
    
    func displayModalAlert(title: String) -> UIAlertController{
        let pending = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        
        //create an activity indicator
        //let indicator = UIActivityIndicatorView(frame: CGRectMake(50, 50, 37, 37))
        //indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        //indicator.activityIndicatorViewStyle = .Gray
        //add the activity indicator as a subview of the alert controller's view
        //pending.view.addSubview(indicator)
        //pending.view.layoutIfNeeded()
        
        //indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        //indicator.startAnimating()
        
        self.presentViewController(pending, animated: true, completion: nil)
        
        return pending
    }
}
