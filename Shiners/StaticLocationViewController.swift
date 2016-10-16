//
//  StaticLocationViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit
import MapKit

public class StaticLocationViewController: UIViewController, MKMapViewDelegate, LocationHandlerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var annotation: MKPointAnnotation?
    
    private let locationHandler = LocationHandler()
    public var delegate: StaticLocationViewControllerDelegate?
    private var tapped: Bool = false;
    
    public var currentCoordinate: CLLocationCoordinate2D?
    
    @IBAction func btnClear_Click(sender: AnyObject) {
        if let annotation = self.annotation{
            self.mapView.removeAnnotation(annotation)
        }
        self.delegate?.locationSelected(nil, address: nil)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad();
        
        self.mapView.delegate = self;
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.mapView.addGestureRecognizer(gestureRecognizer)
        self.locationHandler.delegate = self
        self.tapped = self.currentCoordinate != nil
        if (self.currentCoordinate != nil){
            self.centerMap(self.currentCoordinate!)
            self.processCoordinate(self.currentCoordinate!, first: false)
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.mapView.showsUserLocation = true
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.mapView.showsUserLocation = false
    }
    
    public func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        if (self.currentCoordinate == nil){
            self.centerMap(coordinate)
            self.processCoordinate(coordinate, first: true)
        }
    }
    
    
    
    private func centerMap(coordinate: CLLocationCoordinate2D){
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(region, animated: false)
    }
    
    func handleLongPress (gestureRecognizer: UIGestureRecognizer){
        if (gestureRecognizer.state == .Began){
            self.tapped = true
            let point = gestureRecognizer.locationInView(self.mapView)
            let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
            
            self.processCoordinate(coordinate, first: false)
        }
    }
    
    private func processCoordinate(coordinate: CLLocationCoordinate2D, first: Bool){
        self.currentCoordinate = coordinate;
        self.locationHandler.reverseGeocode(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        
        if let annotation = self.annotation{
            self.mapView.removeAnnotation(annotation)
        }
        self.annotation = MKPointAnnotation()
        self.annotation?.title = NSLocalizedString("Selected locataion", comment: "Annotation title, Selected Locataion")
        if first {
            self.annotation?.subtitle = NSLocalizedString("Tap and hold anywhere on the map to select location", comment: "Annotation subTitle, Tap and hold anywhere on the map to select location")
        } else {
            self.annotation?.subtitle = ""
        }
        self.annotation?.coordinate = coordinate
        
        self.mapView.addAnnotation(self.annotation!)
        self.mapView.selectAnnotation(self.annotation!, animated: true)
    }
    
    public func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation === self.annotation){
            let annotationView =
                MKPinAnnotationView(annotation: annotation, reuseIdentifier: "loc")
            annotationView.canShowCallout = true
            
            return annotationView
        }
        
        return nil;
    }
    
    public func locationReported(geocoderInfo: GeocoderInfo) {
        if (!geocoderInfo.error){
            if let name = geocoderInfo.name {
                self.annotation?.title = name
                if self.tapped {
                    self.annotation?.subtitle = geocoderInfo.address
                }
            } else {
                self.annotation?.title = geocoderInfo.address
                if self.tapped {
                    self.annotation?.subtitle = nil
                }
            }
            
        }
        self.delegate?.locationSelected((self.annotation?.coordinate)!, address: geocoderInfo.name)
    }
}

public protocol StaticLocationViewControllerDelegate{
    func locationSelected(location: CLLocationCoordinate2D?, address: String?)
}