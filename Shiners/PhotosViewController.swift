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
    fileprivate let BTN_TO_MOVE: CGFloat = 68
    var buttonUp = false
    fileprivate var imagePickerHandler: ImagePickerHandler?
    fileprivate var images = [UIImage]()
    
    var uploadingIds = [String]()
    var retryingIds = [String]()
    
    var currentLocationInfo: GeocoderInfo?
    var editingPost = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.editingPost {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.svImages.isHidden = true;
        self.lblNoImages.isHidden = false;
        
        self.imagePickerHandler = ImagePickerHandler(viewController: self, delegate: self)
        if self.post.photos == nil {
            self.post.photos = [Photo]()
        } else {
            self.showExistingPhotos()
        }
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        self.svImages.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.NewPost_Photo)
    }
    
    func scrollViewTapped(_ gestureRecognizer: UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.recognized && self.images.count > 0 {
            let point = gestureRecognizer.location(in: self.svImages)
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
        self.images.removeAll()
        self.post.photos!.forEach { (photo) in
            ImageCachingHandler.Instance.getImageFromUrl(photo.original!, callback: { (image) in
                ThreadHelper.runOnMainThread({
                    self.images.append(image!)
                    let view = self.addImageToScrollView(image!, index: index)
                    view.imageUrl = photo.original
                    index += 1
                })
            })
        }
    }
    
    //Actions
    @IBAction func addImages(_ sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_AddPhoto_Click)
        self.imagePickerHandler?.displayImagePicker()
    }
    
    //Create post
    @IBAction func createPost(_ sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_BtnCreate_Click)
        if !self.isNetworkReachable(){
            return
        }
        self.doCreatePost()
    }
    
    func doCreatePost(){
        self.setLoading(true)
        if ConnectionHandler.Instance.isNetworkConnected() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            let callback: MeteorMethodCallback = { (success, errorId, errorMessage, result) in
                ThreadHelper.runOnMainThread({ 
                    self.setLoading(false, rightBarButtonItem: self.createPost)
                })
                if success{
                    AccountHandler.Instance.updateMyPosts()
                    ThreadHelper.runOnMainThread({
                        self.view.endEditing(true)
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    })
                    if let id = result as? String {
                        self.post.id = id
                        NotificationManager.sendNotification(.NearbyPostsUpdated, object: nil)
                    }
                } else {
                    ThreadHelper.runOnMainThread({
                        self.showAlert(NSLocalizedString("Error occurred", comment: "Alert, error occurred"), message: errorMessage)
                    })
                }
            }
            
            //Add post
            ConnectionHandler.Instance.posts.addPost(post, currentCoordinates: self.currentLocationInfo?.coordinate, callback: callback)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(doCreatePost), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.setLoading(true)
        
        let rotatedImage = image.correctlyOrientedImage().resizeImage()
        self.images.append(rotatedImage)
        let view = self.addImageToScrollView(rotatedImage, index: self.images.count - 1)
        self.doUpload(view)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func doUpload(_ view: SmallImageView){
        view.displayLoading(true)
        self.uploadingIds.append(view.id)
        
        view.uploadDelegate = ImageCachingHandler.Instance.saveImage(view.image) { (success, imageUrl) in
            ThreadHelper.runOnMainThread({
                if let index = self.uploadingIds.index(of: view.id){
                    //self.setLoading(false, rightBarButtonItem: self.cancelButton)
                    //self.btnSave.enabled = true
                    
                    if success {
                        view.activityIndicator.stopAnimating()
                        view.displayLoading(false)
                        let photo = Photo()
                        photo.original = imageUrl
                        self.post.photos!.append(photo)
                        view.imageUrl = imageUrl
                        self.uploadingIds.remove(at: index)
                        if let retryIndex = self.retryingIds.index(of: view.id){
                            self.retryingIds.remove(at: retryIndex)
                        }
                    } else {
                        if self.retryingIds.index(of: view.id) == nil {
                            self.showAlert(NSLocalizedString("Error", comment: "Alert, Error"), message: NSLocalizedString("Error uploading photo", comment: "Alert, error message uploading photo"));
                            self.deleteClicked(view)
                        }
                    }
                    
                    self.updateCreateButton()
                } else {
                    let globalY = self.calculateImagesHeight(self.images.count - 1)
                    self.svImages.contentSize = CGSize(width: self.svImages.frame.size.width, height: CGFloat(globalY));
                }
            })
        }
        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(displayUploadingLongTime), userInfo: view, repeats: false)
    }
    
    func updateCreateButton(){
        if self.uploadingIds.count == 0{
            if self.editingPost{
                self.setLoading(false)
            } else {
                self.setLoading(false, rightBarButtonItem: self.createPost)
            }
        } else {
            self.setLoading(true)
        }
    }
    
    func addImageToScrollView(_ image: UIImage, index: Int) -> SmallImageView {
        if (self.svImages.isHidden){
            self.svImages.isHidden = false
            self.lblNoImages.isHidden = true
        }
        
        var y = self.calculateImagesHeight(index)
        let view = SmallImageView(x: 8, y: y, index: index, delegate: self, image: image)
        view.alpha = 0
        
        UIView.animate(withDuration: 0.7, animations: { 
            view.alpha = 1
        }) 
        
        self.svImages.addSubview(view)
        y = self.calculateImagesHeight(index + 1)
        
        self.svImages.contentSize = CGSize(width: self.svImages.frame.size.width, height: CGFloat(y));
        self.svImages.layoutSubviews()
        
        self.svImages.scrollRectToVisible(CGRect(x: self.svImages.contentSize.width - 1, y: self.svImages.contentSize.height - 1, width: 1, height: 1), animated: true)
        
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
    
    func displayUploadingLongTime(_ timer: Timer){
        if let view = timer.userInfo as? SmallImageView, self.uploadingIds.index(of: view.id) != nil {
            view.initControlButtons()
        }
    }
    
    func calculateImagesHeight(_ count: Int) -> Float {
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
    
    func deleteClicked(_ smallImageView: SmallImageView) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_Photo_Remove)
        if let index = self.uploadingIds.index(of: smallImageView.id!){
            self.uploadingIds.remove(at: index)
            smallImageView.uploadDelegate?.abort()
        }
        if let imageUrl = smallImageView.imageUrl, let index = self.post.photos!.index(where: {$0.original == imageUrl}) {
            self.post.photos!.remove(at: index)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            smallImageView.alpha = 0
            }, completion: { (finished) in
                self.images.remove(at: smallImageView.index!)
                if let index = self.svImages.subviews.index(of: smallImageView){
                    smallImageView.removeFromSuperview()
                    var i = 0
                    self.svImages.subviews.forEach({ (view) in
                        if let sView = view as? SmallImageView {
                            if i >= index - 1 {
                                sView.index = i
                                let y = self.calculateImagesHeight(i)
                                UIView.animate(withDuration: 0.3, animations: { 
                                    sView.frame = CGRect(x: CGFloat(8), y: CGFloat(y), width: sView.frame.width + 20, height: sView.frame.height + 10)
                                    self.svImages.layoutSubviews()
                                }, completion: { (finished) in
                                    if i == self.svImages.subviews.count - 1 {
                                        let globalY = self.calculateImagesHeight(i)
                                        self.svImages.contentSize = CGSize(width: self.svImages.frame.size.width, height: CGFloat(globalY));
                                    }
                                }) 
                            }
                            i += 1
                        }
                    })
                }
                if self.images.count == 0 {
                    self.svImages.isHidden = true
                    self.lblNoImages.isHidden = false
                }
                self.updateCreateButton()
            }) 
    }
    
    func retryClicked(_ view: SmallImageView) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_Photo_Retry)
        if let index = self.uploadingIds.index(of: view.id!){
            self.uploadingIds.remove(at: index)
            self.retryingIds.append(view.id!)
            view.uploadDelegate?.abort()
            view.hideLongUploadControls()
        }
        self.doUpload(view)
    }
    
    func uploadWithLowerQualityClicked(_ view: SmallImageView) {
        AppAnalytics.logEvent(.NewPostWizard_PhotoStep_Photo_LowerQual)
        if !view.isLowerQualityUpload {
            view.isLowerQualityUpload = true
            if let index = self.uploadingIds.index(of: view.id!){
                self.uploadingIds.remove(at: index)
                self.retryingIds.append(view.id!)
                view.uploadDelegate?.abort()
                view.hideLongUploadControls()
            }
            view.image = view.image.resizeImage(320, maxHeight: 320, quality: 0.5)
            self.doUpload(view)
        }
    }
    
    func showPhotoViewer(_ currentIndex: Int){
        var photos = [CustomPhoto]()
        var i = 0
        self.images.forEach { (image) in
            photos.append(CustomPhoto(image: image, attributedCaptionTitle: NSAttributedString(string: "\(i + 1)", attributes: [NSForegroundColorAttributeName: UIColor.white])))
            i += 1
        }
        let photosViewController = NYTPhotosViewController(photos: photos, initialPhoto: photos[currentIndex], delegate: nil)
        photosViewController.rightBarButtonItem = nil
        self.present(photosViewController, animated: true, completion: nil)
    }
}
