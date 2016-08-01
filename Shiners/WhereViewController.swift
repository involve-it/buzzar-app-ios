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
    var localLocations = [Location]()

    var currentLocationInfo: GeocoderInfo?
    
    private var dynamicLocationRequested = false
    
    @IBOutlet weak var createPostAddiotionalMenu: UIView!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    @IBOutlet weak var labeDetermineLocation: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.currentLocationInfo == nil {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(currentLocationReported), name: NotificationManager.Name.NewPostLocationReported.rawValue, object: nil)
        }
    
        self.labeDetermineLocation.text = "current location not yet defined"
    }

    @IBAction func btn_getDynamicLocation(sender: AnyObject) {
        if let _ = self.currentLocationInfo{
            self.setDynamicLocation()
        } else {
            self.dynamicLocationRequested = true
        }
    }
    
    func currentLocationReported(notification: NSNotification){
        let geocoderInfo = notification.object as! GeocoderInfo
        self.currentLocationInfo = geocoderInfo
        if self.dynamicLocationRequested {
            self.setDynamicLocation()
        }
    }
    
    //****************************************************************//
    
    @IBAction func createPost(sender: AnyObject) {
        if let post = self.post {
            
            post.title = self.post.title
            post.descr = self.post.descr
            post.timestamp = NSDate()
            post.photos = [Photo]()
            
            post.locations = [Location]()
            
            //Dynamic location
            if let dynamicLocationIndex = self.localLocations.indexOf({return $0.placeType == .Dynamic}) {
                post.locations?.append(self.localLocations[dynamicLocationIndex])
            }
            
            //Static location
            if let staticLocationIndex = self.localLocations.indexOf({return $0.placeType == .Static}) {
                post.locations?.append(self.localLocations[staticLocationIndex])
            }
            
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
                labeDetermineLocation.text = geocoderInfo.address
                //self.cellDynamicLocation?.accessoryType = UITableViewCellAccessoryType.Checkmark
                let location = Location()
                location.lat = geocoderInfo.coordinate?.latitude
                location.lng = geocoderInfo.coordinate?.longitude
                location.name = geocoderInfo.address
                location.placeType = .Dynamic
                
                if let index = localLocations.indexOf({return $0.placeType == .Dynamic}) {
                    localLocations.removeAtIndex(index)
                }
                
                self.localLocations.append(location)
                
                //Проверка на пустой массив locations
                localLocationsIsEmpty()
                
                //self.currentDynamicLocation = location
            }
        }
    }
    
    func locationSelected(location: CLLocationCoordinate2D?, address: String?) {
        let loc = Location()
        loc.name = address
        loc.placeType = .Static
        loc.lat = location?.latitude
        loc.lng = location?.longitude
        
        if let index = localLocations.indexOf({return $0.placeType == .Static}) {
            localLocations.removeAtIndex(index)
        }
        
        self.localLocations.append(loc)
        
        //Устанавлиаваем текстувую метку с адресом
        labeDetermineLocation.text = address
        
        //Проверка на пустой массив locations
        localLocationsIsEmpty()
        
        //print("\(localLocations)")
    }
    
    func localLocationsIsEmpty() {
        if !localLocations.isEmpty {
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
                
                var post = Post()
                
                //Передаю данные по цепочке с предыдущего view контроллера
                post = self.post
                
                //Добавляем в объект пост location
                post.locations = self.localLocations
                
                //Передаем объект post следующему контроллеру
                destination.post = post
                destination.currentLocationInfo = self.currentLocationInfo
            }
        } else if segue.identifier == "staticSegue" {
            if let destination = segue.destinationViewController as? StaticLocationViewController {
                destination.delegate = self
                if let index = localLocations.indexOf({return $0.placeType == .Static}) {
                    let selectedLocation = self.localLocations[index]
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
