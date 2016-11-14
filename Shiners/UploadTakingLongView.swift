//
//  UploadTakingLongView.swift
//  Shiners
//
//  Created by Yury Dorofeev on 11/13/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit


class UploadTakingLongView: UIView{
    
    @IBOutlet weak var swButtons: UIStackView!
    @IBOutlet weak var btnUploadLowerQuality: UIButton!
    @IBOutlet weak var btnRetry: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var lblMessage: UILabel!
    
    func setupSubviews(){
        self.btnRetry.layer.cornerRadius = 4
        self.btnCancel.layer.cornerRadius = 4
        self.btnUploadLowerQuality.layer.cornerRadius = 4
        
        self.btnRetry.clipsToBounds = true
        self.btnCancel.clipsToBounds = true
        self.btnUploadLowerQuality.clipsToBounds = true
        
        if self.frame.size.width >= self.frame.size.height {
            self.swButtons.axis = .Horizontal
        } else {
            self.swButtons.axis = .Vertical
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}