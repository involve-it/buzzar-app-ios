//
//  NewMessageView.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/18/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class NewMessageView: UIView, UITableViewDataSource, UITextViewDelegate, UITableViewDelegate, LocationHandlerDelegate {
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var txtTo: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    var timer:Timer?
    var recipient: User?
    var showNearbyUsers = true
    
    var nearbyUsers = [User]()
    var parentFrame: CGRect!
    var keyboardHeight = CGFloat(0)
    var inputViewHeight = CGFloat(0)
    
    func setupView(frame: CGRect, navigationController: UINavigationController, inputViewHeight: CGFloat){
        self.inputViewHeight = inputViewHeight
        self.parentFrame = frame
        let top = CGFloat(navigationController.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.height)
        self.frame = CGRect(x: 0, y: top, width: frame.width, height: self.parentFrame.height - top - self.keyboardHeight - self.inputViewHeight - 1)
        self.bringSubview(toFront: self.tableView)
        self.layoutSubviews()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.isHidden = true
        
        /*if self.recipient == nil {
            self.txtTo.becomeFirstResponder()
        }*/
        
        self.txtTo.delegate = self
        
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: self.frame.height - 1, width: self.frame.width, height: 1)
        layer.backgroundColor = UIColor(white: 0.8, alpha: 1).cgColor
        self.layer.addSublayer(layer)
        
        if self.showNearbyUsers {
            self.getNearbyUsers()
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        }
    }
    
    func keyboardWillHide(){
        self.keyboardHeight = 0
        self.keyboardHeightChanged()
    }
    
    func keyboardWillShow(notification: Notification){
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardHeight = keyboardSize.height
            self.keyboardHeightChanged()
        }
    }
    
    func keyboardHeightChanged(){
        self.frame.size.height = self.parentFrame.height - self.frame.origin.y - self.keyboardHeight - self.inputViewHeight - 1
        self.layoutSubviews()
    }
    
    func getNearbyUsers(){
        if let lastLocation = LocationHandler.lastLocation {
            ConnectionHandler.Instance.users.getNearbyUsers(lat: Float(lastLocation.coordinate.latitude), lng: Float(lastLocation.coordinate.longitude), callback: { (success, errorId, errorMessage, users) in
                //if success {
                    ThreadHelper.runOnMainThread({
                        self.keyboardHeightChanged()
                        self.nearbyUsers = AccountHandler.Instance.allUsers
                            //users as! [User]
                        self.tableView.reloadData()
                    })
                //}
            })
        } else {
            let locationHandler = LocationHandler()
            locationHandler.delegate = self
            
            locationHandler.getLocationOnce(false)
        }
    }
    
    func locationReported(_ geocoderInfo: GeocoderInfo) {
        self.getNearbyUsers()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.txtTo.textColor = UIColor.black
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkUser), userInfo: nil, repeats: false)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
        self.checkUser()
    }
    
    func checkUser(){
        if let username = self.txtTo.text, username != "" {
            if ConnectionHandler.Instance.isNetworkConnected() {
                self.activityIndicator.startAnimating()
                ConnectionHandler.Instance.users.getUserByName(username, callback: { (success, errorId, error, result) in
                    ThreadHelper.runOnMainThread {
                        if success {
                            self.recipient = (result as! User)
                            self.txtTo.textColor = UIColor.green
                        } else {
                            self.txtTo.textColor = UIColor.red
                        }
                        self.activityIndicator.stopAnimating()
                    }
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Nearby users", comment: "Section title, Nearby users")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nearbyUsers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = self.nearbyUsers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "nearbyUserCell")!
        cell.textLabel?.text = user.username
        
        return cell
    }
}
