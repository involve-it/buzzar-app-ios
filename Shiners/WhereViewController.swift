//
//  WhereViewController.swift
//  wizard2
//
//  Created by Вячеслав on 7/6/16.
//  Copyright © 2016 mr.Douson. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class WhereViewController: UIViewController, StaticLocationViewControllerDelegate, MKMapViewDelegate {
    
    var post: Post!
    var annotations = [MKPointAnnotation]()
    
    //var localLocations = [Location]()

    let labeDetermineLocationText = NSLocalizedString("Acquiring location...", comment: "Location, Acquiring location...")
    var currentLocationInfo: GeocoderInfo?
    
    private var dynamicLocationRequested = false
    
    @IBOutlet weak var createPostAddiotionalMenu: UIView!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    @IBOutlet weak var labeDetermineLocation: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var textFieldLocation: UITextField!
    
    @IBOutlet weak var switcherDynamic: UISwitch!
    @IBOutlet weak var switcherStatic: UISwitch!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftPaddingToTextField([textFieldLocation])
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(currentLocationReported), name: NotificationManager.Name.NewPostLocationReported.rawValue, object: nil)
        
        self.post.locations = [Location]()
        self.labeDetermineLocation.text = labeDetermineLocationText
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateUiElementsInLocation()
    }
    
    func currentLocationReported(notification: NSNotification){
        let geocoderInfo = notification.object as! GeocoderInfo
        NSLog("Location reported: \(geocoderInfo)")
        self.currentLocationInfo = geocoderInfo
        if self.dynamicLocationRequested {
            self.setDynamicLocation()
        } else {
            self.updateUiElementsInLocation()
        }
    }
    
    func leftPaddingToTextField(array: [UITextField]) {
        
        for textField in array {
            let paddingView = UIView(frame: CGRectMake(0, 0, 15, textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.Always
        }
        
    }
    
    //Switcher
    @IBAction func switcher_getDynamicLocation(sender: UISwitch) {
        //event Value changed

        if sender.on {
            self.labeDetermineLocation.text = self.labeDetermineLocationText
            if let _ = self.currentLocationInfo{
                self.setDynamicLocation()
            } else {
                self.dynamicLocationRequested = true
            }
        } else {
            
            if let index = self.post.locations!.indexOf({return $0.placeType == .Dynamic}) {
                self.post.locations!.removeAtIndex(index)
            }
            
            updateUiElementsInLocation()
        }
    }
    
    
    @IBAction func switcher_getStaticLocation(sender: UISwitch) {
        //event Touch Up Inside
        if sender.on {
            
            //Go to staticSegue
            self.performSegueWithIdentifier("staticSegue", sender: self)
            
        } else {
            if let index = self.post.locations!.indexOf({return $0.placeType == .Static}) {
                self.post.locations!.removeAtIndex(index)
                /*
                self.labeDetermineLocation.text = self.labeDetermineLocationText
                */
            }
            
            updateUiElementsInLocation()
        }
        
    }
    
    
    //****************************************************************//
    
    @IBAction func createPost(sender: AnyObject) {
        if let post = self.post {
            
            //print("\(post)")
            
            let callback: MeteorMethodCallback = { (success, errorId, errorMessage, result) in
                if success{
                    AccountHandler.Instance.updateMyPosts()
                    ThreadHelper.runOnMainThread({
                        self.view.endEditing(true)
                        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                    })
                } else {
                    ThreadHelper.runOnMainThread({ 
                        self.showAlert("Error occurred", message: errorMessage)
                    })
                }
            }
            
            //Add post
            ConnectionHandler.Instance.posts.addPost(post, currentCoordinates: self.currentLocationInfo?.coordinate, callback: callback)
        }
    }
    
    //from manager
    func setDynamicLocation() {
        if let geocoderInfo = self.currentLocationInfo {
            //let indexPath = NSIndexPath(forRow: 0, inSection: 3)
            //let cell = self.tableView.cellForRowAtIndexPath(indexPath)
            if geocoderInfo.denied {
                ThreadHelper.runOnMainThread({ 
                    self.labeDetermineLocation.text = NSLocalizedString("Please allow location services in settings", comment: "Please allow location services in settings")
                })
            } else if geocoderInfo.error {
                ThreadHelper.runOnMainThread({ 
                    self.labeDetermineLocation.text = NSLocalizedString("An error occurred getting your current location", comment: "Error getting current location")
                })
            } else {
                
                /*if post.locations!.indexOf({return $0.placeType == .Static}) == nil {
                    labeDetermineLocation.text = geocoderInfo.address ?? "Acquiring address..."
                }*/
                
                //self.cellDynamicLocation?.accessoryType = UITableViewCellAccessoryType.Checkmark
                let location = Location()
                
                location.lat = geocoderInfo.coordinate?.latitude
                location.lng = geocoderInfo.coordinate?.longitude
                location.name = geocoderInfo.address
                location.placeType = .Dynamic
                
                if let index = post.locations!.indexOf({return $0.placeType == .Dynamic}) {
                    post.locations!.removeAtIndex(index)
                }
                
                self.post.locations!.append(location)
                
                //self.currentDynamicLocation = location
            }
        }
        
        updateUiElementsInLocation()
    }
    
    func locationSelected(location: CLLocationCoordinate2D?, address: String?) {
        if let index = post.locations!.indexOf({return $0.placeType == .Static}) {
            post.locations!.removeAtIndex(index)
        }
        
        if let locLocation = location {
            let loc = Location()
            loc.name = address
            loc.placeType = .Static
            loc.lat = locLocation.latitude
            loc.lng = locLocation.longitude
            
            self.post.locations!.append(loc)
        }
        
        updateUiElementsInLocation()
    }
    
    
    func updateUiElementsInLocation() {
        var labelLocation = self.labeDetermineLocationText
        if let currentLocationInfo = self.currentLocationInfo, let address = currentLocationInfo.address{
            labelLocation = address
        }
        var hasStaticLocation = false
        
        for location in self.post.locations! {
            
           
            showAnnotationOnMap()
            
            if let locationName = location.name {
                labelLocation = locationName
                
            }
            if location.placeType == .Static {
                hasStaticLocation = true
                break
            }
        }

        ThreadHelper.runOnMainThread { 
            self.labeDetermineLocation.text = labelLocation
            
            if !hasStaticLocation {
                self.switcherStatic.on = false
            }
            
            if self.post.locations?.count > 0 {
                self.btn_next.enabled = true
                self.createPostAddiotionalMenu.hidden = false
            } else {
                self.btn_next.enabled = false
                self.createPostAddiotionalMenu.hidden = true
            }
        }
    }
    
    func showAnnotationOnMap() {
  
        if !self.annotations.isEmpty {
            self.mapView.addAnnotations(self.annotations)
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueDatePicker" {
            if let destination = segue.destinationViewController as? WhenPickDateViewController {
                
                //Передаем объект post следующему контроллеру
                destination.post = post
                destination.currentLocationInfo = self.currentLocationInfo
            }
        } else if segue.identifier == "staticSegue" {
            if let destination = segue.destinationViewController as? StaticLocationViewController {
                destination.delegate = self
                if let index = post.locations!.indexOf({return $0.placeType == .Static}) {
                    let selectedLocation = self.post.locations![index]
                    destination.currentCoordinate = CLLocationCoordinate2D(latitude: selectedLocation.lat!, longitude: selectedLocation.lng!)
                }
            }
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
