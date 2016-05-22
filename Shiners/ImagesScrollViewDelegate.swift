//
//  ImagesScrollViewDelegate.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import NYTPhotoViewer

public class ImagesScrollViewDelegate: NSObject, UIScrollViewDelegate, NYTPhotosViewControllerDelegate{
    private let mainView: UIView
    private let scrollView: UIScrollView
    private let viewController: UIViewController
    
    private var photosViewController: NYTPhotosViewController?
    
    private var photos: [CustomPhoto] = []
    
    private var position = 0
    
    public init(mainView: UIView, scrollView: UIScrollView, viewController: UIViewController){
        self.mainView = mainView;
        self.scrollView = scrollView;
        self.viewController = viewController
        super.init();
        self.scrollView.delegate = self;
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    }
    
    
    public func setupScrollView(imageUrls: [String]?) {
        self.photos = []
        self.scrollView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        //let currentPosition = self.scrollView.contentOffset.x / scrollView.frame.size.width;
        
        //svImages.frame = CGRectMake(0, 0, self.view.frame.size.width, 260)
        var index = 0;
        if let urls = imageUrls{
            if (urls.count > 0){
                for url in urls{
                    self.addImageToScrollView(url, index: index)
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
        
        self.scrollToPosition(self.position)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        self.scrollView.addGestureRecognizer(gestureRecognizer)
    }
    
    private func addImageToScrollView(imageUrl: String?, index: Int){
        //add default - it will be updated later
        self.addPhoto(ImageCachingHandler.defaultImage!, index: index)
        
        let imageView = UIImageView(frame: CGRectMake( CGFloat(index) * mainView.frame.size.width, 0, mainView.frame.size.width, scrollView.frame.size.height));
        imageView.contentMode = .ScaleAspectFit;
        imageView.clipsToBounds = true;
        
        let loading = ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
            dispatch_async(dispatch_get_main_queue(), {
                imageView.image = image;
                self.updatePhoto(image!, index: index)
            })
        })
        if loading {
            imageView.image = ImageCachingHandler.defaultImage;
        }
        
        scrollView.addSubview(imageView);
    }
    
    private func addPhoto(image: UIImage, index: Int){
        let title = NSAttributedString(string: "Photo \(index + 1)", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        self.photos.append(CustomPhoto(image: image, attributedCaptionTitle: title))
    }
    
    private func updatePhoto(image: UIImage, index: Int){
        let photo = self.photos[index]
        photo.image = image
        
        self.photosViewController?.updateImageForPhoto(photo)
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let x = scrollView.contentOffset.x;
        let currentPosition = x / mainView.frame.size.width;
        //var position: Int;
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
    
    func scrollToPosition(position: Int){
        self.scrollView.contentOffset = CGPoint(x: CGFloat(position) * mainView.frame.size.width, y: 0)
    }
    
    public func photosViewController(photosViewController: NYTPhotosViewController, loadingViewForPhoto photo: NYTPhoto) -> UIView? {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.startAnimating()
        return activityIndicator
    }
    
    func scrollViewTapped(gestureRecognizer: UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Recognized {
            let point = gestureRecognizer.locationInView(self.scrollView)
            let imageIndex = Int(floor(point.x / self.mainView.frame.width))
            
            self.showPhotoViewer(imageIndex)
        }
    }
    
    func showPhotoViewer(currentIndex: Int){
        self.photosViewController = NYTPhotosViewController(photos: self.photos, initialPhoto: self.photos[currentIndex], delegate: self)
        self.photosViewController?.rightBarButtonItem = nil
        self.viewController.presentViewController(self.photosViewController!, animated: true, completion: nil)
    }
}