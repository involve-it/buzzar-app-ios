//
//  MapTypeViewController.swift
//  Shiners
//
//  Created by Вячеслав on 9/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import MapKit

class PostsMapViewController: UIViewController, MKMapViewDelegate, PostsViewControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!

    var currentLocationAnnotation: CustomPointAnnotation!
    var locationUpdated = false
    
    var postsLocationAnnotations = [CustomPointAnnotation]()
    var postsPlaceMarks: [CLPlacemark]!
    var geoCoder: CLGeocoder!
    
    weak var mainViewController: PostsMainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mainViewController = self.parentViewController as! PostsMainViewController
        
        //Location's of post
        self.postsUpdated()
    }
    
    func postsUpdated() {
        self.updateMap(self.mainViewController.posts)
    }
    
    func showPostDetails(index: Int) {
        let detailsViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("postDetails") as! PostDetailsViewController
        let post = self.mainViewController.posts[index]
        if let currentLocation = self.mainViewController.currentLocation {
            //current location
            let curLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            post.outDistancePost = post.getDistanceFormatted(curLocation)
        }
        detailsViewController.post = post
        self.mainViewController.navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.mapView.showsUserLocation = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.mapView.showsUserLocation = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func updateMap(posts: [Post]) {
        self.mapView.removeAnnotations(self.postsLocationAnnotations)
        self.postsLocationAnnotations = [CustomPointAnnotation]()
        if posts.count > 0 {
            
            for post in posts {
                
                
                if let postCoordinateLocations = post.locations {
                    
                    var postLocation: Location?
                    for coordinareLocation in postCoordinateLocations {
                        
                        if coordinareLocation.placeType == .Dynamic {
                            //Dynamic
                            postLocation = coordinareLocation
                        } else {
                            //Static
                            postLocation = coordinareLocation
                        }
                        
                    }
                    
                    //print("Post Location: \(postLocation)")
                    
                    if let postLocation = postLocation, lat = postLocation.lat, lng = postLocation.lng {
                        
                        let location: CLLocation = {
                            let loc = CLLocation(latitude: lat, longitude: lng)
                            return loc
                        }()
                        
                        let annotation = CustomPointAnnotation(coordinate: location.coordinate)
                        annotation.id = post.id
                        annotation.title = post.title
                        if let subTitle = post.descr {
                            annotation.subtitle = subTitle
                        }
                        
                        if post.photos?.count > 0 {
                            if let postImage = post.photos?[0].thumbnail ?? post.photos?[0].original {
                                if ImageCachingHandler.Instance.getImageFromUrl(postImage, defaultImage: ImageCachingHandler.defaultPhoto, callback: { (image) in
                                    ThreadHelper.runOnMainThread({
                                        annotation.image = image
                                    })
                                }){
                                    annotation.image = ImageCachingHandler.defaultPhoto
                                }
                            }
                        } else {
                            annotation.image = ImageCachingHandler.defaultPhoto
                        }
                        
                        annotation.pinCustomImageName = "dynamic_annotation"
                        
                        postsLocationAnnotations.append(annotation)
 

//                        geoCoder = CLGeocoder()
//                        postsPlaceMarks = [CLPlacemark]()
                        
//                        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
//                        
//                            if error != nil {
//                                print("Reverse geocoder failed with error: \(error!.localizedDescription)")
//                            }
//                    
//                            /*if placemarks != nil {
//                                //self.postsPlaceMarks.append(placemarks[0])
//                                if let placemark = placemarks?.first {
//                                    let name = placemark.name
//                                    print("PlaceMark name: \(name)")
//                                    
//                                    //Add annotation
//                                    //let anatation = MKPointAnnotation()
//                                    //anatation.coordinate = location.coordinate
//                                    
//                                    //let anatation = CustomPointAnnotation()
//                                    //anatation.coordinate = placemark.location!.coordinate
//                                    //anatation.title = name
//                                    //anatation.pinCustomImageName = "dynamic_annotation"
//                                    //self.postsPlaceMarks.append(placemark)
//         
//                                }
//                            }*/
//                        })
                    }
                }
            }
            let currentVisibleMapRectangle = self.mapView.visibleMapRect
            //Show all annotations
            self.mapView.showAnnotations(self.postsLocationAnnotations, animated: false)
            self.mapView.setVisibleMapRect(currentVisibleMapRectangle, animated: false)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        if (annotation is CustomPointAnnotation){
            let reuseIdentifier = "pin"
            var view = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView
            
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                view!.canShowCallout = true
                view?.centerOffset = CGPointMake(10, -20)
            } else {
                view!.annotation = annotation
            }
            
            let customPointAnnotation = annotation as! CustomPointAnnotation
            //view!.image = UIImage(named: customPointAnnotation.pinCustomImageName!)
            
            let leftIconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 53, height: 53))
            leftIconView.image = customPointAnnotation.image
            leftIconView.contentMode = .ScaleAspectFill
            leftIconView.clipsToBounds = true
            view?.leftCalloutAccessoryView = leftIconView
            let btn = UIButton(type: .DetailDisclosure)
            view?.rightCalloutAccessoryView = btn
            
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? CustomPointAnnotation, postIndex = self.mainViewController!.posts.indexOf({$0.id == annotation.id}){
            self.showPostDetails(postIndex)
        }
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if !self.locationUpdated {
            self.currentLocationAnnotation = CustomPointAnnotation(coordinate: userLocation.coordinate)
            
        
            self.mapView.showAnnotations([self.currentLocationAnnotation] + self.postsLocationAnnotations, animated: true)
            self.mapView.selectAnnotation(self.currentLocationAnnotation, animated: false)
            self.mapView.removeAnnotation(self.currentLocationAnnotation)
            
            //Center map on location
            if let currentLocation = currentLocationAnnotation {
                centerMapOnLocation(currentLocation, regionRadius: 10000.0)
                self.mapView.selectAnnotation(currentLocation, animated: false)
            }
            
            self.locationUpdated = true
        }
    }
    
    /*
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.sharedApplication()
            app.openURL(NSURL(string: (annotationView.annotation!.title!)!)!)
        }
    }*/
    
    
    func centerMapOnLocation(location: CustomPointAnnotation, regionRadius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        //let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(coordinateRegion, animated: true)
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

