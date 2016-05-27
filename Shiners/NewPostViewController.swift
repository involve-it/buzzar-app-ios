//
//  NewPostViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import CoreLocation

class NewPostViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, DescriptionViewControllerDelegate, LocationHandlerDelegate, StaticLocationViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SmallImageViewDelegate{
    var descriptionHtml: String = ""
    
    //private let createButton = UIBarButtonItem(title: "Create", style: .Plain, target: nil, action: #selector(btnCreate_Clicked));
    @IBOutlet var createButton: UIBarButtonItem!
    
    var post: Post?
    
    @IBOutlet weak var cellStaticLocation: UITableViewCell!
    @IBOutlet weak var cellDynamicLocation: UITableViewCell!
    
    @IBOutlet weak var svImages: UIScrollView!
    @IBOutlet weak var lblNoImages: UILabel!
    @IBOutlet weak var cellImages: UITableViewCell!
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtAdType: UITextField!
    
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblDescriptionPlaceholder: UILabel!
    
    @IBOutlet weak var txtWhen: UITextField!
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.view.endEditing(true)
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var whenPicker = UIPickerView(frame: CGRectZero)
    var adTypePicker = UIPickerView(frame: CGRectZero)
    
    var locationHandler = LocationHandler()
    
    private var currentStaticLocation: Location?
    private var currentDynamicLocation: Location?
    private var imagePickerHandler: ImagePickerHandler?
    private var images = [UIImage]()
    
