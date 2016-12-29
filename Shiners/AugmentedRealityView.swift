//
//  AugmentedRealityView.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import CoreMotion

fileprivate let DEGREES_TO_RADIANS = (M_PI/180.0)
fileprivate let WGS84_A = (6378137.0)
fileprivate let WGS84_E = (8.1819190842622e-2)

class AugmentedRealityView: UIView, CLLocationManagerDelegate {
    var captureSession: AVCaptureSession!
    var captureLayer: AVCaptureVideoPreviewLayer!
    var captureView: UIView!
    
    var locationManager: CLLocationManager!
    var motionManager: CMMotionManager!
    var displayLink: CADisplayLink!
    var projectionTransform: [Float]!
    var placesOfInterest = [PlaceOfInterest]()
    var placesOfInterestCoordinates = [[Float]]()
    var location: CLLocation!
    fileprivate var distances = [DistanceAndIndex]()
    
    var cameraTransform: [Float]!
    
    func start(){
        self.startCameraPreviw()
        self.locationManager.startUpdatingLocation()
        self.startDeviceMotion()
        self.startDisplayLink()
    }
    
    func stop(){
        self.stopCameraPreview()
        self.locationManager.stopUpdatingLocation()
        self.stopDeviceMotion()
        self.stopDisplayLink()
    }
    
    func setPlacesOfInterest(pois: [PlaceOfInterest]){
        self.placesOfInterest.forEach { (poi) in
            poi.view.removeFromSuperview()
        }
        
        self.placesOfInterest = pois
        self.location = LocationHandler.lastLocation
        if self.location != nil {
            self.updatePlacesOfInterestCoordinates()
        }
    }
    
    func initialize(){
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = 100
        
        self.captureView = UIView(frame: self.bounds)
        self.captureView.bounds = self.bounds
        self.addSubview(self.captureView)
        self.sendSubview(toBack: self.captureView)
        var matrix = [Float]()
        self.createProjectionMatrix(mout: &matrix, fovy: Float(60.0) * Float(DEGREES_TO_RADIANS), aspect: Float(self.bounds.size.width / self.bounds.size.height), zNear: 0.25, zFar: 1000)
        self.projectionTransform = matrix
    }
    
