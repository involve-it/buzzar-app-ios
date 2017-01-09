//
//  LocationHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import CoreLocation

open class LocationHandler: NSObject, CLLocationManagerDelegate {
    open static var lastLocation: CLLocation?
    
    public override init (){
        super.init()
        self.locationManager.delegate = self;
    }
    
    fileprivate var requestType: RequestType?
    fileprivate let locationManager = CLLocationManager()
    fileprivate var notDenied: Bool {
        get {
            return CLLocationManager.authorizationStatus() != .denied
        }
    }
    
    fileprivate var geocodingRequired = false
    fileprivate var monitoring = false
    
    fileprivate lazy var geocoder = CLGeocoder()
    
    open var delegate: LocationHandlerDelegate?
    fileprivate var locationReportedOnce = false
    
    fileprivate static let DEFAULT_LOCATION_UPDATE_TIMEOUT = 30.0
    
    open func startMonitoringLocation() -> Bool{
        if self.notDenied {
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
        }
        
        return self.notDenied
    }
    
    open func stopMonitoringLocation() {
        self.monitoring = false
        self.geocodingRequired = false
        self.locationManager.stopUpdatingLocation()
    }
    
    open func getLocationOnce(_ geocodingRequired: Bool) -> Bool {
        if self.notDenied {
            self.monitoring = false
            self.geocodingRequired = geocodingRequired
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager.requestLocation()
            
            self.locationReportedOnce = false
            Timer.scheduledTimer(timeInterval: LocationHandler.DEFAULT_LOCATION_UPDATE_TIMEOUT, target: self, selector: #selector(notifyTimeout), userInfo: nil, repeats: false)
        }
        
        return self.notDenied
    }
    
    func notifyTimeout(){
        if !self.locationReportedOnce {
            let geocoderInfo = GeocoderInfo()
            geocoderInfo.error = true
            self.delegate?.locationReported(geocoderInfo)
        }
    }
    
    open func monitorSignificantLocationChanges() -> Bool {
        if self.notDenied {
            self.monitoring = true
            self.geocodingRequired = false
            self.locationManager.allowsBackgroundLocationUpdates = true
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.startMonitoringSignificantLocationChanges()
        }
        
        return self.notDenied
    }
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.locationReportedOnce = true
            LocationHandler.lastLocation = location
            CachingHandler.Instance.saveLastLocation(location.coordinate.latitude, lng: location.coordinate.longitude)
            if self.geocodingRequired{
                self.reverseGeocode(location)
            } else {
                let geocoderInfo = GeocoderInfo()
                geocoderInfo.coordinate = location.coordinate
                self.delegate?.locationReported(geocoderInfo)
            }
            if self.monitoring {
                self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            }
        }
    }
    
    open func reverseGeocode(_ location: CLLocation){
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
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if !self.notDenied {
            let geocoderInfo = GeocoderInfo()
            geocoderInfo.denied = true
            geocoderInfo.error = true
            self.delegate?.locationReported(geocoderInfo)
        }
    }
    
    fileprivate enum RequestType {
        case once, monitorSignificant
    }
}

open class GeocoderInfo{
    open var name: String?
    open var address: String?
    open var coordinate: CLLocationCoordinate2D?
    open var denied: Bool = false
    open var error: Bool = false
}

public protocol LocationHandlerDelegate{
    func locationReported(_ geocoderInfo: GeocoderInfo)
}
