//
//  NewPostViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import CoreLocation

class NewPostViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, DescriptionViewControllerDelegate, LocationHandlerDelegate, StaticLocationViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SmallImageViewDelegate, ValuePickerViewControllerDelegate{
    var descriptionHtml: String = ""
    
    @IBOutlet weak var createButton: UIBarButtonItem!
    
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
    
    //For sale
    @IBOutlet weak var lblCurrency: UILabel!
    @IBOutlet weak var txtCurrency: UITextField!
    var currencyPicker = UIPickerView(frame: CGRectZero)
    @IBOutlet weak var txtPrice: UITextField!
    
    //Connections
    var connectionsPicker = UIPickerView(frame: CGRectZero)
    @IBOutlet weak var txtConnection: UITextField!
    @IBOutlet weak var lblConnection: UILabel!
    
    //Training
    var trainingPicker = UIPickerView(frame: CGRectZero)
    @IBOutlet weak var txtTraining: UITextField!
    @IBOutlet weak var lblTraining: UILabel!
    var trainingCategoryPicker = UIPickerView(frame: CGRectZero)
    @IBOutlet weak var txtTrainingCategory: UITextField!
    @IBOutlet weak var lblTrainingCategory: UILabel!
    
    //Housing
    var housingPicker = UIPickerView(frame:CGRectZero)
    @IBOutlet weak var lblHousing: UILabel!
    @IBOutlet weak var txtHousing: UITextField!
    
    //Local Events
    var localEventsPicker = UIPickerView(frame: CGRectZero)
    @IBOutlet weak var txtLocalEvent: UITextField!
    @IBOutlet weak var lblLocalEvent: UILabel!
    
    //Help
    @IBOutlet weak var lblHelp: UILabel!
    
    var whenPicker = UIPickerView(frame: CGRectZero)
    var adTypePicker = UIPickerView(frame: CGRectZero)
    
    var locationHandler = LocationHandler()
    
    private var currentStaticLocation: Location?
    private var currentDynamicLocation: Location?
    private var imagePickerHandler: ImagePickerHandler?
    private var images = [UIImage]()
    
    @IBOutlet weak var lblWhen: UILabel!
    @IBOutlet weak var lblAdType: UILabel!
    
    private var adType: Post.AdType?
    
