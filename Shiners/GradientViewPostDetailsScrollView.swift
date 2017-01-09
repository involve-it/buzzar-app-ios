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
    @IBInspectable var startColor: UIColor = UIColor.black {
        didSet {
            gradientSetup()
        }
    }
    
    // 3
    @IBInspectable var midColor: UIColor = UIColor.blue {
        didSet {
            gradientSetup()
        }
    }
    
    // 4
    @IBInspectable var endColor: UIColor = UIColor.white {
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
    fileprivate func setup() {
        layer.addSublayer(gradientLayer)
        gradientSetup()
    }
    
    // 8
    func gradientSetup() {
        
        //let tmpColor = UIColor.yellowColor()
        
        gradientLayer.colors = [startColor.cgColor, midColor.cgColor, endColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        
        gradientLayer.locations = [0, 0.5, 1]
        
    }
    
    // 9
    override func layoutSubviews() {
        gradientLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
    }
    
}
