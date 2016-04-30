//
//  ImagesScrollViewDelegate.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class ImagesScrollViewDelegate: NSObject, UIScrollViewDelegate{
    private let mainView: UIView;
    private let scrollView: UIScrollView;
    
    public init(mainView: UIView, scrollView: UIScrollView){
        self.mainView = mainView;
        self.scrollView = scrollView;
        super.init();
        self.scrollView.delegate = self;
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    }
    
    
    public func setupScrollView(ids: [String]?) {
        //svImages.frame = CGRectMake(0, 0, self.view.frame.size.width, 260)
        var index = 0;
        if let imageIds = ids{
            if (imageIds.count > 0){
                for imageId in imageIds{
                    self.addImageToScrollView(imageId, index: index)
                    index+=1;
                }
            } else {
                index+=1;
                self.addImageToScrollView(nil, index: 0)
            }
        } else {
            index+=1;
            self.addImageToScrollView(nil, index: 0)
        }
        
        scrollView.contentSize = CGSizeMake(mainView.frame.size.width * CGFloat(index), scrollView.frame.size.height);
    }
    
    private func addImageToScrollView(id: String?, index: Int){
        let imageView = UIImageView(frame: CGRectMake( CGFloat(index) * mainView.frame.size.width, 0, mainView.frame.size.width, scrollView.frame.size.height));
        imageView.contentMode = .ScaleAspectFit;
        imageView.clipsToBounds = true;
        if let imageId = id{
            let loading = ImageCachingHandler.Instance.getImage(imageId, callback: { (image) in
                dispatch_async(dispatch_get_main_queue(), {
                    imageView.image = image;
                })
            })
            if loading{
                imageView.image = ImageCachingHandler.defaultImage;
            }
            
        } else {
            imageView.image = ImageCachingHandler.defaultImage;
        }
        scrollView.addSubview(imageView);
    }

    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let x = scrollView.contentOffset.x;
        let currentPosition = x / mainView.frame.size.width;
        var position: Int;
        if (velocity.x == 0){
            position = Int(round(currentPosition));
        } else if (abs(velocity.x) < 0.4){
            if floor(currentPosition) == round(currentPosition) {
                position = Int(round(currentPosition))
            } else {
                position = Int(round(currentPosition)) + 1
            }
        } else {
            if (velocity.x > 0){
                position = Int(currentPosition) + 1
            } else {
                position = Int(currentPosition)
            }
        }
        
        targetContentOffset.memory = CGPointMake(CGFloat(position) * mainView.frame.size.width, 0);
    }
}