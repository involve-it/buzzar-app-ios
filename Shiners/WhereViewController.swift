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

class WhereViewController: UIViewController, StaticLocationViewControllerDelegate, MKMapViewDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var post: Post!
    var staticLocationAnnotation: MKPointAnnotation!
    
    var locationUpdated = false
    var showSearchResultTabel = false
    var searchResults: [MKPlacemark]!

    let labeDetermineLocationText = NSLocalizedString("Acquiring location...", comment: "Location, Acquiring location...")
    var currentLocationInfo: GeocoderInfo?
    
    private var dynamicLocationRequested = false
    
    private var tapped: Bool = false
    var annotation: MKPointAnnotation?
    var staticCoordinate: CLLocationCoordinate2D?
    private let locationHandler = LocationHandler()
    
    @IBOutlet weak var createPostAddiotionalMenu: UIView!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    @IBOutlet weak var labeDetermineLocation: UILabel!
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    @IBOutlet weak var switcherDynamic: UISwitch!
    @IBOutlet weak var switcherStatic: UISwitch!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchContainerView.alpha = 0
        self.searchContainerView.hidden = true
        
        self.searchResults = [MKPlacemark]()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(currentLocationReported), name: NotificationManager.Name.NewPostLocationReported.rawValue, object: nil)
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.mapView.addGestureRecognizer(gestureRecognizer)
        
        self.tapped = self.staticCoordinate != nil
        if (self.staticCoordinate != nil){
            self.centerMapOnLocation(self.staticCoordinate!, regionRadius: 5000)
            self.setStaticLocation(self.staticCoordinate!, first: false)
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
        NSLog("Location reported: \(geocoderInfo)")
        self.currentLocationInfo = geocoderInfo
        if self.dynamicLocationRequested {
            self.setDynamicLocation()
        } else {
            self.updateUiElementsInLocation()
        }
    }
    
    
    //Switcher
    @IBAction func switcher_getDynamicLocation(sender: UISwitch) {
        //event Value changed

        self.mapView.showsUserLocation = sender.on
        
        if sender.on {
            
            //Center current location on map
            if !self.mapView.userLocationVisible {
                if let currentCoordinate = self.currentLocationInfo?.coordinate {
                    centerMapOnLocation(currentCoordinate, regionRadius: 5000)
                }
            }
            
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
            
            if let currentCoordinate = self.currentLocationInfo?.coordinate {
                self.centerMapOnLocation(currentCoordinate, regionRadius: 5000)
                self.setStaticLocation(currentCoordinate, first: false)
            }
            
            //Go to staticSegue
            //self.performSegueWithIdentifier("staticSegue", sender: self)
            
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
    
    func handleLongPress (gestureRecognizer: UIGestureRecognizer){
        if (gestureRecognizer.state == .Began){
            self.tapped = true
            let point = gestureRecognizer.locationInView(self.mapView)
            let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
            
            self.setStaticLocation(coordinate, first: false)
        }
    }
    
    private func setStaticLocation(coordinate: CLLocationCoordinate2D, first: Bool) {
        self.staticCoordinate = coordinate
        
        self.locationHandler.reverseGeocode(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        
        if let annotation = self.annotation{
            self.mapView.removeAnnotation(annotation)
        }
        
        self.annotation = MKPointAnnotation()
        self.annotation?.title = "Selected locataion"
        if first {
            self.annotation?.subtitle = "Tap and hold anywhere on the map to select location"
        } else {
            self.annotation?.subtitle = ""
        }
        self.annotation?.coordinate = coordinate
        
        self.mapView.addAnnotation(self.annotation!)
        self.mapView.selectAnnotation(self.annotation!, animated: true)
    }
    
    private func searchingRequest(request: String) {
        //запрос на поиск
        if !showSearchResultTabel {
            self.searchContainerView.alpha = 1
            self.searchContainerView.hidden = false
            
            //guard let loc = self.mapView.userLocation.location else {return}
            let req = MKLocalSearchRequest()
            req.naturalLanguageQuery = request
            //req.region = MKCoordinateRegionMake(loc.coordinate, MKCoordinateSpanMake(1, 1))
            let search = MKLocalSearch(request: req)
            search.startWithCompletionHandler({(response: MKLocalSearchResponse?, error: NSError?) in
                guard let response = response else { print(error); return}
                self.mapView.showsUserLocation = false
                
                self.searchResults.removeAll()
                for item in response.mapItems {
                    
                    self.searchResults.append(item.placemark)
                }
                
                self.tableView.reloadData()
                
            })
            
            
        }
    }
    
    
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        //фокус на searchBar
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        
        self.searchContainerView.alpha = 0
        self.searchContainerView.hidden = true
        
        if !(searchBar.text?.isEmpty)! {
            searchBar.text?.removeAll()
        }
        
        if let annotation = self.annotation{
            self.mapView.removeAnnotation(annotation)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        cell.textLabel?.text = self.searchResults[indexPath.row].name
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        
        let location = self.searchResults[indexPath.row].coordinate
        self.centerMapOnLocation(location, regionRadius: 5000)
        
        if let annotation = self.annotation{
            self.mapView.removeAnnotation(annotation)
        }
        
        self.annotation = MKPointAnnotation()
        self.annotation!.title = self.searchResults[indexPath.row].name
        //ann.subtitle = self.searchResults[indexPath.row].subtitle
        self.annotation!.coordinate = location
        self.mapView.addAnnotation(self.annotation!)
        
        UIView.animateWithDuration(0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
            
                self.searchContainerView.alpha = 0
            
            }, completion: { (completed: Bool) in
                self.searchContainerView.hidden = true
        })
        
        //UIView.animateWithDuration(2, delay: 0, options: [.CurveEaseOut], animations: {}, completion: nil)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchingRequest(searchText)
     }
    
    
    
    
    func centerMapOnLocation(location: CLLocationCoordinate2D, regionRadius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: false)
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if !self.locationUpdated {
            let annotation = MKPointAnnotation()
            annotation.coordinate = userLocation.coordinate
            
            
            self.mapView.showAnnotations([self.staticLocationAnnotation, annotation], animated: true)
            self.mapView.selectAnnotation(self.staticLocationAnnotation, animated: false)
            self.mapView.removeAnnotation(annotation)
            self.locationUpdated = true
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