    func startDeviceMotion(){
        self.motionManager = CMMotionManager()
        self.motionManager.showsDeviceMovementDisplay = true
        self.motionManager.deviceMotionUpdateInterval = 1.0/60.0
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xTrueNorthZVertical)
    }
    
    func stopDeviceMotion(){
        self.motionManager.stopDeviceMotionUpdates()
        self.motionManager = nil
    }
    
    func startDisplayLink(){
        self.displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink))
        self.displayLink.frameInterval = 1
        self.displayLink.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
    }
    
    func stopDisplayLink(){
        self.displayLink.invalidate()
        self.displayLink = nil
    }
    
    func onDisplayLink(){
        if let d = self.motionManager.deviceMotion {
            let r = d.attitude.rotationMatrix
            var t = self.cameraTransform ?? [Float]()
            self.transformFromCMRotationMatrix(mout: &t, m: r)
            self.cameraTransform = t
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        if self.cameraTransform != nil {
            var projectionCameraTransform = [Float]();
            
            self.multiplyMatrixAndMatrix(c: &projectionCameraTransform, a: self.projectionTransform, b: self.cameraTransform);
            
            var i = 0;
            self.placesOfInterest.forEach { (poi) in
                var v = [Float]()
                self.multiplyMatrixAndVector(vout: &v, m: projectionCameraTransform, v: placesOfInterestCoordinates[i]);
                
                let x = (v[0] / v[3] + 1.0) * 0.5;
                let y = (v[1] / v[3] + 1.0) * 0.5;
                if (v[2] < 0.0) {
                    //NSLog(@"%@", self.bounds);
                    
                    //NSLog(@"%@", @"here goes bounds.size.width/height:");
                    //NSLog(@"%f",self.bounds.size.width);
                    //NSLog(@"%f",self.bounds.size.height);
                    poi.view.center = CGPoint(x: CGFloat(x)*self.bounds.size.width, y: self.bounds.size.height-CGFloat(y)*self.bounds.size.height);
                    poi.view.isHidden = false;
                    if let index = self.distances.index(where: {$0.index == i}){
                        let distance = self.distances[index]
                        (poi.view as! ElementView).setDistance(distance: distance.distance / 1000)
                    }
                    
                } else {
                    poi.view.isHidden = true;
                }
                i += 1;

            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.location = location
            if self.placesOfInterest.count > 0 {
                self.updatePlacesOfInterestCoordinates()
            }
        }
    }
    
    func updatePlacesOfInterestCoordinates(){
        self.placesOfInterestCoordinates.removeAll()
        
        let ecef = Ecef()
        ecef.lat = self.location.coordinate.latitude
        ecef.lon = self.location.coordinate.longitude
        
        self.latLonToEcef(ecef: ecef)
        self.distances.removeAll()
        var i = 0
        self.placesOfInterest.forEach { (poi) in
            let ecefPoi = Ecef()
            ecefPoi.lat = poi.location.coordinate.latitude
            ecefPoi.lon = poi.location.coordinate.longitude
            self.latLonToEcef(ecef: ecefPoi)
            let enu = Enu()
            enu.lat = self.location.coordinate.latitude
            enu.lon = self.location.coordinate.longitude
            enu.x = ecef.x
            enu.y = ecef.y
            enu.z = ecef.z
            enu.xr = ecefPoi.x
            enu.yr = ecefPoi.y
            enu.zr = ecefPoi.z
            self.ecefToEnu(enu: enu)
            
            var coords = [Float](repeating: 0, count: 4)
            coords[0] = Float(enu.n)
            coords[1] = -Float(enu.e)
            coords[2] = 0
            coords[3] = 1
            self.placesOfInterestCoordinates.append(coords)
            
            var distanceAndIndex = DistanceAndIndex()
            distanceAndIndex.distance = sqrt(enu.n * enu.n + enu.e * enu.e)
            distanceAndIndex.index = i
            self.distances.append(distanceAndIndex)
            
            i += 1
        }
        
        
        self.distances.sort { (a, b) -> Bool in
            if a.distance > b.distance {
                return true
            } else {
                return false
            }
        }
        
        self.distances.forEach { (distance) in
            let poi = self.placesOfInterest[distance.index]
            self.addSubview(poi.view)
        }
    }

    fileprivate func startCameraPreviw() {
        guard let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {return}
        self.captureSession = AVCaptureSession()
        var videoInput: AVCaptureDeviceInput
        do{
            videoInput = try AVCaptureDeviceInput(device: camera)
        }
        catch {
            return
        }
        self.captureSession.addInput(videoInput)
        self.captureLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.captureLayer.frame = self.captureView.bounds
        self.captureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.captureView.layer.addSublayer(self.captureLayer)
        let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        backgroundQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    fileprivate func stopCameraPreview(){
        self.captureSession.stopRunning()
        self.captureLayer.removeFromSuperlayer()
        self.captureSession = nil
        self.captureLayer = nil
    }
    
    //conversion
    func createProjectionMatrix(mout: inout [Float], fovy: Float, aspect: Float, zNear: Float, zFar: Float)
    {
        let f = 1.0 / tanf(fovy/2.0);
        
        mout = [Float](repeating: 0.0, count: 16)
        
        mout[0] = f / aspect;
        mout[1] = 0.0;
        mout[2] = 0.0;
        mout[3] = 0.0;
        
        mout[4] = 0.0;
        mout[5] = f;
        mout[6] = 0.0;
        mout[7] = 0.0;
        
        mout[8] = 0.0;
        mout[9] = 0.0;
        mout[10] = (zFar+zNear) / (zNear-zFar);
        mout[11] = -1.0;
        
        mout[12] = 0.0;
        mout[13] = 0.0;
        mout[14] = 2 * zFar * zNear /  (zNear-zFar);
        mout[15] = 0.0;
    }
    
    func multiplyMatrixAndVector(vout: inout [Float], m: [Float], v: [Float])
    {
        vout = [Float](repeating: 0.0, count: 4)
        
        vout[0] = m[0]*v[0] + m[4]*v[1] + m[8]*v[2] + m[12]*v[3];
        vout[1] = m[1]*v[0] + m[5]*v[1] + m[9]*v[2] + m[13]*v[3];
        vout[2] = m[2]*v[0] + m[6]*v[1] + m[10]*v[2] + m[14]*v[3];
        vout[3] = m[3]*v[0] + m[7]*v[1] + m[11]*v[2] + m[15]*v[3];
    }
    
    func multiplyMatrixAndMatrix(c: inout [Float], a: [Float], b: [Float])
    {
        //memset(c, 0, 16*sizeof(float));
        c = [Float](repeating: 0.0, count: 16)
        
        for col in 0...3 {
            for row in 0...3 {
                for i in 0...3 {
                    c[col*4+row] += a[i*4+row]*b[col*4+i];
                }
            }
        }
    }

    func transformFromCMRotationMatrix(mout: inout [Float], m: CMRotationMatrix)
    {
        mout = [Float](repeating: 0.0, count: 16)
        
        mout[0] = Float(m.m11);
        mout[1] = Float(m.m21);
        mout[2] = Float(m.m31);
        mout[3] = 0.0;
        
        mout[4] = Float(m.m12);
        mout[5] = Float(m.m22);
        mout[6] = Float(m.m32);
        mout[7] = 0.0;
        
        mout[8] = Float(m.m13);
        mout[9] = Float(m.m23);
        mout[10] = Float(m.m33);
        mout[11] = 0.0;
        
        mout[12] = 0.0;
        mout[13] = 0.0;
        mout[14] = 0.0;
        mout[15] = 1.0;
    }
    
    fileprivate func latLonToEcef(ecef: Ecef)
    {
        let clat = cos(ecef.lat * DEGREES_TO_RADIANS);
        let slat = sin(ecef.lat * DEGREES_TO_RADIANS);
        let clon = cos(ecef.lon * DEGREES_TO_RADIANS);
        let slon = sin(ecef.lon * DEGREES_TO_RADIANS);
    
        let N = WGS84_A / sqrt(1.0 - WGS84_E * WGS84_E * slat * slat);
        
        ecef.x = (N + ecef.alt) * clat * clon;
        ecef.y = (N + ecef.alt) * clat * slon;
        ecef.z = (N * (1.0 - WGS84_E * WGS84_E) + ecef.alt) * slat;
    }
    
    // Coverts ECEF to ENU coordinates centered at given lat, lon
    fileprivate func ecefToEnu(enu: Enu)
    {
        let clat = cos(enu.lat * DEGREES_TO_RADIANS);
        let slat = sin(enu.lat * DEGREES_TO_RADIANS);
        let clon = cos(enu.lon * DEGREES_TO_RADIANS);
        let slon = sin(enu.lon * DEGREES_TO_RADIANS);
        let dx = enu.x - enu.xr;
        let dy = enu.y - enu.yr;
        let dz = enu.z - enu.zr;
        
        enu.e = -slon*dx  + clon*dy;
        enu.n = -slat*clon*dx - slat*slon*dy + clat*dz;
        enu.u = clat*clon*dx + clat*slon*dy + slat*dz;
    }
    
    fileprivate class Ecef {
        var lat: Double!
        var lon: Double!
        var alt: Double = 0.0
        var x: Double = 0.0
        var y: Double = 0.0
        var z: Double = 0.0
    }
    
    fileprivate class Enu {
        var lat: Double!
        var lon: Double!
        var x: Double!
        var y: Double!
        var z: Double!
        var xr: Double!
        var yr: Double!
        var zr: Double!
        
        var e: Double = 0.0
        var n: Double = 0.0
        var u: Double = 0.0
    }
    
    fileprivate struct DistanceAndIndex{
        var distance: Double!
        var index: Int!
    }
    
}
