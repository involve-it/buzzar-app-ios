//
//  AugmentedRealityViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class AugmentedRealityViewController: UIViewController, LocationHandlerDelegate {

    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.posts = AccountHandler.Instance.myPosts!

        // Do any additional setup after loading the view.
        let locationHandler = LocationHandler()
        locationHandler.delegate = self
        locationHandler.startMonitoringLocation()
    }
    
    func locationReported(_ geocoderInfo: GeocoderInfo) {
        
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
