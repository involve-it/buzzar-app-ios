//
//  WhereViewController.swift
//  wizard2
//
//  Created by Вячеслав on 7/6/16.
//  Copyright © 2016 mr.Douson. All rights reserved.
//

import UIKit
import CoreLocation

class WhereViewController: UIViewController, LocationHandlerDelegate, StaticLocationViewControllerDelegate {

    var locationHandler = LocationHandler()
    var post: Post!
    var localLocations = [Location]()

    
    @IBOutlet weak var createPostAddiotionalMenu: UIView!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    @IBOutlet weak var labeDetermineLocation: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.locationHandler.delegate = self;
    
        self.labeDetermineLocation.text = "current location not yet defined"
                
        
    }

    @IBAction func btn_getDynamicLocation(sender: AnyObject) {
        if !self.locationHandler.getLocationOnce(true) {
            self.showAlert("Error", message: "Доступ запрещен")
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
            ConnectionHandler.Instance.posts.addPost(post, callback: callback)
            
        }
    }
    
    
    
    //from manager
    func locationReported(geocoderInfo: GeocoderInfo) {
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
    
    func locationSelected(location: CLLocationCoordinate2D?, address: String?) {
        let location = Location()
        location.name = address
        location.placeType = .Static
        
        if let index = localLocations.indexOf({return $0.placeType == .Static}) {
            localLocations.removeAtIndex(index)
        }
        
        self.localLocations.append(location)
        
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
            }
        } else if segue.identifier == "staticSegue" {
            if let destination = segue.destinationViewController as? StaticLocationViewController {
                destination.delegate = self
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
