//
//  LocationHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import CoreLocation

public class LocationHandler: NSObject, CLLocationManagerDelegate {
    public override init (){
        super.init()
        self.locationManager.delegate = self;
    }
    
    private var requestType: RequestType?
    private let locationManager = CLLocationManager()
    private var notDenied: Bool {
        get {
            return CLLocationManager.authorizationStatus() != .Denied
        }
    }
    
    private lazy var geocoder = CLGeocoder()
    
    public var delegate: LocationHandlerDelegate?
    
    public func getLocationOnce() -> Bool {
        if self.notDenied {
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager.requestLocation()
        }
        
        return self.notDenied
    }
    
    public func monitorSignificantLocationChanges() -> Bool {
        if self.notDenied {
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.startMonitoringSignificantLocationChanges()
        }
        
        return self.notDenied
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.reverseGeocode(location)
        }
    }
    
    public func reverseGeocode(location: CLLocation){
        self.geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemark = placemarks?.first {
                let geocoderInfo = GeocoderInfo();
                if let locationName = placemark.addressDictionary!["Name"] as? String {
                    geocoderInfo.name = locationName
                }
                if let street = placemark.addressDictionary!["Thoroughfare"] as? String {
                    geocoderInfo.address = street
                } else if let city = placemark.addressDictionary!["City"] as? String {
                    geocoderInfo.address = city
                    if let state = placemark.addressDictionary!["State"] as? String {
                        geocoderInfo.address = geocoderInfo.address! + ", " + state
                    }
                } else if let zip = placemark.addressDictionary!["ZIP"] as? String {
                    geocoderInfo.address = zip
                } else if let country = placemark.addressDictionary!["Country"] as? String {
                    geocoderInfo.address = country
                }
                geocoderInfo.coordinate = location.coordinate
                self.delegate?.locationReported(geocoderInfo)
            }
        };
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if !self.notDenied {
            let geocoderInfo = GeocoderInfo()
            geocoderInfo.denied = true
            geocoderInfo.error = true
            self.delegate?.locationReported(geocoderInfo)
        }
    }
    
    private enum RequestType {
        case Once, MonitorSignificant
    }
}

public class GeocoderInfo{
    public var name: String?
    public var address: String?
    public var coordinate: CLLocationCoordinate2D?
    public var denied: Bool = false
    public var error: Bool = false
}

public protocol LocationHandlerDelegate{
    func locationReported(geocoderInfo: GeocoderInfo)
}