//
//  MapTypeViewController.swift
//  Shiners
//
//  Created by Вячеслав on 9/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
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
        
        self.mainViewController = self.parent as! PostsMainViewController
        
        //Location's of post
        self.postsUpdated()
    }
    
    func postsUpdated() {
        self.updateMap(self.mainViewController.allPosts)
    }
    
    func showPostDetails(_ index: Int) {
        let detailsViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "postDetails") as! PostDetailsViewController
        let post = self.mainViewController.allPosts[index]
        if let currentLocation = self.mainViewController.currentLocation {
            //current location
            let curLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            post.outDistancePost = post.getDistanceFormatted(curLocation)
        }
        detailsViewController.post = post
        
        detailsViewController.pendingCommentsAsyncId = CommentsHandler.Instance.getCommentsAsync(post.id!, skip: 0)
        detailsViewController.subscriptionId = AccountHandler.Instance.subscribeToCommentsForPost(post.id!)
        
        self.mainViewController.navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.NearbyPosts_Map)
        self.mapView.showsUserLocation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.mapView.showsUserLocation = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func updateMap(_ posts: [Post]) {
        self.mapView.removeAnnotations(self.postsLocationAnnotations)
        self.postsLocationAnnotations = [CustomPointAnnotation]()
        if posts.count > 0 {
            
            for post in posts {
                
                
                if let postCoordinateLocations = post.locations {
                    
                    var postLocation: Location?
                    var postType: String!
                    for coordinareLocation in postCoordinateLocations {
                        
                        if coordinareLocation.placeType == .Dynamic {
                            //Dynamic
                            postLocation = coordinareLocation
                            postType = "dynamic"
                            break
                        } else {
                            //Static
                            postLocation = coordinareLocation
                            postType = "static"
                        }
                        
                    }
                    
                    //print("Post Location: \(postLocation)")
                    
                    if let postLocation = postLocation, let lat = postLocation.lat, let lng = postLocation.lng {
                        
                        let location = CLLocation(latitude: lat, longitude: lng)
                        
                        let annotation = CustomPointAnnotation(coordinate: location.coordinate)
                        annotation.id = post.id
                        
                        if let category = post.type?.rawValue {
                            annotation.category = category
                        }
                        
                        annotation.live = post.isLive()
                        annotation.postType = postType
                        
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let customPointAnnotation = annotation as! CustomPointAnnotation
        
        if let _ = customPointAnnotation.id {
            let reuseIdentifier = "customPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            
            if (annotationView == nil) {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView!.canShowCallout = true
                annotationView?.centerOffset = CGPoint(x: 10, y: -20)
            } else {
                annotationView!.annotation = annotation
            }
            
            var imageName: String!
            if let category = customPointAnnotation.category {
                imageName = "\(customPointAnnotation.postType!)-\((customPointAnnotation.live ?? false) ? "live" : "offline")-flag-" + "\(category)"
            } else {
                imageName = "\(customPointAnnotation.postType!)-\((customPointAnnotation.live ?? false) ? "live" : "offline")-flag-jobs"
            }
            annotationView!.image = UIImage(named: imageName)
            
            annotationView?.frame = CGRect(x: 0, y: 0, width: 24.2, height: 32)
            
            let leftIconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 53, height: 53))
            leftIconView.image = customPointAnnotation.image
            leftIconView.contentMode = .scaleAspectFill
            leftIconView.clipsToBounds = true
            annotationView?.leftCalloutAccessoryView = leftIconView
            
            let btn = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = btn

            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? CustomPointAnnotation, let postIndex = self.mainViewController!.allPosts.index(where: {$0.id == annotation.id}){
            AppAnalytics.logEvent(.NearbyPostsScreen_Map_PostSelected)
            self.showPostDetails(postIndex)
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
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
    
    func displayLoadingMore() {
        
    }
    
    func centerMapOnLocation(_ location: CustomPointAnnotation, regionRadius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        //let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(coordinateRegion, animated: false)
    }

}

