//
//  CVCellNib.swift
//  Shiners
//
//  Created by Вячеслав on 8/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class CVCellNib: UICollectionViewCell {

    
    @IBOutlet weak var imgPostCategory: UIImageView!
    @IBOutlet weak var txtlabelPostCategory: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    /*convenience override init(frame: CGRect) {
        self.init(frame: frame)
        var blurEffect: UIVisualEffect
        blurEffect = UIBlurEffect(style: .Light)
        var visualEffectView: UIVisualEffectView
        visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = self.maskView!.bounds
        self.addSubview(visualEffectView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.maskView!.frame = self.contentView.bounds
    }*/

}