//
//  UIViewControllerExtensions.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public extension UIViewController{
    public func setLoading(_ loading: Bool, rightBarButtonItem: UIBarButtonItem? = nil){
        if (loading){
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray);
            activityIndicator.startAnimating();
            activityIndicator.isHidden = false;
            let rightItem = UIBarButtonItem(customView: activityIndicator);
            self.navigationItem.rightBarButtonItem = rightItem;
        } else {
            self.navigationItem.rightBarButtonItem = rightBarButtonItem
        }
    }
    
    
    public func showAlert(_ title: String, message: String?){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Alert title, Dismiss"), style: .default, handler: nil));
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    public func showConnecting(_ connecting: Bool){
        
    }
    
    func displayModalAlert(_ title: String, message: String? = nil) -> UIAlertController{
        let pending = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        //create an activity indicator
        //let indicator = UIActivityIndicatorView(frame: CGRectMake(-12, 22, 37, 37))
        //indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        //indicator.activityIndicatorViewStyle = .Gray
        //add the activity indicator as a subview of the alert controller's view
        //pending.view.addSubview(indicator)
        //pending.view.layoutIfNeeded()
        
        //indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        //indicator.startAnimating()
        
        self.present(pending, animated: true, completion: nil)
        
        return pending
    }
    
    func isNetworkReachable() -> Bool {
        if !ConnectionHandler.Instance.isNetworkConnected(){
            self.showAlert(NSLocalizedString("Network Unreachable", comment: "Alert title, Network Unreachable"), message: NSLocalizedString("Looks like you are not connected to Internet. Please, check you Internet connection and try again.", comment: "Alert message, Looks like you are not connected to Internet. Please, check you Internet connection and try again."))
            return false
        }
        return true
    }
    
    func isVisible() -> Bool{
        return self.isViewLoaded && self.view.window != nil
    }
    
}
