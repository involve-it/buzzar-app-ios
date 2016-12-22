//
//  SmallImageView.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

open class SmallImageView: UIView{
    
    open weak var imageView: UIImageView!
    open weak var btnDelete: UIButton!
    
    open var width: CGFloat!
    open var height: CGFloat!
    
    fileprivate(set) open var id: String!
    open var latestUploadId: String?
    open var index: Int?
    open var delegate: SmallImageViewDelegate?
    
    let activityIndicator = UIActivityIndicatorView()
    let coverImageView: UIView = UIView()
    
    var uploadTakingLongView: UploadTakingLongView?
    open var imageUrl: String?
    open var image: UIImage!
    open var isLowerQualityUpload = false
    
    var uploadDelegate: ImageCachingHandler.UploadDelegate?
    
    public init (x: Float, y : Float, index:Int, delegate: SmallImageViewDelegate?, image: UIImage){
        //todo: fix different aspect ratios
        self.width = UIScreen.main.bounds.width - 16
        
        self.height = max(self.width / 2 - 10, self.width * (image.size.height / image.size.width))
        self.image = image
        self.id = UUID().uuidString
        self.index = index
        self.delegate = delegate
        
        //extension of the edges + 20
        super.init(frame: CGRect(x: CGFloat(x), y: CGFloat(y), width: self.width + 20, height: self.height + 10))
        self.clipsToBounds = true
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 8, width: self.width, height: self.height))
        imageView.contentMode = .scaleAspectFill
        
        imageView.layer.cornerRadius = CGFloat(4)
        imageView.backgroundColor = UIColor.black
        
        imageView.clipsToBounds = true
        imageView.image = image
        self.addSubview(imageView)
        self.imageView = imageView
        
        //Indicator & coverView
        self.coverImageView.backgroundColor = UIColor(white: 0.1, alpha: 0.75)
        self.coverImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.coverImageView.alpha = 0
        
        activityIndicator.center = imageView.center
        activityIndicator.activityIndicatorViewStyle = .white
        activityIndicator.hidesWhenStopped = true
        //activityIndicator.startAnimating()
        //self.imageView.addSubview(coverImageView)
        
        //self.initControlButtons()
        
        self.addSubview(activityIndicator)
        
        
        let btnDelete = UIButton(frame: CGRect(x: CGFloat(self.width - 12), y: 0, width: 17, height: 17))
        btnDelete.setBackgroundImage(UIImage(named: "deleteImage"), for: UIControlState())
        btnDelete.addTarget(self, action: #selector(btnDelete_Click), for: .touchUpInside)
        
        self.addSubview(btnDelete)
        self.btnDelete = btnDelete
    }
    
    func initControlButtons(){
        let uploadTakingLongView = (Bundle.main.loadNibNamed("UploadTakingLongView", owner: self, options: nil))?[0] as! UploadTakingLongView
        uploadTakingLongView.frame = CGRect(x: 0, y: 10, width: self.frame.width - 16, height: self.frame.height - 20)
        uploadTakingLongView.setupSubviews()
        uploadTakingLongView.btnCancel.addTarget(self, action: #selector(btnDelete_Click), for: .touchUpInside)
        uploadTakingLongView.btnRetry.addTarget(self, action: #selector(btnRetry_Click), for: .touchUpInside)
        if self.isLowerQualityUpload {
            uploadTakingLongView.btnUploadLowerQuality.removeFromSuperview()
        } else {
            uploadTakingLongView.btnUploadLowerQuality.addTarget(self, action: #selector(btnUploadWithLowerQuality_Click), for: .touchUpInside)
        }
            //UploadTakingLongView(frame: self.coverImageView.frame)
        uploadTakingLongView.alpha = 0
        
        self.addSubview(uploadTakingLongView)
        self.uploadTakingLongView = uploadTakingLongView
        self.bringSubview(toFront: self.btnDelete)
        self.layoutSubviews()
        
        UIView.animate(withDuration: 0.3, animations: {
            uploadTakingLongView.alpha = 1
            self.activityIndicator.center = CGPoint(x: self.activityIndicator.center.x, y: CGFloat(self.height) / 4 + 8)
        })
    }
    
    open func displayLongUploadControls(){
        self.initControlButtons()
    }
    
    open func hideLongUploadControls(){
        UIView.animate(withDuration: 0.3, animations: {
            self.uploadTakingLongView?.alpha = 0
        }, completion: {(finished) in
            self.uploadTakingLongView?.removeFromSuperview()
            self.uploadTakingLongView = nil
        }) 
    }
    
    open func displayLoading(_ loading: Bool){
        if loading {
            self.imageView.addSubview(self.coverImageView)
            //self.layer.removeAllAnimations()
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.animate(withDuration: 0.3, animations: { 
                self.coverImageView.alpha = 1
                self.activityIndicator.center = self.imageView.center
                }, completion: { (finished) in
                    //temp
                    //self.initControlButtons()
            })
            self.activityIndicator.startAnimating()
        } else {
            UIView.animate(withDuration: 0.3, animations: { 
                self.coverImageView.alpha = 0
            })
            self.hideLongUploadControls()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func btnDelete_Click(_ sender: AnyObject) {
        self.delegate?.deleteClicked(self)
    }
    
    func btnRetry_Click(_ sender: AnyObject){
        self.delegate?.retryClicked(self)
    }
    
    func btnUploadWithLowerQuality_Click(_ sender: AnyObject){
        self.delegate?.uploadWithLowerQualityClicked(self)
    }
}

public protocol SmallImageViewDelegate{
    func deleteClicked(_ view: SmallImageView)
    func retryClicked(_ view: SmallImageView)
    func uploadWithLowerQualityClicked(_ view: SmallImageView)
}
