//
//  editMyPostTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 14/12/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import CoreLocation


class editMyPostTableViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate, SelectCategoryViewControllerDelegate, LocationHandlerDelegate {

    @IBOutlet weak var titleTextCount: UILabel!
    @IBOutlet weak var titleNewPost: UITextField!
    
    @IBOutlet weak var fieldDescriptionOfPost: UITextView!
    @IBOutlet weak var titleCountOfDescription: UILabel!
    
    @IBOutlet var btn_update: UIBarButtonItem!
    
    var post: Post!
    var originalPost: Post!
    
    fileprivate var currentLocationInfo: GeocoderInfo?
    fileprivate let locationHandler = LocationHandler()
    
    @IBOutlet var btnAddPhotos: UIButton!
    @IBOutlet var imgPhoto: UIImageView!
    @IBOutlet var cellExpiration: UITableViewCell!
    @IBOutlet var cellLocation: UITableViewCell!
    @IBOutlet var cellCategory: UITableViewCell!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.post = Post()
        self.post.updateFrom(post: self.originalPost)
        //Заполняем начальное значение при инициализации контроллера
        titleTextCount.text = String(titleAllowCount)
        // Устанавливаем начальное значение в метку счетчика разрешенного кол-во символов
        titleCountOfDescription.text = String(descriptionAllowCount)
        
        self.btnAddPhotos.layer.cornerRadius = 4
        
        txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
        self.imgPhoto.clipsToBounds = true
        self.locationHandler.delegate = self
        if !self.locationHandler.getLocationOnce(true){
            self.currentLocationInfo = GeocoderInfo()
            self.currentLocationInfo!.denied = true
        } else if let location = LocationHandler.lastLocation {
            self.currentLocationInfo = GeocoderInfo()
            self.currentLocationInfo!.coordinate = location.coordinate
        }
    }
    
    func locationReported(_ geocoderInfo: GeocoderInfo) {
        self.currentLocationInfo = geocoderInfo
        //print("New post location reported")
        NotificationManager.sendNotification(NotificationManager.Name.NewPostLocationReported, object: self.currentLocationInfo)
    }
    
    func refreshUI(){
        self.titleNewPost.text = self.post.title
        if let descr = self.post.descr {
            self.fieldDescriptionOfPost.text = descr
            fieldDescriptionOfPost.textColor = UIColor.black
        } else {
            //Placeholder
            fieldDescriptionOfPost.text = descriptionPlaceholderText
            fieldDescriptionOfPost.textColor = descriptionPlaceholderColor
        }
        if let imageUrl = self.post.getMainPhoto() {
            ImageCachingHandler.Instance.getImageFromUrl(imageUrl.original!, defaultImage: nil, callback: { (image) in
                ThreadHelper.runOnMainThread {
                    if image != nil {
                        self.imgPhoto.contentMode = .scaleAspectFill
                        self.imgPhoto.image = image
                    }
                }
            })
            self.btnAddPhotos.backgroundColor = UIColor(white: 1, alpha: 0.2)
            self.btnAddPhotos.setTitle(NSLocalizedString("Edit photos", comment: "Edit photos"), for: .normal)
        } else {
            self.imgPhoto.contentMode = .center
            self.imgPhoto.image = UIImage(named: "edit_no-photo")
            self.btnAddPhotos.setTitle(NSLocalizedString("Add photos", comment: "Add photos"), for: .normal)
            self.btnAddPhotos.backgroundColor = nil
        }
        if let category = self.post.type {
            self.cellCategory.detailTextLabel!.text = category.rawValue
        } else {
            self.cellCategory.detailTextLabel!.text = ""
        }
        if let expirationDate = self.post.endDate {
            self.cellExpiration.detailTextLabel!.text = expirationDate.toFriendlyLongDateTimeString()
        } else {
            self.cellExpiration.detailTextLabel!.text = ""
        }
        
        if let postCoordinateLocation = post.locations {
            let geoCoder = CLGeocoder()
            
            var postLocation:Location?
            
            for coordinateLocation in postCoordinateLocation {
                if coordinateLocation.placeType! == .Dynamic {
                    postLocation = coordinateLocation
                    
                    break
                } else {
                    postLocation = coordinateLocation
                }
            }
            
            if let postLoc = postLocation, let lat = postLoc.lat, let lng = postLoc.lng {
                let location = CLLocation(latitude: lat, longitude: lng)
                if let name = postLoc.name {
                    self.cellLocation.detailTextLabel!.text = name
                }
                geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                    if error != nil {
                        print("Reverse geocoder failed with error" + error!.localizedDescription)
                        return
                    }
                    
                    if let placemarks = placemarks {
                        let placemark = placemarks[0]
                        
                        ThreadHelper.runOnMainThread({
                            if placemark.formatAddress() != "" {
                                self.cellLocation.detailTextLabel!.text = placemark.formatAddress()
                            } else {
                                self.cellLocation.detailTextLabel!.text = NSLocalizedString("Address is not defined", comment: "Location, Address is not defined")
                            }
                        })
                    }
                })
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshUI()
        AppAnalytics.logScreen(.EditPost)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.post.title = self.titleNewPost.text
        self.post.descr = self.fieldDescriptionOfPost.text
        self.view.endEditing(true)
    }

    @IBAction func titleFieldChanged(_ sender: UITextField) {
        let currentCountTitleTextField:Int = (titleNewPost.text?.characters.count)!
        titleTextCount.text = String( Int(titleAllowCount)! - currentCountTitleTextField )
        
        if let title = sender.text, title != "" {
            btn_update.isEnabled = true
        } else {
            btn_update.isEnabled = false
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        //Изменение titleCountOfDescription в зависимости от лимита
        let currentCountFieldDescriptionOfPost: Int = fieldDescriptionOfPost.text.characters.count
        titleCountOfDescription.text =  String(Int(descriptionAllowCount)! - currentCountFieldDescriptionOfPost)
    }
    
    //Textfield limit characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if range.length + range.location > titleNewPost.text!.characters.count {
            return false
        } else {
            let newlength = titleNewPost.text!.characters.count + string.characters.count - range.length
            return newlength <= Int(titleAllowCount)!
        }
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentText: NSString = fieldDescriptionOfPost.text as NSString
        let updateText = currentText.replacingCharacters(in: range, with: text)
        
        if updateText.isEmpty || range.length + range.location > fieldDescriptionOfPost.text.characters.count{
            fieldDescriptionOfPost.text = descriptionPlaceholderText
            fieldDescriptionOfPost.textColor = descriptionPlaceholderColor
            
            txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
            return false
            
        } else if (fieldDescriptionOfPost.textColor == descriptionPlaceholderColor && !text.isEmpty)  {
            fieldDescriptionOfPost.text = nil
            fieldDescriptionOfPost.textColor = UIColor.black
        } else {
            let newlength = fieldDescriptionOfPost.text.characters.count + text.characters.count - range.length
            return newlength <= Int(descriptionAllowCount)!
        }
        
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if fieldDescriptionOfPost.textColor == descriptionPlaceholderColor {
                txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
            }
        }
    }
    
    func txtPlaceholderSelectedTextRange(_ placeholder: UITextView) -> () {
        placeholder.selectedTextRange = placeholder.textRange(from: placeholder.beginningOfDocument, to: placeholder.beginningOfDocument)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "expiration"{
            let viewController = segue.destination as! WhenPickDateViewController
            viewController.post = self.post
            viewController.editingPost = true
        } else if segue.identifier == "location" {
            let viewController = segue.destination as! WhereViewController
            viewController.post = self.post
            viewController.editingPost = true
            viewController.currentLocationInfo = self.currentLocationInfo
        } else if segue.identifier == "photos" {
            let viewController = segue.destination as! PhotosViewController
            viewController.post = self.post
            viewController.editingPost = true
        } else if segue.identifier == "category"{
            let navController = segue.destination as! UINavigationController
            let selectCategoryViewController = navController.viewControllers[0] as! SelectCategoryTableViewController
            selectCategoryViewController.currentCategory = post.type?.rawValue
            selectCategoryViewController.selectCategoryDelegate = self
        }
    }
  
    func categorySelected(_ category: String?, value: String) {
        if let cat = category {
            self.post.type = Post.AdType(rawValue: cat)
        } else {
            self.post.type = nil
        }
        //self.cellCategory.detailTextLabel!.text = value
    }
    
    @IBAction func btnSave_Click(_ sender: Any) {
        if self.isNetworkReachable() {
            self.doSave()
        }
    }
    
    func doSave(){
        self.setLoading(true)
        if ConnectionHandler.Instance.isConnected() {
            self.post.title = self.titleNewPost.text
            self.post.descr = self.fieldDescriptionOfPost.text
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            ConnectionHandler.Instance.posts.editPost(self.post, callback: { (success, errorId, error, result) in
                ThreadHelper.runOnMainThread {
                    if success {
                        self.originalPost.updateFrom(post: self.post)
                        //NotificationManager.sendNotification(.NearbyPostModified, object: self.post)
                        NotificationManager.sendNotification(.MyPostUpdated, object: self.post)
                        self.setLoading(false)
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    } else {
                        self.setLoading(false, rightBarButtonItem: self.btn_update)
                    }
                }
            })
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(doSave), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }

    @IBAction func btnCancel_Click(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
