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
    var mainViewController: PostsMainViewController!
    
    func postsUpdated() {
        self.posts = mainViewController.allPosts
        self.refreshPosts()
    }
    
    func showPostDetails(_ index: Int) {
        
    }
    
    func displayLoadingMore() {
        
    }
    
    @IBAction func btnClose_Click(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.mainViewController.currentViewController = self.mainViewController.viewControllerForSelectedSegmentIndex(self.mainViewController.typeSwitch.selectedSegmentIndex)
        })
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let arView = self.view as! AugmentedRealityView
        arView.initialize()
        self.refreshPosts()
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
