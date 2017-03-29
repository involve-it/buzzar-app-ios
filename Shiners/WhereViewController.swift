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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class WhereViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, LocationHandlerDelegate {
    
    var post: Post!
    
    var locationUpdated = false
    var searchResults: [MKPlacemark]!

    let labeDetermineLocationText = NSLocalizedString("Acquiring location...", comment: "Location, Acquiring location...")
    var currentLocationInfo: GeocoderInfo?
    
    fileprivate var dynamicLocationRequested = false
    
    fileprivate var tapped: Bool = false
    var annotation: MKPointAnnotation?
    
    fileprivate let locationHandler = LocationHandler()
    
    @IBOutlet weak var createPostAddiotionalMenu: UIView!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    @IBOutlet weak var labeDetermineLocation: UILabel!
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var switcherDynamic: UISwitch!
    @IBOutlet weak var switcherStatic: UISwitch!
    var editingPost = false
    var lastStaticSearchRequestId = ""
    
    func locationReported(_ geocoderInfo: GeocoderInfo) {
        if let annotation = self.annotation, let address = geocoderInfo.address{
            ThreadHelper.runOnMainThread({ 
                annotation.title = address
            })
            if let index = post.locations!.index(where: {return $0.placeType == .Static}) {
                post.locations![index].name = address
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.editingPost {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.searchContainerView.alpha = 0
        self.searchContainerView.isHidden = true
        
        self.searchResults = [MKPlacemark]()
        self.locationHandler.delegate = self
        self.mapView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(currentLocationReported), name: NSNotification.Name(rawValue: NotificationManager.Name.NewPostLocationReported.rawValue), object: nil)
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.mapView.addGestureRecognizer(gestureRecognizer)
        if post.locations == nil {
            post.locations = [Location]()
        }
        self.labeDetermineLocation.text = labeDetermineLocationText
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppAnalytics.logScreen(.NewPost_Loc)
        
        if let _ = self.post.locations!.index(where: {return $0.placeType == .Dynamic}) {
            self.mapView.showsUserLocation = true
            self.switcherDynamic.isOn = true
        }
        
        if let index = self.post.locations!.index(where: {return $0.placeType == .Static}) {
            let location = self.post.locations![index]
            self.setStaticLocation(CLLocationCoordinate2DMake(location.lat!, location.lng!), first: false)
        }
        
        self.centerMapOnAnnotations()
        self.updateUiElementsInLocation()
        
    }
    
    func currentLocationReported(_ notification: Notification){
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
    @IBAction func switcher_getDynamicLocation(_ sender: UISwitch) {
        self.mapView.showsUserLocation = sender.isOn
        
        if sender.isOn {
            if self.switcherStatic.isOn {
                self.switcherStatic.setOn(false, animated: true)
                self.removeStaticLocation()
            }
            AppAnalytics.logEvent(.NewPostWizard_Loc_Dynamic_On)
            //Center current location on map
            if !self.mapView.isUserLocationVisible {
                self.centerMapOnAnnotations()
            }
            
            self.labeDetermineLocation.text = self.labeDetermineLocationText
            if let _ = self.currentLocationInfo{
                self.setDynamicLocation()
            } else {
                self.dynamicLocationRequested = true
            }
        } else {
            AppAnalytics.logEvent(.NewPostWizard_Loc_Dynamic_Off)
            self.removeDynamicLocation()
        }
        updateUiElementsInLocation()
    }
    
    func removeDynamicLocation() {
        if let index = self.post.locations!.index(where: {return $0.placeType == .Dynamic}) {
            self.post.locations!.remove(at: index)
        }
    }
    
    
    @IBAction func switcher_getStaticLocation(_ sender: UISwitch) {
        if sender.isOn {
            if self.switcherDynamic.isOn {
                self.switcherDynamic.setOn(false, animated: true)
                self.removeDynamicLocation()
            }
            AppAnalytics.logEvent(.NewPostWizard_Loc_Static_On)
            if let currentCoordinate = self.currentLocationInfo?.coordinate {
                self.setStaticLocation(currentCoordinate, first: true)
                self.centerMapOnAnnotations()
            }
            
        } else {
            AppAnalytics.logEvent(.NewPostWizard_Loc_Static_Off)
            self.removeStaticLocation()
        }
        
        updateUiElementsInLocation()
    }
    
    func removeStaticLocation(){
        if let annotation = self.annotation{
            self.mapView.removeAnnotation(annotation)
            self.annotation = nil
        }
        if let index = self.post.locations!.index(where: {return $0.placeType == .Static}) {
            self.post.locations!.remove(at: index)
        }
    }
    
    func handleLongPress (_ gestureRecognizer: UIGestureRecognizer){
        if (gestureRecognizer.state == .began){
            self.searchBar.showsCancelButton = false
            self.searchBar.resignFirstResponder()
            self.tapped = true
            let point = gestureRecognizer.location(in: self.mapView)
            let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
            
            self.setStaticLocation(coordinate, first: false)
            self.updateUiElementsInLocation()
        }
    }
    
    fileprivate func setStaticLocation(_ coordinate: CLLocationCoordinate2D, first: Bool) {
        self.locationHandler.reverseGeocode(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        
        if let annotation = self.annotation{
            self.mapView.removeAnnotation(annotation)
        }
        
        self.annotation = MKPointAnnotation()
        self.annotation?.title = "Selected locataion"
        if first {
            self.annotation?.subtitle = "Tap and hold anywhere on the map to change"
        } else {
            self.annotation?.subtitle = ""
        }
        self.annotation?.coordinate = coordinate
        
        self.mapView.addAnnotation(self.annotation!)
        self.mapView.selectAnnotation(self.annotation!, animated: true)
        
        let location = Location()
        
        location.lat = coordinate.latitude
        location.lng = coordinate.longitude
        location.placeType = .Static
        
        if let index = post.locations!.index(where: {return $0.placeType == .Static}) {
            post.locations!.remove(at: index)
        }
        
        self.post.locations!.append(location)
        self.switcherStatic.isOn = true
    }
    
    @objc fileprivate func searchingRequest(_ request: String) {
        //запрос на поиск
        if request != "" {
            let requestId = UUID().uuidString
            self.lastStaticSearchRequestId = requestId
            
            self.searchContainerView.alpha = 1
            self.searchContainerView.isHidden = false
            
            //guard let loc = self.mapView.userLocation.location else {return}
            let req = MKLocalSearchRequest()
            req.naturalLanguageQuery = request
            if let currentCoords = self.currentLocationInfo?.coordinate{
                req.region = MKCoordinateRegionMake(currentCoords, MKCoordinateSpanMake(1, 1))
            }
            //req.region = MKCoordinateRegionMake(loc.coordinate, MKCoordinateSpanMake(1, 1))
            let search = MKLocalSearch(request: req)
            search.start(completionHandler: { (response, error) in
                guard let response = response, requestId == self.lastStaticSearchRequestId else { return }
                
                self.searchResults.removeAll()
                for item in response.mapItems {
                    
                    self.searchResults.append(item.placemark)
                }
                ThreadHelper.runOnMainThread({
                    self.tableView.reloadData()
                })
            })
        } else {
            self.searchContainerView.alpha = 0
            self.searchContainerView.isHidden = true
            self.searchResults.removeAll()
            self.tableView.reloadData()
        }
    }
    
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //фокус на searchBar
        AppAnalytics.logEvent(.NewPostWizard_Loc_SearchFieldActive)
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        AppAnalytics.logEvent(.NewPostWizard_Loc_Search_Cancel_Click)
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        
        self.searchContainerView.alpha = 0
        self.searchContainerView.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = self.searchResults[indexPath.row].title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppAnalytics.logEvent(.NewPostWizard_Loc_Search_ResSelected)
        tableView.deselectRow(at: indexPath, animated: true)
        self.switcherStatic.isOn = true
        
        let location = self.searchResults[indexPath.row].coordinate
        
        if let annotation = self.annotation{
            self.mapView.removeAnnotation(annotation)
        }
        
        self.annotation = MKPointAnnotation()
        self.annotation!.title = self.searchResults[indexPath.row].name
        //ann.subtitle = self.searchResults[indexPath.row].subtitle
        self.annotation!.coordinate = location
        self.mapView.addAnnotation(self.annotation!)
        
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.searchContainerView.alpha = 0
            }, completion: { (completed: Bool) in
                self.searchContainerView.isHidden = true
        })
        
        self.setStaticLocation(location, first: false)
        self.centerMapOnAnnotations()
        self.searchBar.resignFirstResponder()
        self.searchBar.showsCancelButton = false
        if !self.editingPost {
            self.btn_next.isEnabled = true
        }
        
        //UIView.animateWithDuration(2, delay: 0, options: [.CurveEaseOut], animations: {}, completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchingRequest(searchText)
     }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !self.locationUpdated {
            self.locationUpdated = true
            self.centerMapOnAnnotations()
        }
    }
    
    func centerMapOnAnnotations(){
        var annotations = [MKPointAnnotation]()
        var dynamicAnnotation: MKPointAnnotation?
        if self.mapView.showsUserLocation && self.locationUpdated{
            dynamicAnnotation = MKPointAnnotation()
            dynamicAnnotation!.coordinate = self.mapView.userLocation.coordinate
            annotations.append(dynamicAnnotation!)
        }
        
        if let staticAnnotation = self.annotation{
            annotations.append(staticAnnotation)
        }
        if annotations.count > 0 {
            ThreadHelper.runOnMainThread({ 
                self.mapView.showAnnotations(annotations, animated: true)
                if let dynAnnotation = dynamicAnnotation{
                    self.mapView.removeAnnotation(dynAnnotation)
                }
            })
        } /*else {
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(location,
                                                                      regionRadius * 2.0, regionRadius * 2.0)
            mapView.setRegion(coordinateRegion, animated: false)
        }*/
    }
    
    //****************************************************************//
    
    @IBAction func createPost(_ sender: AnyObject) {
        if let post = self.post {
            
            //print("\(post)")
            
            let callback: MeteorMethodCallback = { (success, errorId, errorMessage, result) in
                if success{
                    AccountHandler.Instance.updateMyPosts()
                    ThreadHelper.runOnMainThread({
                        self.view.endEditing(true)
                        self.navigationController?.dismiss(animated: true, completion: nil)
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
                
                if let index = post.locations!.index(where: {return $0.placeType == .Dynamic}) {
                    post.locations!.remove(at: index)
                }
                
                self.post.locations!.append(location)
                
                //self.currentDynamicLocation = location
            }
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
                self.switcherStatic.isOn = false
            }
            
            if !self.editingPost {
                if self.post.locations?.count > 0 {
                    self.btn_next.isEnabled = true
                    self.createPostAddiotionalMenu.isHidden = false
                } else {
                    self.btn_next.isEnabled = false
                    self.createPostAddiotionalMenu.isHidden = true
                }
            }
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueDatePicker" {
            AppAnalytics.logEvent(.NewPostWizard_Loc_BtnNext_Click)
            if let destination = segue.destination as? WhenPickDateViewController {
                
                //Передаем объект post следующему контроллеру
                destination.post = post
                destination.currentLocationInfo = self.currentLocationInfo
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
