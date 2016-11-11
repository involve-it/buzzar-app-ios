//
//  cellPage.swift
//  Shiners
//
//  Created by Вячеслав on 07/11/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit


class cellPage: UICollectionViewCell {
    
    var page: Page? {
        didSet {
            guard let page = page else {return}
            
            imageView.image = UIImage(named: page.imageName)
            
            let titleColor = UIColor(netHex: 0x4EB2F4)
            let textColor = UIColor(white: 0.4, alpha: 1)
            let attributedText = NSMutableAttributedString(string: page.title, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(20, weight: UIFontWeightRegular), NSForegroundColorAttributeName: titleColor])
            attributedText.appendAttributedString(NSAttributedString(string: "\n\n\(page.message)", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: textColor]))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .Center
            
            let length = attributedText.string.characters.count
            attributedText.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(location: 0, length: length))
            
            textView.attributedText = attributedText
        }
    }
    
    let modelName = UIDevice.currentDevice().modelName
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .ScaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.blackColor()
        return iv
        
    }()
    
    let separatorLineView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor(white: 0.9, alpha: 1)
        return line
    }()
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.editable = false
        tv.contentInset = UIEdgeInsets(top: 18, left: 0, bottom: 0, right: 0)
        return tv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCell() {
        //Configure cell
        
        addSubview(imageView)
        addSubview(separatorLineView)
        addSubview(textView)
        
        imageView.anchorToTop(topAnchor, left: leftAnchor, bottom: textView.topAnchor, right: rightAnchor)
  
        let multiplierId: CGFloat = (modelName == "iPhone 4s" || modelName == "iPhone 4") ? 0.4 : 0.3
        
        textView.anchorWithConstantsToTop(nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, topConstant: 0, leftConstant: 16, bottomConstant: 0, rightConstant: 16)
        textView.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: multiplierId).active = true
        
        separatorLineView.anchorToTop(nil, left: leftAnchor, bottom: textView.topAnchor, right: rightAnchor)
        separatorLineView.heightAnchor.constraintEqualToConstant(1).active = true
    }
}