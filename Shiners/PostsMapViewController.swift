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
        self.updateMap(self.mainViewController.allPosts)
    }
    
    func showPostDetails(index: Int) {
        let detailsViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("postDetails") as! PostDetailsViewController
        let post = self.mainViewController.allPosts[index]
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
                        
                        postsLocationAnnotations.append(annotation)
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
        
        let customPointAnnotation = annotation as! CustomPointAnnotation
        
        if (annotation is CustomPointAnnotation) {
            let reuseIdentifier = "customPin"
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
            
            if (annotationView == nil) {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView!.canShowCallout = true
                annotationView?.centerOffset = CGPointMake(10, -20)
            } else {
                annotationView!.annotation = annotation
                
            }
            
            annotationView!.image = UIImage(named: "static-live-flag-jobs")
            annotationView?.frame = CGRect(x: 0, y: 0, width: 24.2, height: 32)
            
            let leftIconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 53, height: 53))
            leftIconView.image = customPointAnnotation.image
            leftIconView.contentMode = .ScaleAspectFill
            leftIconView.clipsToBounds = true
            annotationView?.leftCalloutAccessoryView = leftIconView
            let btn = UIButton(type: .DetailDisclosure)
            annotationView?.rightCalloutAccessoryView = btn

            return annotationView
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? CustomPointAnnotation, postIndex = self.mainViewController!.allPosts.indexOf({$0.id == annotation.id}){
            self.showPostDetails(postIndex)
        }
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if !self.locationUpdated {
            self.currentLocationAnnotation = CustomPointAnnotation(coordinate: userLocation.coordinate)
            
        
            self.mapView.showAnnotations([self.currentLocationAnnotation] + self.postsLocationAnnotations, animated: false)
            self.mapView.selectAnnotation(self.currentLocationAnnotation, animated: false)
            self.mapView.removeAnnotation(self.currentLocationAnnotation)
            
            //Center map on location
            if let currentLocation = currentLocationAnnotation {
                centerMapOnLocation(currentLocation, regionRadius: 160.0)
                self.mapView.selectAnnotation(currentLocation, animated: false)
            }
            
            self.locationUpdated = true
        }
    }
    
    

    
    func centerMapOnLocation(location: CustomPointAnnotation, regionRadius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        //let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(coordinateRegion, animated: false)
    }

}

