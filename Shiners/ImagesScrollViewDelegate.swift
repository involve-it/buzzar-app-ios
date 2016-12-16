//
//  ImagesScrollViewDelegate.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import NYTPhotoViewer

open class ImagesScrollViewDelegate: NSObject, UIScrollViewDelegate, NYTPhotosViewControllerDelegate{
    fileprivate let mainView: UIView
    fileprivate let scrollView: UIScrollView
    fileprivate let viewController: UIViewController
    fileprivate var photosViewController: NYTPhotosViewController?
    
    fileprivate var photos: [CustomPhoto] = []
    
    fileprivate var position = 0
    fileprivate let pageControl: UIPageControl?
    fileprivate var imagesCount = 0
    
    let addPhotoTitle = NSLocalizedString("Photo", comment: "Title, Photo")
    
    public init(mainView: UIView, scrollView: UIScrollView, viewController: UIViewController, pageControl: UIPageControl?){
        self.mainView = mainView;
        self.scrollView = scrollView;
        self.viewController = viewController
        self.pageControl = pageControl
        
        super.init();
        self.scrollView.delegate = self;
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    }
    
    
    open func setupScrollView(_ imageUrls: [String]?) {
        self.photos = []
        self.scrollView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        //let currentPosition = self.scrollView.contentOffset.x / scrollView.frame.size.width;
        
        //svImages.frame = CGRectMake(0, 0, self.view.frame.size.width, 260)
        var index = 0;
        if let urls = imageUrls{
            self.imagesCount = urls.count
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
        
        scrollView.contentSize = CGSize(width: mainView.frame.size.width * CGFloat(index), height: scrollView.frame.size.height);
        
        self.scrollToPosition(self.position)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        self.scrollView.addGestureRecognizer(gestureRecognizer)
        
        
    }
    


    fileprivate func addImageToScrollView(_ imageUrl: String?, index: Int){
        //add default - it will be updated later
        self.addPhoto(ImageCachingHandler.defaultPhoto!, index: index)
        
        let imageView = UIImageView(frame: CGRect( x: CGFloat(index) * mainView.frame.size.width, y: 0, width: mainView.frame.size.width, height: scrollView.frame.size.height));
        imageView.contentMode = .scaleAspectFill;
        imageView.clipsToBounds = true;
        
        let loading = ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
            DispatchQueue.main.async(execute: {
                imageView.image = image;
                self.updatePhoto(image!, index: index)
            })
        })
        if loading {
            imageView.image = ImageCachingHandler.defaultPhoto;
        }
        
        scrollView.addSubview(imageView);
    }
    
    fileprivate func addPhoto(_ image: UIImage, index: Int){
        let title = NSAttributedString(string: "\(addPhotoTitle) \(index + 1)", attributes: [NSForegroundColorAttributeName: UIColor.white])
        self.photos.append(CustomPhoto(image: image, attributedCaptionTitle: title))
    }
    
    fileprivate func updatePhoto(_ image: UIImage, index: Int){
        let photo = self.photos[index]
        photo.image = image
        
        self.photosViewController?.updateImage(for: photo)
    }
    
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
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
        targetContentOffset.pointee = CGPoint(x: CGFloat(position) * mainView.frame.size.width, y: 0);
        
        //Change currentPosition - pageControl
        self.pageControl?.currentPage = position
    }
    
    func scrollToPosition(_ position: Int){
        self.scrollView.contentOffset = CGPoint(x: CGFloat(position) * mainView.frame.size.width, y: 0)
    }
    
    open func photosViewController(_ photosViewController: NYTPhotosViewController, loadingViewFor photo: NYTPhoto) -> UIView? {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.startAnimating()
        return activityIndicator
    }
    
    func scrollViewTapped(_ gestureRecognizer: UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.recognized && self.imagesCount > 0 {
            let point = gestureRecognizer.location(in: self.scrollView)
            let imageIndex = Int(floor(point.x / self.mainView.frame.width))
            
            self.showPhotoViewer(imageIndex)
        }
    }
    
    func showPhotoViewer(_ currentIndex: Int){
        self.photosViewController = NYTPhotosViewController(photos: self.photos, initialPhoto: self.photos[currentIndex], delegate: self)
        self.photosViewController?.rightBarButtonItem = nil
        self.viewController.present(self.photosViewController!, animated: true, completion: nil)
    }
}
