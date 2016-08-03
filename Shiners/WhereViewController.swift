//
//  WhereViewController.swift
//  wizard2
//
//  Created by Вячеслав on 7/6/16.
//  Copyright © 2016 mr.Douson. All rights reserved.
//

import UIKit
import CoreLocation

class WhereViewController: UIViewController, StaticLocationViewControllerDelegate {
    var post: Post!
    //var localLocations = [Location]()

    let labeDetermineLocationText = "current location not yet defined"
    var currentLocationInfo: GeocoderInfo?
    
    private var dynamicLocationRequested = false
    
    @IBOutlet weak var createPostAddiotionalMenu: UIView!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    @IBOutlet weak var labeDetermineLocation: UILabel!
    
    
    @IBOutlet weak var switcherDynamic: UISwitch!
    @IBOutlet weak var switcherStatic: UISwitch!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.currentLocationInfo == nil {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(currentLocationReported), name: NotificationManager.Name.NewPostLocationReported.rawValue, object: nil)
        }
    
        self.post.locations = [Location]()
        self.labeDetermineLocation.text = labeDetermineLocationText
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateUiElementsInLocation()
    }
    
    func currentLocationReported(notification: NSNotification){
        let geocoderInfo = notification.object as! GeocoderInfo
        self.currentLocationInfo = geocoderInfo
        if self.dynamicLocationRequested {
            self.setDynamicLocation()
        }
    }
    
    //Switcher
    @IBAction func switcher_getDynamicLocation(sender: UISwitch) {
        //event Value changed

        if sender.on {
            
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
                    self.showAlert("Error occurred", message: errorMessage)
                }
            }
            
            //Add post
            ConnectionHandler.Instance.posts.addPost(post, currentCoordinates: self.currentLocationInfo?.coordinate, callback: callback)
            
        }
    }
    
    
    
    //from manager
    func setDynamicLocation() {
        if let geocoderInfo = self.currentLocationInfo {
            NSLog("Location reported: \(geocoderInfo)")
            //let indexPath = NSIndexPath(forRow: 0, inSection: 3)
            //let cell = self.tableView.cellForRowAtIndexPath(indexPath)
            if geocoderInfo.denied {
                labeDetermineLocation.text = "Please allow location services in settings"
            } else if geocoderInfo.error {
                labeDetermineLocation.text = "An error occurred getting your current location"
            } else {
                
                if post.locations!.indexOf({return $0.placeType == .Static}) == nil {
                    labeDetermineLocation.text = geocoderInfo.address
                }
                
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
        var hasStaticLocation = false
        
        for location in self.post.locations! {
            labelLocation = location.name!
            if location.placeType == .Static {
                hasStaticLocation = true
                break
            }
            
        }

        labeDetermineLocation.text = labelLocation
        
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
