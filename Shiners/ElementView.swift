//
//  ElementView.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/28/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import CoreLocation

class ElementView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    @IBOutlet var lblDistance: UILabel!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet var photoLoc: UIImageView!
    
    var post: Post!
    
    func setup(post: Post){
        self.post = post
        self.isOpaque = false;
        self.backgroundColor = UIColor(colorLiteralRed: 0.1, green: 0.1, blue: 0.1, alpha: 0)
        
        self.center = CGPoint(x: 200, y: 200);
        self.lbl.textAlignment = .center
        self.lbl.textColor = UIColor.white;
        self.lbl.text = post.title
        self.lbl.frame.size.height = post.title!.heightWithConstrainedWidth(149, font: self.lbl.font)
        self.lbl.backgroundColor = UIColor(colorLiteralRed: 0.1, green: 0.1, blue: 0.1, alpha: 0.5)
        self.photoLoc.backgroundColor = UIColor(colorLiteralRed: 0.1, green: 0.1, blue: 0.1, alpha: 0.5)
        
        self.lblDistance.tintColor = UIColor(red: 90/255, green: 177/255, blue: 231/255, alpha: 1)
        self.lblDistance.textColor = UIColor.white;
        self.lblDistance.isHidden = true
        self.lblDistance.backgroundColor = UIColor(colorLiteralRed: 0.1, green: 0.1, blue: 0.1, alpha: 0.5)
        //self.photo.alpha = 0.5
        //[NSString stringWithCString:poiNames[i] encoding:NSASCIIStringEncoding];
        //let nsTitle = post.title! as NSString
        //let size = nsTitle.size(attributes: [NSFontAttributeName: self.lbl.font])
        //[label.text sizeWithFont:label.font];
        //self.lbl.bounds = CGRect(x:0, y:0, width:size.width, height:size.height);
        //self.frame = CGRect(x: 0, y: 0, width: 100, height: self.photo.frame.height + 8 + self.lbl.frame.height)
        self.lbl.layer.cornerRadius = 4
        self.lbl.sizeToFit()
        
        self.photo.image = UIImage(named: post.getPostCategoryImageName())
        
        self.frame.size.width = 150
        self.frame.size.height = 67 + self.lbl.frame.size.height
        
        
        /*self.photo.image = ImageCachingHandler.defaultPhoto
        if let photo = post.getMainPhoto(), let original = photo.original {
            ImageCachingHandler.Instance.getImageFromUrl(original, callback: {(image) in
                ThreadHelper.runOnMainThread {
                    self.photo.image = image
                    let ratio = image!.size.height / image!.size.width
                    if ratio > 0 {
                        self.frame.size.width /= ratio
                    } else {
                        self.frame.size.height /= ratio
                    }
                    self.setNeedsLayout()
                }
            })
        }*/
        
        self.setNeedsLayout()
    }
    
    func setLocation(location: CLLocation){
        ThreadHelper.runOnMainThread {
            self.lblDistance.isHidden = false
            self.lblDistance.text = self.post.getDistanceFormatted(location)
        }
    }
}
