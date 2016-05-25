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
    
    private var currentStaticLocation: CLLocationCoordinate2D?
    private var currentDynamicLocation: CLLocationCoordinate2D?
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
    }
    
    override func viewDidAppear(animated: Bool) {
        self.txtTitle.becomeFirstResponder()
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
            return ConstantValuesHandler.Instance.postDateRanges[row]
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
            self.txtWhen.text = ConstantValuesHandler.Instance.postDateRanges[row]
            self.lblWhen.text = ConstantValuesHandler.Instance.postDateRanges[row]
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
            vc.currentCoordinate = self.currentStaticLocation
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
                    self.txtWhen.text = ConstantValuesHandler.Instance.postDateRanges[0]
                    self.lblWhen.text = ConstantValuesHandler.Instance.postDateRanges[0]
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
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 3))
        if geocoderInfo.denied {
            cell?.detailTextLabel?.text = "Please allow location services in settings"
        } else if geocoderInfo.error {
            cell?.detailTextLabel?.text = "An error occurred getting your current location"
        } else {
            cell?.detailTextLabel?.text = geocoderInfo.address
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
            self.currentDynamicLocation = geocoderInfo.coordinate
        }
    }
    
    //from map
    func locationSelected(location: CLLocationCoordinate2D?, address: String?) {
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 3))
        if let addr = address {
            cell?.detailTextLabel?.text = addr
            cell?.accessoryType = .Checkmark
        } else {
            cell?.accessoryType = .DisclosureIndicator
            cell?.detailTextLabel?.text = "Pinned to static location"
        }
        self.currentStaticLocation = location
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
    
    private func composePost() -> Post{
        let post = Post()
        post.title = txtTitle.text
        post.descr = descriptionHtml
        post.type = lblAdType.text
        //todo
        //post.images
        
        
        return post
    }
    
    @IBAction func btnCreate_Clicked(sender: AnyObject) {
        
    }
    
}