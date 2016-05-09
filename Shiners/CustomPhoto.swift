//
//  CustomPhoto.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/6/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import NYTPhotoViewer

class CustomPhoto: NSObject, NYTPhoto{
    var image: UIImage?
    var imageData: NSData?
    var placeholderImage: UIImage?
    let attributedCaptionTitle: NSAttributedString?
    let attributedCaptionSummary: NSAttributedString? = nil
        //NSAttributedString(string: "summary string", attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
    let attributedCaptionCredit: NSAttributedString? = nil
        //NSAttributedString(string: "credit", attributes: [NSForegroundColorAttributeName: UIColor.darkGrayColor()])
    
    init(image: UIImage? = nil, imageData: NSData? = nil, attributedCaptionTitle: NSAttributedString? = nil) {
        self.image = image
        self.imageData = imageData
        self.attributedCaptionTitle = attributedCaptionTitle
        super.init()
    }
}