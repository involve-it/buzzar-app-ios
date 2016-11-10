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
    public static let height: CGFloat = 80
    
    private(set) public var id: String!
    public var index: Int?
    public var delegate: SmallImageViewDelegate?
    
    let activityIndicator = UIActivityIndicatorView()
    let coverImageView: UIView = UIView()
    
    public init (x: Float, y : Float, index:Int, delegate: SmallImageViewDelegate?, image: UIImage){
        //todo: fix different aspect ratios
        self.id = NSUUID().UUIDString
        self.index = index
        self.delegate = delegate
        
        //extension of the edges + 20
        super.init(frame: CGRectMake(CGFloat(x), CGFloat(y), SmallImageView.width + 20, SmallImageView.height + 10))
        self.clipsToBounds = true
        
        let imageView = UIImageView(frame: CGRectMake(0, 10, SmallImageView.width, SmallImageView.height))
        imageView.contentMode = .ScaleAspectFill
        
        imageView.layer.cornerRadius = CGFloat(4)
        imageView.backgroundColor = UIColor.blackColor()
        
        imageView.clipsToBounds = true
        imageView.image = image
        self.addSubview(imageView)
        self.imageView = imageView
        
        //Indicator & coverView
        self.coverImageView.backgroundColor = UIColor(white: 0.1, alpha: 0.75)
        self.coverImageView.frame = CGRectMake(0, 0, self.frame.width, self.frame.width)
        
        activityIndicator.center = imageView.center
        activityIndicator.activityIndicatorViewStyle = .White
        activityIndicator.hidesWhenStopped = true
        //activityIndicator.startAnimating()
        //self.imageView.addSubview(coverImageView)
        self.addSubview(activityIndicator)
        
        let btnDelete = UIButton(frame: CGRectMake(CGFloat(SmallImageView.width - 12), CGFloat(y - 4), 17, 17))
        btnDelete.setBackgroundImage(UIImage(named: "deleteImage"), forState: .Normal)
        btnDelete.addTarget(self, action: #selector(btnDelete_Click), forControlEvents: .TouchUpInside)
        
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