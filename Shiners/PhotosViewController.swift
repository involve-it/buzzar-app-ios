//
//  PhotosViewController.swift
//  Shiners
//
//  Created by Вячеслав on 7/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import NYTPhotoViewer

class PhotosViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SmallImageViewDelegate {
    @IBOutlet weak var lblNoImages: UILabel!
    @IBOutlet weak var svImages: UIScrollView!
    @IBOutlet var createPost: UIBarButtonItem!
    
    var post: Post!
    
    @IBOutlet weak var constraintSvImagesTop: NSLayoutConstraint!
    @IBOutlet weak var constraintAddPhotoButtonTop: NSLayoutConstraint!
    private let BTN_TO_MOVE: CGFloat = 68
    var buttonUp = false
    private var imagePickerHandler: ImagePickerHandler?
    private var images = [UIImage]()
    
    var uploadingIds = [String]()
    var retryingIds = [String]()
    
    var currentLocationInfo: GeocoderInfo?
    
    override func viewDidLoad() {
        self.svImages.hidden = true;
        self.lblNoImages.hidden = false;
        
        self.imagePickerHandler = ImagePickerHandler(viewController: self, delegate: self)
        if self.post.photos == nil {
            self.post.photos = [Photo]()
        } else {
            self.showExistingPhotos()
        }
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        self.svImages.addGestureRecognizer(gestureRecognizer)
    }
    
    func scrollViewTapped(gestureRecognizer: UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Recognized && self.images.count > 0 {
            let point = gestureRecognizer.locationInView(self.svImages)
            var index = 0
            var currentHeight:Float = 0
            
            for view in self.svImages.subviews {
                if let smallImageView = view as? SmallImageView {
                    currentHeight += Float(smallImageView.height)
                    if Float(point.y) < currentHeight {
                        break
                    }
                    
                    index += 1
                }
            }
            if index < self.images.count {
                self.showPhotoViewer(index)
            }
        }
    }
    
    func showExistingPhotos(){
        var index = 0
        self.post.photos!.forEach { (photo) in
            ImageCachingHandler.Instance.getImageFromUrl(photo.original!, callback: { (image) in
                ThreadHelper.runOnMainThread({ 
                    self.addImageToScrollView(image!, index: index)
                    index += 1
                })
            })
        }
    }
    
