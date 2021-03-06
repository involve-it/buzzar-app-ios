//
//  AugmentedRealityViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import CoreLocation

class AugmentedRealityViewController: UIViewController, PostsViewControllerDelegate{

    var posts = [Post]()
    var mainViewController: PostsMainViewController?
    var currentLocation: CLLocationCoordinate2D?
    var showOnlyClose = true
    
    func postsUpdated(posts: [Post], currentLocation: CLLocationCoordinate2D?) {
        ThreadHelper.runOnMainThread {
            if let location = currentLocation {
                self.currentLocation = location
            }
            if let loc = self.currentLocation, self.showOnlyClose {
                print("have current location")
                let location = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
                self.posts = posts.filter({ (post) -> Bool in
                    if let postLoc = post.getPostLocation() {
                        let postLocation = CLLocation(latitude: postLoc.lat!, longitude: postLoc.lng!)
                        
                        if  location.distance(from: postLocation) / 1000 < 100{
                            return true
                        } else {
                            return false
                        }
                    } else {
                        return false
                    }
                })
            } else {
                print("do not have current location")
                self.posts = Array(posts.prefix(10))
            }
            self.refreshPosts()
        }
    }
    
    func showPostDetails(_ index: Int) {
        
    }
    
    func displayLoadingMore() {
        
    }
    
    @IBAction func btnClose_Click(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func refreshPosts(){
        let arView = self.view as! AugmentedRealityView
        var placesOfInterest = [PlaceOfInterest]()
        self.posts.forEach { (post) in
            if let locations = post.locations, locations.count > 0 {
                var postLocation: Location!
                for location in locations {
                    postLocation = location
                    if location.placeType! == .Dynamic {
                        break
                    }
                }
                /*let label = UILabel();
                 label.adjustsFontSizeToFitWidth = false;
                 label.isOpaque = false;
                 label.backgroundColor = UIColor(colorLiteralRed: 0.1, green: 0.1, blue: 0.1, alpha: 0.5)
                 label.center = CGPoint(x: 200, y: 200);
                 label.textAlignment = .center
                 label.textColor = UIColor.white;
                 label.text = post.title
                 //[NSString stringWithCString:poiNames[i] encoding:NSASCIIStringEncoding];
                 let nsTitle = post.title! as NSString
                 let size = nsTitle.size(attributes: [NSFontAttributeName: label.font])
                 //[label.text sizeWithFont:label.font];
                 label.bounds = CGRect(x:0, y:0, width:size.width, height:size.height);*/
                let view = (Bundle.main.loadNibNamed("ElementView", owner: self, options: nil))?[0] as! ElementView
                view.setup(post: post)
                
                let poi = PlaceOfInterest()
                poi.view = view
                poi.location = CLLocation(latitude: postLocation.lat!, longitude: postLocation.lng!)
                placesOfInterest.append(poi)
            }
        }
        arView.setPlacesOfInterest(pois: placesOfInterest)
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            self.btnClose_Click(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let arView = self.view as! AugmentedRealityView
        arView.initialize()
        self.postsUpdated(posts: self.posts, currentLocation: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.view as! AugmentedRealityView).start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        (self.view as! AugmentedRealityView).stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
