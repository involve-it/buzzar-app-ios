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
    
    public var width: CGFloat!
    public var height: CGFloat!
    
    private(set) public var id: String!
    public var index: Int?
    public var delegate: SmallImageViewDelegate?
    
    let activityIndicator = UIActivityIndicatorView()
    let coverImageView: UIView = UIView()
    
    var uploadTakingLongView: UploadTakingLongView?
    public var imageUrl: String?
    public var image: UIImage!
    
    var uploadDelegate: ImageCachingHandler.UploadDelegate?
    
    public init (x: Float, y : Float, index:Int, delegate: SmallImageViewDelegate?, image: UIImage){
        //todo: fix different aspect ratios
        self.width = UIScreen.mainScreen().bounds.width - 16
        
        self.height = max(60, self.width * (image.size.height / image.size.width))
        self.image = image
        self.id = NSUUID().UUIDString
        self.index = index
        self.delegate = delegate
        
        //extension of the edges + 20
        super.init(frame: CGRectMake(CGFloat(x), CGFloat(y), self.width + 20, self.height + 10))
        self.clipsToBounds = true
        
        let imageView = UIImageView(frame: CGRectMake(0, 10, self.width, self.height))
        imageView.contentMode = .ScaleAspectFill
        
        imageView.layer.cornerRadius = CGFloat(4)
        imageView.backgroundColor = UIColor.blackColor()
        
        imageView.clipsToBounds = true
        imageView.image = image
        self.addSubview(imageView)
        self.imageView = imageView
        
        //Indicator & coverView
        self.coverImageView.backgroundColor = UIColor(white: 0.1, alpha: 0.75)
        self.coverImageView.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
        self.coverImageView.alpha = 0
        
        activityIndicator.center = imageView.center
        activityIndicator.activityIndicatorViewStyle = .White
        activityIndicator.hidesWhenStopped = true
        //activityIndicator.startAnimating()
        //self.imageView.addSubview(coverImageView)
        
        //self.initControlButtons()
        
        self.addSubview(activityIndicator)
        
        
        let btnDelete = UIButton(frame: CGRectMake(CGFloat(self.width - 12), 0, 17, 17))
        btnDelete.setBackgroundImage(UIImage(named: "deleteImage"), forState: .Normal)
        btnDelete.addTarget(self, action: #selector(btnDelete_Click), forControlEvents: .TouchUpInside)
        
        self.addSubview(btnDelete)
        self.btnDelete = btnDelete
    }
    
    func initControlButtons(){
        let uploadTakingLongView = (NSBundle.mainBundle().loadNibNamed("UploadTakingLongView", owner: self, options: nil))[0] as! UploadTakingLongView
        uploadTakingLongView.frame = CGRectMake(0, 10, self.frame.width - 16, self.frame.height - 20)
        uploadTakingLongView.setupSubviews()
        uploadTakingLongView.btnCancel.addTarget(self, action: #selector(btnDelete_Click), forControlEvents: .TouchUpInside)
        uploadTakingLongView.btnRetry.addTarget(self, action: #selector(btnRetry_Click), forControlEvents: .TouchUpInside)
        uploadTakingLongView.btnUploadLowerQuality.addTarget(self, action: #selector(btnUploadWithLowerQuality_Click), forControlEvents: .TouchUpInside)
            //UploadTakingLongView(frame: self.coverImageView.frame)
        uploadTakingLongView.alpha = 0
        
        self.addSubview(uploadTakingLongView)
        self.uploadTakingLongView = uploadTakingLongView
        self.bringSubviewToFront(self.btnDelete)
        self.layoutSubviews()
        
        UIView.animateWithDuration(0.3, animations: {
            uploadTakingLongView.alpha = 1
            self.activityIndicator.center = CGPointMake(self.activityIndicator.center.x, 70)
        })
    }
    
    public func displayLongUploadControls(){
        self.initControlButtons()
    }
    
    public func hideLongUploadControls(){
        UIView.animateWithDuration(0.3, animations: {
            self.uploadTakingLongView?.alpha = 0
        }) {(finished) in
            self.uploadTakingLongView?.removeFromSuperview()
            self.uploadTakingLongView = nil
        }
    }
    
    public func displayLoading(loading: Bool){
        if loading {
            self.imageView.addSubview(self.coverImageView)
            //self.layer.removeAllAnimations()
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.animateWithDuration(0.3, animations: { 
                self.coverImageView.alpha = 1
                }, completion: { (finished) in
                    //temp
                    //self.initControlButtons()
            })
            self.activityIndicator.startAnimating()
        } else {
            UIView.animateWithDuration(0.3, animations: { 
                self.coverImageView.alpha = 0
            })
            self.hideLongUploadControls()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func btnDelete_Click(sender: AnyObject) {
        self.delegate?.deleteClicked(self)
    }
    
    func btnRetry_Click(sender: AnyObject){
        self.delegate?.retryClicked(self)
    }
    
    func btnUploadWithLowerQuality_Click(sender: AnyObject){
        self.delegate?.uploadWithLowerQualityClicked(self)
    }
}

public protocol SmallImageViewDelegate{
    func deleteClicked(view: SmallImageView)
    func retryClicked(view: SmallImageView)
    func uploadWithLowerQualityClicked(view: SmallImageView)
}