//
//  GradientViewPostDetailsScrollView.swift
//  Shiners
//
//  Created by Вячеслав on 7/20/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

@IBDesignable class GradientView: UIView {
    
    
    // 1
    let gradientLayer = CAGradientLayer()
    
    // 2
    @IBInspectable var startColor: UIColor = UIColor.blackColor() {
        didSet {
            gradientSetup()
        }
    }
    
    // 3
    @IBInspectable var midColor: UIColor = UIColor.blueColor() {
        didSet {
            gradientSetup()
        }
    }
    
    // 4
    @IBInspectable var endColor: UIColor = UIColor.whiteColor() {
        didSet {
            gradientSetup()
        }
    }
    
    // 5
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    // 6
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }
    
    // 7
    private func setup() {
        layer.addSublayer(gradientLayer)
        gradientSetup()
    }
    
    // 8
    func gradientSetup() {
        
        //let tmpColor = UIColor.yellowColor()
        
        gradientLayer.colors = [startColor.CGColor, midColor.CGColor, endColor.CGColor]
        gradientLayer.startPoint = CGPointMake(0.5, 0.0)
        gradientLayer.endPoint = CGPointMake(0.5, 1.0)
        
        
        gradientLayer.locations = [0, 0.5, 1]
        
    }
    
    // 9
    override func layoutSubviews() {
        gradientLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))
    }
    
}