    override func viewDidLoad() {
        self.whenPicker.delegate = self;
        self.whenPicker.dataSource = self;
        
        self.adTypePicker.delegate = self;
        self.adTypePicker.dataSource = self;
        
        self.currencyPicker.delegate = self
        self.currencyPicker.dataSource = self
        
        self.connectionsPicker.delegate = self
        self.connectionsPicker.dataSource = self
        
        self.trainingPicker.delegate = self
        self.trainingPicker.dataSource = self
        
        self.trainingCategoryPicker.delegate = self
        self.trainingCategoryPicker.dataSource = self
        
        self.housingPicker.delegate = self
        self.housingPicker.dataSource = self
        
        self.localEventsPicker.delegate = self
        self.localEventsPicker.dataSource = self
        
        self.txtWhen.inputView = self.whenPicker;
        self.txtWhen.inputAccessoryView = nil
        
        self.txtAdType.inputView = self.adTypePicker;
        self.txtAdType.inputAccessoryView = nil
        
        self.txtCurrency.inputView = self.currencyPicker
        self.txtCurrency.inputAccessoryView = nil
        
        self.txtConnection.inputView = self.connectionsPicker
        self.txtConnection.inputAccessoryView = nil
        
        self.txtTraining.inputView = self.trainingPicker
        self.txtTraining.inputAccessoryView = nil
        
        self.txtTrainingCategory.inputView = self.trainingCategoryPicker
        self.txtTrainingCategory.inputAccessoryView = nil
        
        self.txtHousing.inputView = self.housingPicker
        self.txtHousing.inputAccessoryView = nil
        
        self.txtLocalEvent.inputView = self.localEventsPicker
        self.txtLocalEvent.inputAccessoryView = nil
        
        self.locationHandler.delegate = self;
        
        self.svImages.hidden = true;
        self.lblNoImages.hidden = false;
        
        self.imagePickerHandler = ImagePickerHandler(viewController: self, delegate: self)
        self.setLoading(false, rightBarButtonItem: self.createButton)
        
        if let _ = self.post {
            self.restorePost()
            self.createButton.title = NSLocalizedString("Save", comment: "Title, Save")
        } else {
            self.createButton.title = NSLocalizedString("Create", comment: "Title, Create")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if self.post == nil {
            self.txtTitle.becomeFirstResponder()
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView === self.whenPicker){
            return ConstantValuesHandler.Instance.postDateRanges.count;
        } else if (pickerView === self.adTypePicker){
            return ConstantValuesHandler.Instance.adTypes.count
        } else if (pickerView === self.currencyPicker){
            return ConstantValuesHandler.Instance.currencies.count
        } else if pickerView === self.connectionsPicker {
            return ConstantValuesHandler.Instance.connectionTypes.count
        } else if pickerView === self.trainingPicker {
            return ConstantValuesHandler.Instance.trainingTypes.count
        } else if pickerView === self.housingPicker {
            return ConstantValuesHandler.Instance.housingTypes.count
        } else if pickerView === self.localEventsPicker{
            return ConstantValuesHandler.Instance.localEventTypes.count
        } else if pickerView === self.trainingCategoryPicker {
            return ConstantValuesHandler.Instance.trainingCategoryTypes.count
        }
        
        return 0;
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === self.whenPicker{
            return Array(ConstantValuesHandler.Instance.postDateRanges.keys)[row]
        } else if pickerView === self.adTypePicker{
            return Array(ConstantValuesHandler.Instance.adTypes.values)[row]
        } else if pickerView === self.currencyPicker {
            return ConstantValuesHandler.Instance.currencies[row]
        } else if pickerView === self.connectionsPicker {
            return Array(ConstantValuesHandler.Instance.connectionTypes.values)[row]
        } else if pickerView === self.trainingPicker {
            return Array(ConstantValuesHandler.Instance.trainingTypes.values)[row]
        } else if pickerView === self.housingPicker {
            return Array(ConstantValuesHandler.Instance.housingTypes.values)[row]
        } else if pickerView === self.localEventsPicker {
            return Array(ConstantValuesHandler.Instance.localEventTypes.values)[row]
        } else if pickerView === self.trainingCategoryPicker {
            return Array(ConstantValuesHandler.Instance.trainingCategoryTypes.values)[row]
        }
        
        return "";
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if pickerView === self.whenPicker || pickerView === self.adTypePicker || pickerView === self.currencyPicker || pickerView === self.connectionsPicker || pickerView === self.trainingPicker || pickerView === self.housingPicker || pickerView === self.localEventsPicker || pickerView == self.trainingCategoryPicker {
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
            let text = Array(ConstantValuesHandler.Instance.adTypes.values)[row]
            self.lblAdType.text = text
            self.txtAdType.text = text
            self.adType = Post.AdType(rawValue: Array(ConstantValuesHandler.Instance.adTypes.keys)[row])
            self.refreshAdTypeDependencies()
        } else if pickerView === self.currencyPicker {
            self.lblCurrency.text = ConstantValuesHandler.Instance.currencies[row] + " >"
            self.txtCurrency.text = ConstantValuesHandler.Instance.currencies[row]
        } else if pickerView === self.connectionsPicker {
            let text = Array(ConstantValuesHandler.Instance.connectionTypes.values)[row]
            self.lblConnection.text = text
            self.txtConnection.text = text
        } else if pickerView === self.trainingPicker {
            let text = Array(ConstantValuesHandler.Instance.trainingTypes.values)[row]
            self.lblTraining.text = text
            self.txtTraining.text = text
        } else if pickerView === self.housingPicker {
            let text = Array(ConstantValuesHandler.Instance.housingTypes.values)[row]
            self.lblHousing.text = text
            self.txtHousing.text = text
        } else if pickerView === self.localEventsPicker {
            let text = Array(ConstantValuesHandler.Instance.localEventTypes.values)[row]
            self.lblLocalEvent.text = text
            self.txtLocalEvent.text = text
        } else if pickerView === self.trainingCategoryPicker {
            let text = Array(ConstantValuesHandler.Instance.trainingCategoryTypes.values)[row]
            self.lblTrainingCategory.text = text
            self.txtTrainingCategory.text = text
        }
    }
    
    private func refreshAdTypeDependencies(){
        let indexSet = NSMutableIndexSet()
        Section.ContextRelated.forEach({indexSet.addIndex($0)})
        self.tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
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
        } else if segue.identifier == "helpSelectionSegue" {
            let vc = (segue.destinationViewController as? UINavigationController)?.viewControllers.first as! ValuePickerViewController
            vc.delegate = self
            vc.multipleSelection = true
            vc.items = ConstantValuesHandler.Instance.helpTypes
            if let selected = self.lblHelp.text where self.lblHelp.text != " " && self.lblHelp.text != "" {
                let split = selected.componentsSeparatedByString(", ").map({
                    Array(ConstantValuesHandler.Instance.helpTypes.keys)[Array(ConstantValuesHandler.Instance.helpTypes.values).indexOf(String($0))!]
                })
                vc.selectedItems = split
            }
        }
    }
    