    @IBOutlet weak var lblWhen: UILabel!
    @IBOutlet weak var lblAdType: UILabel!
    override func viewDidLoad() {
        self.whenPicker.delegate = self;
        self.whenPicker.dataSource = self;
        
        self.adTypePicker.delegate = self;
        self.adTypePicker.dataSource = self;
        
        self.txtWhen.inputView = self.whenPicker;
        self.txtWhen.inputAccessoryView = nil
        
        self.txtAdType.inputView = self.adTypePicker;
        self.txtAdType.inputAccessoryView = nil
        
        self.locationHandler.delegate = self;
        
        self.svImages.hidden = true;
        self.lblNoImages.hidden = false;
        
        self.imagePickerHandler = ImagePickerHandler(viewController: self, delegate: self)
        self.setLoading(false, rightBarButtonItem: self.createButton)
        
        if let _ = self.post {
            self.restorePost()
            self.createButton.title = "Save"
        } else {
            self.txtTitle.becomeFirstResponder()
            self.createButton.title = "Create"
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView === self.whenPicker){
            return ConstantValuesHandler.Instance.postDateRanges.count;
        } else if (pickerView === self.adTypePicker){
            return ConstantValuesHandler.Instance.adTypes.count;
        }
        
        return 0;
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === self.whenPicker{
            return Array(ConstantValuesHandler.Instance.postDateRanges.keys)[row]
        } else if pickerView === self.adTypePicker{
            return ConstantValuesHandler.Instance.adTypes[row]
        }
        
        return "";
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if pickerView === self.whenPicker || pickerView === self.adTypePicker{
            return 1;
        } else {
            return 0;
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerView === self.whenPicker){
            let text = Array(ConstantValuesHandler.Instance.postDateRanges.keys)[row]
            self.txtWhen.text = text
            self.lblWhen.text = text
        } else if pickerView === self.adTypePicker {
            self.lblAdType.text = ConstantValuesHandler.Instance.adTypes[row]
            self.txtAdType.text = ConstantValuesHandler.Instance.adTypes[row]
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //prevents crash on unwind from staticLocationSegue
        self.view.endEditing(true)
        if segue.identifier == "descriptionSegue"{
            let vc = segue.destinationViewController as! DescriptionViewController;
            vc.delegate = self;
            vc.html = self.descriptionHtml
        } else if segue.identifier == "staticLocationSegue" {
            let vc = segue.destinationViewController as! StaticLocationViewController
            vc.delegate = self;
            if let lat = self.currentStaticLocation?.lat, lng = self.currentStaticLocation?.lng {
                vc.currentCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
        }
    }
    
    func htmlUpdated(html: String?, text: String?) {
        self.lblDescription.text = text
        
        if let htmlString = html{
            self.descriptionHtml = htmlString
        } else {
            self.descriptionHtml = ""
        }
        
        if let _ = text where text != "" {
            self.lblDescriptionPlaceholder.hidden = true
            self.lblDescription.hidden = false
        } else {
            self.lblDescriptionPlaceholder.hidden = false
            self.lblDescription.hidden = true
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if (indexPath.section == 1 || indexPath.section == 3 || indexPath.section == 4 || (indexPath.section == 2)){
            return indexPath
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 2 {
            if self.txtAdType.isFirstResponder(){
                self.txtAdType.resignFirstResponder()
            } else {
                if self.txtAdType.text == "" {
                    self.txtAdType.text = ConstantValuesHandler.Instance.adTypes[0]
                    self.lblAdType.text = ConstantValuesHandler.Instance.adTypes[0]
                }
                self.txtAdType.becomeFirstResponder()
            }
        } else if indexPath.section == 4 {
            if (self.txtWhen.isFirstResponder()){
                self.txtWhen.resignFirstResponder()
            } else {
                if self.txtWhen.text == "" {
                    let text = Array(ConstantValuesHandler.Instance.postDateRanges.keys)[0]
                    self.txtWhen.text = text
                    self.lblWhen.text = text
                }
                self.txtWhen.becomeFirstResponder()
            }
        } else if indexPath.section == 3 {
            self.view.endEditing(true)
            if indexPath.row == 0 {
                self.currentDynamicLocation = nil
                let cell = self.tableView.cellForRowAtIndexPath(indexPath)
                if cell?.accessoryType == UITableViewCellAccessoryType.None {
                    self.detectLocation()
                    cell?.detailTextLabel?.text = "Attempting to get your location..."
                } else {
                    cell?.accessoryType = UITableViewCellAccessoryType.None
                    cell?.detailTextLabel?.text = "Moving with your ad"
                }
            }
        } else if indexPath.section == 2 && indexPath.row == 1 {
            //images
            self.view.endEditing(true)
            self.imagePickerHandler?.displayImagePicker()
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func detectLocation(){
        if !self.locationHandler.getLocationOnce() {
            if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 3)){
                cell.detailTextLabel!.text = "Please allow location services in settings"
            }
        }
    }
    
    //from manager
    func locationReported(geocoderInfo: GeocoderInfo) {
        NSLog("Location reported: \(geocoderInfo)")
        //let indexPath = NSIndexPath(forRow: 0, inSection: 3)
        //let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        if geocoderInfo.denied {
            self.cellDynamicLocation?.detailTextLabel?.text = "Please allow location services in settings"
        } else if geocoderInfo.error {
            self.cellDynamicLocation?.detailTextLabel?.text = "An error occurred getting your current location"
        } else {
            self.cellDynamicLocation?.detailTextLabel?.text = geocoderInfo.address
            self.cellDynamicLocation?.accessoryType = UITableViewCellAccessoryType.Checkmark
            let location = Location()
            location.lat = geocoderInfo.coordinate?.latitude
            location.lng = geocoderInfo.coordinate?.longitude
            location.name = geocoderInfo.address
            self.currentDynamicLocation = location
        }
    }
    
    //from map
    func locationSelected(location: CLLocationCoordinate2D?, address: String?) {
        if let addr = address {
            self.cellStaticLocation?.detailTextLabel?.text = addr
            self.cellStaticLocation?.accessoryType = .Checkmark
        } else {
            self.cellStaticLocation?.accessoryType = .DisclosureIndicator
            self.cellStaticLocation?.detailTextLabel?.text = "Pinned to static location"
        }
        let loc = Location()
        loc.lat = location?.latitude
        loc.lng = location?.longitude
        loc.name = address
        self.currentStaticLocation = loc
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.images.append(image)
        self.addImageToScrollView(image, index: self.images.count - 1)
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func addImageToScrollView(image: UIImage, index: Int){
        if (self.svImages.hidden){
            self.svImages.hidden = false
            self.lblNoImages.hidden = true
        }
        
        var x = self.calculateImagesWidth(index)
        let view = SmallImageView(x: x, y: 8, id: index, delegate: self, image: image)
        
        self.svImages.addSubview(view)
        
        x = self.calculateImagesWidth(index + 1)
        
        self.svImages.contentSize = CGSizeMake(CGFloat(x), self.svImages.frame.size.height);
        self.svImages.layoutSubviews()
    
    }
    
    func redrawImagesScrollView(){
        self.svImages.subviews.forEach({ (view) in
            view.removeFromSuperview()
        })
        
        var index = 0
        self.images.forEach { (image) in
            self.addImageToScrollView(image, index: index)
            index += 1
        }
    }
    
    func calculateImagesWidth(count: Int) -> Float {
        return (8 + Float(count) * Float(SmallImageView.width + 8))
        //return Float(self.svImages.frame.width) * Float(self.images.count)
    }
    
    func deleteClicked(view: SmallImageView) {
        self.images.removeAtIndex(view.id!)
        self.redrawImagesScrollView()
        if self.images.count == 0{
            self.svImages.hidden = true
            self.lblNoImages.hidden = false
        }
    }
    
    private func restorePost(){
        if let post = self.post{
            txtTitle.text = post.title
            if let descr = post.descr {
                descriptionHtml = descr
                lblDescription.text = descr
                
                lblDescription.hidden = false
                lblDescriptionPlaceholder.hidden = true
            }
            
            lblAdType.text = post.type
            if let locations = post.locations {
                for location in locations {
                    if location.placeType == .Dynamic {
                        self.cellDynamicLocation?.accessoryType = .Checkmark
                        self.cellDynamicLocation?.detailTextLabel?.text = location.name
                        self.currentDynamicLocation = location
                        self.detectLocation()
                    } else if location.placeType == .Static {
                        self.cellStaticLocation?.accessoryType = .Checkmark
                        self.cellStaticLocation?.detailTextLabel?.text = location.name
                        self.currentStaticLocation = location
                    }
                }
            }
        }
    }
    
    private func composePost() -> Post?{
        var post:Post = Post()
        if self.post != nil {
            post = self.post!
        }
        post.title = txtTitle.text
        post.descr = descriptionHtml
        post.type = lblAdType.text
        post.timestamp = NSDate()
        //todo
        //post.images
        post.locations = [Location]()
        if let dynamicLocation = self.currentDynamicLocation {
            post.locations?.append(dynamicLocation)
        }
        
        if let staticLocation = self.currentStaticLocation{
            post.locations?.append(staticLocation)
        }
        if let endDateText = self.txtWhen.text where self.txtWhen.text != ""{
            post.endDate = NSDate().dateByAddingTimeInterval(ConstantValuesHandler.Instance.postDateRanges[endDateText]!)
        } else {
            return nil
        }
        
        return post
    }
    
    func btnCreate_Clicked(sender: AnyObject) {
        if let post = self.composePost(){
            self.setLoading(true)
            let callback: MeteorMethodCallback = { (success, errorId, errorMessage, result) in
                self.setLoading(false, rightBarButtonItem: self.createButton)
                if success{
                    AccountHandler.Instance.updateMyPosts()
                    ThreadHelper.runOnMainThread({ 
                        self.view.endEditing(true)
                        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                    })
                } else {
                    self.showAlert("Error occurred", message: errorMessage)
                }
            }
            if let _ = self.post {
                ConnectionHandler.Instance.posts.editPost(post, callback:  callback)
            } else {
                ConnectionHandler.Instance.posts.addPost(post, callback: callback)
            }
        } else {
            self.showAlert("Error occurred", message: "Validation failed")
        }
    }
}