//
//  CustomPointAnnotation.swift
//  Shiners
//
//  Created by Вячеслав on 9/12/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import MapKit

class CustomPointAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage?
    var pinCustomImageName: String?
    var id: String?
    var category: String?
    var postType: String?
    var live: Bool!
    
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    
    
}