    //Actions
    @IBAction func addImages(sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_AddPhoto_Click)
        self.imagePickerHandler?.displayImagePicker()
    }
    
    //Create post
    @IBAction func createPost(sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_BtnCreate_Click)
        if !self.isNetworkReachable(){
            return
        }
        self.doCreatePost()
    }
    
    func doCreatePost(){
        self.setLoading(true)
        if ConnectionHandler.Instance.status == .Connected {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            let callback: MeteorMethodCallback = { (success, errorId, errorMessage, result) in
                ThreadHelper.runOnMainThread({ 
                    self.setLoading(false, rightBarButtonItem: self.createPost)
                })
                if success{
                    AccountHandler.Instance.updateMyPosts()
                    ThreadHelper.runOnMainThread({
                        self.view.endEditing(true)
                        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                    })
                } else {
                    ThreadHelper.runOnMainThread({
                        self.showAlert(NSLocalizedString("Error occurred", comment: "Alert, error occurred"), message: errorMessage)
                    })
                }
            }
            
            //Add post
            ConnectionHandler.Instance.posts.addPost(post, currentCoordinates: self.currentLocationInfo?.coordinate, callback: callback)
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(doCreatePost), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        }
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.setLoading(true)
        
        let rotatedImage = image.correctlyOrientedImage().resizeImage()
        self.images.append(rotatedImage)
        let view = self.addImageToScrollView(rotatedImage, index: self.images.count - 1)
        self.doUpload(view)
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func doUpload(view: SmallImageView){
        view.displayLoading(true)
        self.uploadingIds.append(view.id)
        
        view.uploadDelegate = ImageCachingHandler.Instance.saveImage(view.image) { (success, imageUrl) in
            ThreadHelper.runOnMainThread({
                if let index = self.uploadingIds.indexOf(view.id){
                    //self.setLoading(false, rightBarButtonItem: self.cancelButton)
                    //self.btnSave.enabled = true
                    
                    if success {
                        view.activityIndicator.stopAnimating()
                        view.displayLoading(false)
                        let photo = Photo()
                        photo.original = imageUrl
                        self.post.photos!.append(photo)
                        view.imageUrl = imageUrl
                        self.uploadingIds.removeAtIndex(index)
                        if let retryIndex = self.retryingIds.indexOf(view.id){
                            self.retryingIds.removeAtIndex(retryIndex)
                        }
                    } else {
                        if self.retryingIds.indexOf(view.id) == nil {
                            self.showAlert(NSLocalizedString("Error", comment: "Alert, Error"), message: NSLocalizedString("Error uploading photo", comment: "Alert, error message uploading photo"));
                            self.deleteClicked(view)
                        }
                    }
                    
                    self.updateCreateButton()
                } else {
                    let globalY = self.calculateImagesHeight(self.images.count - 1)
                    self.svImages.contentSize = CGSizeMake(self.svImages.frame.size.width, CGFloat(globalY));
                }
            })
        }
        NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(displayUploadingLongTime), userInfo: view, repeats: false)
    }
    
    func updateCreateButton(){
        if self.uploadingIds.count == 0{
            self.setLoading(false, rightBarButtonItem: self.createPost)
        } else {
            self.setLoading(true)
        }
    }
    
    func addImageToScrollView(image: UIImage, index: Int) -> SmallImageView {
        if (self.svImages.hidden){
            self.svImages.hidden = false
            self.lblNoImages.hidden = true
        }
        
        var y = self.calculateImagesHeight(index)
        let view = SmallImageView(x: 8, y: y, index: index, delegate: self, image: image)
        view.alpha = 0
        
        UIView.animateWithDuration(0.7) { 
            view.alpha = 1
        }
        
        self.svImages.addSubview(view)
        y = self.calculateImagesHeight(index + 1)
        
        self.svImages.contentSize = CGSizeMake(self.svImages.frame.size.width, CGFloat(y));
        self.svImages.layoutSubviews()
        
        self.svImages.scrollRectToVisible(CGRectMake(self.svImages.contentSize.width - 1, self.svImages.contentSize.height - 1, 1, 1), animated: true)
        
        return view
    }
    
    /*func redrawImagesScrollView(){
        self.svImages.subviews.forEach({ (view) in
            view.removeFromSuperview()
        })
        
        var index = 0
        self.images.forEach { (image) in
            self.addImageToScrollView(image, index: index)
            index += 1
        }
    }*/
    
    func displayUploadingLongTime(timer: NSTimer){
        if let view = timer.userInfo as? SmallImageView where self.uploadingIds.indexOf(view.id) != nil {
            view.initControlButtons()
        }
    }
    
    func calculateImagesHeight(count: Int) -> Float {
        var height: Float = 8
        var i = 0
        self.svImages.subviews.forEach { (view) in
            if i < count, let smallImageView = view as? SmallImageView {
                height += Float(smallImageView.height + 16)
                i += 1
            }
        }
        /*for i in 0...count {
            if self.svImages.subviews.count > i, let smallImageView = self.svImages.subviews[i] as? SmallImageView {
                height += Float(smallImageView.height + 16)
            }
        }*/
        /*self.svImages.subviews.forEach { (view) in
            if let smallImageView = view as? SmallImageView {
                height += Float(smallImageView.height + 16)
            }
        }*/
        //return (8 + Float(count) * Float(SmallImageView.height + 16))
        return height
    }
    
    func deleteClicked(smallImageView: SmallImageView) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_Photo_BtnRemove_Click)
        if let index = self.uploadingIds.indexOf(smallImageView.id!){
            self.uploadingIds.removeAtIndex(index)
            smallImageView.uploadDelegate?.abort()
        }
        if let imageUrl = smallImageView.imageUrl, index = self.post.photos!.indexOf({$0.original == imageUrl}) {
            self.post.photos!.removeAtIndex(index)
        }
        
        UIView.animateWithDuration(0.3, animations: {
            smallImageView.alpha = 0
            }) { (finished) in
                self.images.removeAtIndex(smallImageView.index!)
                if let index = self.svImages.subviews.indexOf(smallImageView){
                    smallImageView.removeFromSuperview()
                    var i = 0
                    self.svImages.subviews.forEach({ (view) in
                        if let sView = view as? SmallImageView {
                            if i >= index {
                                sView.index = i
                                let y = self.calculateImagesHeight(i)
                                UIView.animateWithDuration(0.3, animations: { 
                                    sView.frame = CGRectMake(CGFloat(8), CGFloat(y), sView.frame.width + 20, sView.frame.height + 10)
                                    self.svImages.layoutSubviews()
                                }) { (finished) in
                                    if i == self.svImages.subviews.count - 1 {
                                        let globalY = self.calculateImagesHeight(i)
                                        self.svImages.contentSize = CGSizeMake(self.svImages.frame.size.width, CGFloat(globalY));
                                    }
                                }
                            }
                            i += 1
                        }
                    })
                }
                if self.images.count == 0{
                    self.svImages.hidden = true
                    self.lblNoImages.hidden = false
                }
                self.updateCreateButton()
            }
    }
    
    func retryClicked(view: SmallImageView) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_Photo_BtnRetry_Click)
        if let index = self.uploadingIds.indexOf(view.id!){
            self.uploadingIds.removeAtIndex(index)
            self.retryingIds.append(view.id!)
            view.uploadDelegate?.abort()
            view.hideLongUploadControls()
        }
        self.doUpload(view)
    }
    
    func uploadWithLowerQualityClicked(view: SmallImageView) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_Photo_BtnLowerQuality_Click)
        if !view.isLowerQualityUpload {
            view.isLowerQualityUpload = true
            if let index = self.uploadingIds.indexOf(view.id!){
                self.uploadingIds.removeAtIndex(index)
                self.retryingIds.append(view.id!)
                view.uploadDelegate?.abort()
                view.hideLongUploadControls()
            }
            view.image = view.image.resizeImage(320, maxHeight: 320, quality: 0.5)
            self.doUpload(view)
        }
    }
    
    func showPhotoViewer(currentIndex: Int){
        var photos = [CustomPhoto]()
        var i = 0
        self.images.forEach { (image) in
            photos.append(CustomPhoto(image: image, attributedCaptionTitle: NSAttributedString(string: "\(i + 1)", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])))
            i += 1
        }
        let photosViewController = NYTPhotosViewController(photos: photos, initialPhoto: photos[currentIndex], delegate: nil)
        photosViewController.rightBarButtonItem = nil
        self.presentViewController(photosViewController, animated: true, completion: nil)
    }
}
