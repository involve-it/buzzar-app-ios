//
//  FullMapViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 8/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class FullMapViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    
    var geocoderInfo: GeocoderInfo!
    
    override func viewDidLoad() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = self.geocoderInfo.coordinate!
        annotation.title = self.geocoderInfo.address
        self.mapView.showAnnotations([annotation], animated: false)
        self.mapView.selectAnnotation(annotation, animated: false)
        
        let span = MKCoordinateSpanMake(0.075, 0.075)
        let region = MKCoordinateRegionMake(self.geocoderInfo.coordinate!, span)
        self.mapView.setRegion(region, animated: false)
    }
    @IBAction func btnDone_Click(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}