    func valuePickerController(valuePickerController: ValuePickerViewController, withId: String?, selectionReturned: [String]) {
        if selectionReturned.count > 0 {
            let items = selectionReturned.map({
                Array(ConstantValuesHandler.Instance.helpTypes.values)[Array(ConstantValuesHandler.Instance.helpTypes.keys).indexOf(String($0))!]
            })
            self.lblHelp.text = items.joinWithSeparator(", ")
        } else {
            self.lblHelp.text = " "
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
        if indexPath.section != Section.Url {
            return indexPath
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == Section.What && indexPath.row == 2 {
            self.toggleFirstResponder(self.txtAdType, label: self.lblAdType, pickerView: self.adTypePicker)
        } else if indexPath.section == Section.When {
            self.toggleFirstResponder(self.txtWhen, label: self.lblWhen, pickerView: self.whenPicker)
        } else if indexPath.section == Section.Location {
            self.view.endEditing(true)
            if indexPath.row == 0 {
                self.currentDynamicLocation = nil
                let cell = self.tableView.cellForRowAtIndexPath(indexPath)
                if cell?.accessoryType == UITableViewCellAccessoryType.None {
                    self.detectLocation()
                    cell?.detailTextLabel?.text = NSLocalizedString("Attempting to get your location...", comment: "Text, Attempting to get your location...")
                } else {
                    cell?.accessoryType = UITableViewCellAccessoryType.None
                    cell?.detailTextLabel?.text = NSLocalizedString("Moving with your ad", comment: "Text, Moving with your ad")
                }
            }
        } else if indexPath.section == Section.Photos && indexPath.row == 1 {
            self.view.endEditing(true)
            self.imagePickerHandler?.displayImagePicker()
        } else if indexPath.section == Section.ForSale {
            self.toggleFirstResponder(self.txtCurrency, label: self.lblCurrency, pickerView: self.currencyPicker)
        } else if indexPath.section == Section.Connections {
            self.toggleFirstResponder(self.txtConnection, label: self.lblConnection, pickerView: self.connectionsPicker)
        } else if indexPath.section == Section.Training {
            if indexPath.row == 0 {
                self.toggleFirstResponder(self.txtTraining, label: self.lblTraining, pickerView: self.trainingPicker)
            } else if indexPath.row == 1 {
                self.toggleFirstResponder(self.txtTrainingCategory, label: self.lblTrainingCategory, pickerView: self.trainingCategoryPicker)
            }
        } else if indexPath.section == Section.Housing {
            self.toggleFirstResponder(self.txtHousing, label: self.lblHousing, pickerView: self.housingPicker)
        } else if indexPath.section == Section.LocalEvent {
            self.toggleFirstResponder(self.txtLocalEvent, label: self.lblLocalEvent, pickerView: self.localEventsPicker)
        }

        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    private func toggleFirstResponder(textField: UITextField, label: UILabel, pickerView: UIPickerView){
        if textField.isFirstResponder(){
            textField.resignFirstResponder()
        } else {
            if textField.text == "" {
                //pickerView.selectRow(0, inComponent: 0, animated: true)
                pickerView.delegate?.pickerView?(pickerView, didSelectRow: 0, inComponent: 0)
            }
            textField.becomeFirstResponder()
        }
    }
    
    func detectLocation(){
        if !self.locationHandler.getLocationOnce(true) {
            if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: Section.Location)){
                cell.detailTextLabel!.text = NSLocalizedString("Please allow location services in settings", comment: "Text, Please allow location services in settings")
            }
        }
    }
    
    //from manager
    func locationReported(geocoderInfo: GeocoderInfo) {
        NSLog("Location reported: \(geocoderInfo)")
        //let indexPath = NSIndexPath(forRow: 0, inSection: 3)
        //let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        if geocoderInfo.denied {
            self.cellDynamicLocation?.detailTextLabel?.text = NSLocalizedString("Please allow location services in settings", comment: "Text, Please allow location services in settings")
        } else if geocoderInfo.error {
            self.cellDynamicLocation?.detailTextLabel?.text = NSLocalizedString("An error occurred getting your current location", comment: "Text, An error occurred getting your current location")
        } else {
            self.cellDynamicLocation?.detailTextLabel?.text = geocoderInfo.address
            self.cellDynamicLocation?.accessoryType = UITableViewCellAccessoryType.Checkmark
            let location = Location()
            location.lat = geocoderInfo.coordinate?.latitude
            location.lng = geocoderInfo.coordinate?.longitude
            location.name = geocoderInfo.address
            location.placeType = .Dynamic
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
            self.cellStaticLocation?.detailTextLabel?.text = NSLocalizedString("Pinned to static location", comment: "Text, Pinned to static location")
        }
        let loc = Location()
        loc.lat = location?.latitude
        loc.lng = location?.longitude
        loc.name = address
        loc.placeType = .Static
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
            self.adType = post.type
            let typeIndex = ConstantValuesHandler.Instance.adTypes.keys.indexOf(post.type!.rawValue)
            let adType = ConstantValuesHandler.Instance.adTypes.values[typeIndex!]
            lblAdType.text = adType
            self.txtPrice.text = post.price
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
            if let endDate = post.endDate {
                lblWhen.text = endDate.toShortDateString()
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
        post.type = self.adType
        post.timestamp = NSDate()
        //todo
        //post.images
        post.photos = [Photo]()
        
        post.locations = [Location]()
        if let dynamicLocation = self.currentDynamicLocation {
            post.locations?.append(dynamicLocation)
        }
        if let staticLocation = self.currentStaticLocation{
            post.locations?.append(staticLocation)
        }
        if let endDateText = self.txtWhen.text where self.txtWhen.text != ""{
            post.endDate = NSDate().dateByAddingTimeInterval(ConstantValuesHandler.Instance.postDateRanges[endDateText]!)
        } else if self.post?.endDate != nil {
            //nothing
        } else {
            return nil
        }
        if let adType = self.adType {
            switch adType {
            case .Trade:
                post.price = self.txtPrice.text
            case .Trainings:
                post.trainingCategory = self.txtTrainingCategory.text
                post.sectionLearning = self.txtTraining.text
            default:
                break
            }
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
                    self.showAlert(NSLocalizedString("Error occurred", comment: "Alert title, Error occurred"), message: errorMessage)
                }
            }
            if let _ = self.post {
                ConnectionHandler.Instance.posts.editPost(post, callback:  callback)
            } else {
                ConnectionHandler.Instance.posts.addPost(post, currentCoordinates: nil, callback: callback)
            }
        } else {
            self.showAlert(NSLocalizedString("Error occurred", comment: "Alert title, Error occurred"), message: NSLocalizedString("Validation failed", comment: "Alert message, Validation failed"))
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if self.isSectionVisible(section){
            return super.tableView(tableView, heightForFooterInSection: section)
        } else {
            return 0.1
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.isSectionVisible(section){
            return super.tableView(tableView, heightForHeaderInSection: section)
        } else {
            return 0.1
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isSectionVisible(section){
            return super.tableView(tableView, numberOfRowsInSection: section)
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.isSectionVisible(section){
            return super.tableView(tableView, viewForHeaderInSection: section)
        } else {
            return nil
        }
    }
    
    private func isSectionVisible(section: Int) -> Bool {
        if Section.ContextRelated.contains(section){
            if self.adType == .Trade && section == Section.ForSale
                || self.adType == .Connect && section == Section.Connections
                || self.adType == .Trainings && section == Section.Training
                || self.adType == .Housing && section == Section.Housing
                || self.adType == .Events && section == Section.LocalEvent
                || self.adType == .Services && section == Section.LocalEvent
                || self.adType == .Help && section == Section.Help
            {
                return true
            }
            
            return false
        }
        
        return true
    }
    
    private struct Section {
        static let Url = 0
        static let What = 1
        
        static let ForSale = 2
        static let Connections = 3
        static let Training = 4
        static let Housing = 5
        static let LocalEvent = 6
        static let Help = 7
        
        static let Photos = 8
        static let Location = 9
        static let When = 10
        
        static let ContextRelated = [ForSale, Connections, Training, Housing, LocalEvent, Help]
    }
}