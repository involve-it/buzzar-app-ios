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

class FullMapViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    
    var geocoderInfo: GeocoderInfo!
    var currentLocationAnnotation: MKPointAnnotation!
    
    override func viewDidLoad() {
        self.mapView.delegate = self
        self.currentLocationAnnotation = MKPointAnnotation()
        self.currentLocationAnnotation.coordinate = self.geocoderInfo.coordinate!
        self.currentLocationAnnotation.title = self.geocoderInfo.address
        self.mapView.showAnnotations([self.currentLocationAnnotation], animated: false)
        self.mapView.selectAnnotation(self.currentLocationAnnotation, animated: false)
        
        
        /*let span = MKCoordinateSpanMake(0.075, 0.075)
        let region = MKCoordinateRegionMake(self.geocoderInfo.coordinate!, span)
        self.mapView.setRegion(region, animated: false)*/
    }
    @IBAction func btnDone_Click(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func btnDirections_Click(sender: AnyObject) {
        let pm = MKPlacemark(coordinate: self.geocoderInfo.coordinate!, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: pm)
        mapItem.name = self.geocoderInfo.address
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMapsWithLaunchOptions(launchOptions)
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = userLocation.coordinate
        
        self.mapView.showAnnotations([self.currentLocationAnnotation, annotation], animated: true)
        self.mapView.selectAnnotation(self.currentLocationAnnotation, animated: false)
        self.mapView.removeAnnotation(annotation)
    }
}