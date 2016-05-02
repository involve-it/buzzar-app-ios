//
//  SmallImageView.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class SmallImageView: UIView{
    
    public weak var imageView: UIImageView!
    public weak var btnDelete: UIButton!
    
    public static let width: CGFloat = 100
    public static let height: CGFloat = 100
    
    public var id: Int?
    public var delegate: SmallImageViewDelegate?
    
    public init (x: Float, y: Float, id: Int, delegate: SmallImageViewDelegate?, image: UIImage){
        //todo: fix different aspect ratios
        self.id = id
        self.delegate = delegate
        
        super.init(frame: CGRectMake(CGFloat(x), CGFloat(y), SmallImageView.width, SmallImageView.height))
        self.clipsToBounds = true
        
        let imageView = UIImageView(frame: CGRectMake(0, 0, SmallImageView.width, SmallImageView.height))
        imageView.contentMode = .ScaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = image
        self.addSubview(imageView)
        self.imageView = imageView;
        
        let btnDelete = UIButton(frame: CGRectMake(CGFloat(SmallImageView.width - 22), CGFloat(y + 2), 20, 20))
        btnDelete.setBackgroundImage(UIImage(named: "cancel.png"), forState: .Normal)
        btnDelete.addTarget(self, action: #selector(btnDelete_Click), forControlEvents: .TouchUpInside)
        btnDelete.layer.shadowColor = UIColor.whiteColor().CGColor
        btnDelete.layer.shadowOpacity = 0.8
        btnDelete.layer.shadowRadius = 1
        btnDelete.layer.shadowOffset = CGSizeMake(-2, 2)
        self.addSubview(btnDelete)
        self.btnDelete = btnDelete
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func btnDelete_Click(sender: AnyObject) {
        self.delegate?.deleteClicked(self)
    }
}

public protocol SmallImageViewDelegate{
    func deleteClicked(view: SmallImageView)
}