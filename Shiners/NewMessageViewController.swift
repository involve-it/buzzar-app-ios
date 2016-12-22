//
//  NewMessageViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/19/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class NewMessageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, LocationHandlerDelegate, UITextViewDelegate {
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var txtTo: UITextView!
    @IBOutlet weak var tableView: UITableView!

    
    //var parentContainerView: UIView!
    var timer:Timer?
    var layoutTimer:Timer?
    var recipient: User?
    var showNearbyUsers = true
    
    var nearbyUsers = [User]()
    var parentFrame: CGRect!
    var keyboardOriginY = CGFloat(0)
    var inputViewHeight = CGFloat(0)
    var keyboardController: JSQMessagesKeyboardController!
    var typing = false
    var delegate: NewMessageViewControllerDelegate?
    var tapGestureRecognizer: UITapGestureRecognizer!
    var parentNavigationController: UINavigationController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let recipient = self.recipient {
            self.txtTo.text = recipient.username
        }
        
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped))
        if self.showNearbyUsers {
            self.getNearbyUsers()
            //NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            //NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
            
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.setOriginY),
                                               name: NSNotification.Name.UIApplicationDidChangeStatusBarFrame,
                                               object: nil)

    }
    
    func keyboardNotification(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as?     NSValue)?.cgRectValue
            //let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            //let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            //let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions().rawValue
            //let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            //var originY: CGFloat!
            let y = endFrame?.origin.y ?? 0
            if  y >= UIScreen.main.bounds.size.height {
                self.keyboardOriginY = 0
            } else {
                self.keyboardOriginY = y
            }
            self.keyboardHeightChanged()
        }
    }
    
    func tapped(tap: UITapGestureRecognizer){
        let point = tap.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point) {
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.tableView.delegate?.tableView!(self.tableView, didSelectRowAt: indexPath)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.recipient == nil {
            self.txtTo.becomeFirstResponder()
        }
    }

    func setupView(frame: CGRect, navigationController: UINavigationController, inputViewHeight: CGFloat, keyboardController: JSQMessagesKeyboardController/*, parentContainerView: UIView*/){
        self.inputViewHeight = inputViewHeight
        self.parentFrame = frame
        self.keyboardController = keyboardController
        self.parentNavigationController = navigationController
        self.keyboardOriginY = self.parentFrame.size.height
        //self.parentContainerView = parentContainerView
        
        let top = CGFloat(navigationController.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.height)
        
        self.view.frame = CGRect(x: 0, y: top, width: self.parentFrame.width, height: self.inputContainerView.frame.height + 1)
        self.view.setNeedsLayout()
        
        self.txtTo.delegate = self
        
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: self.view.frame.height - 1, width: self.view.frame.width, height: 1)
        layer.backgroundColor = UIColor(white: 0.8, alpha: 1).cgColor
        self.view.layer.addSublayer(layer)
    }
    
    /*func keyboardWillHide(){
        self.keyboardHeight = 0
        self.keyboardHeightChanged()
    }*/
    
    /*func keyboardWillShow(notification: Notification){
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.keyboardHeight != keyboardSize.height {
                self.keyboardHeight = keyboardSize.height
                self.keyboardHeightChanged()
            }
        }
    }*/
    
    func keyboardHeightChanged(){
        if let timer = self.layoutTimer {
            timer.invalidate()
        }
        
        self.layoutTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.doLayout), userInfo: nil, repeats: false)
    }
    
    func doLayout(){
        if self.nearbyUsers.count > 0 {
            self.setOriginY()
            self.view.frame.size.height = self.keyboardOriginY - self.view.frame.origin.y - self.inputViewHeight - 1
            self.view.frame.size.width = self.parentFrame.size.width
            //self.parentFrame.height - self.view.frame.origin.y - self.keyboardHeight - self.inputViewHeight - 1
            self.view.layoutSubviews()
        }
    }
    
    func setOriginY (){
        let top = CGFloat(self.parentNavigationController.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.height)
        self.view.frame.origin.y = top
        //self.parentContainerView.frame.origin.y = 0
        print("\(top)")
    }
    
    func getNearbyUsers(){
        if let lastLocation = LocationHandler.lastLocation {
            if ConnectionHandler.Instance.isConnected() {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
                ConnectionHandler.Instance.users.getNearbyUsers(lat: Float(lastLocation.coordinate.latitude), lng: Float(lastLocation.coordinate.longitude), callback: { (success, errorId, errorMessage, users) in
                    if success {
                    ThreadHelper.runOnMainThread({
                        self.nearbyUsers = (users as! [User]).filter({$0.id != AccountHandler.Instance.userId})
                        if self.nearbyUsers.count > 0 {
                            //AccountHandler.Instance.allUsers
                        //self.view.frame.size.height = self.parentFrame.size.height - self.inputViewHeight - self.view.frame.origin.y - 1
                            //self.keyboardOriginY - self.view.frame.origin.y - self.inputViewHeight - 1
                            self.keyboardHeightChanged()
                            //users as! [User]
                            
                            self.tableView.reloadData()
                        }
                    })
                    }
                })
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(getNearbyUsers), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            }
        } else {
            let locationHandler = LocationHandler()
            locationHandler.delegate = self
            
            locationHandler.getLocationOnce(false)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.typing = true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.typing = false
        return true
    }
    
    func locationReported(_ geocoderInfo: GeocoderInfo) {
        self.getNearbyUsers()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.recipient = nil
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
        if self.recipient == nil {
            self.checkUser()
        }
    }
    
    func checkUser(){
        if let username = self.txtTo.text, username != "" {
            if ConnectionHandler.Instance.isNetworkConnected() {
                self.activityIndicator.startAnimating()
                ConnectionHandler.Instance.users.getUserByName(username, callback: { (success, errorId, error, result) in
                    ThreadHelper.runOnMainThread {
                        if success {
                            self.recipient = (result as! User)
                            //green
                            self.txtTo.textColor = UIColor().SHGreen
                        } else {
                            //red
                            self.txtTo.textColor = UIColor().SHRed
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
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = self.nearbyUsers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "nearbyUserCell") as! NearbyUserTableViewCell
        cell.setup(user)
        
        if let imageUrl = user.imageUrl {
            ImageCachingHandler.Instance.getImageFromUrl(imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                ThreadHelper.runOnMainThread {
                    if self.tableView.indexPathsForVisibleRows!.index(where: {$0.row == indexPath.row}) != nil{
                        //cell.imageView!.layer.cornerRadius = cell.imageView!.frame.height / 2
                        //cell.imageView!.layer.masksToBounds = true
                        cell.updateImage(image: image!)
                    }
                }
            })
        }

        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let timer = self.timer {
            timer.invalidate()
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let user = self.nearbyUsers[indexPath.row]
        self.txtTo.text = user.username
        self.recipient = user
        self.txtTo.textColor = UIColor.green
        
        self.delegate?.recipientSelected()
    }

    func hideTableView(){
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol NewMessageViewControllerDelegate{
    func recipientSelected()
}
