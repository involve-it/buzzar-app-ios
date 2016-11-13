//
//  PhotosViewController.swift
//  Shiners
//
//  Created by Вячеслав on 7/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

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
        self.imagePickerHandler?.displayImagePicker()
    }
    
    //Create post
    @IBAction func createPost(sender: AnyObject) {
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
        view.displayLoading(true)
        self.uploadingIds.append(view.id)
        
        ImageCachingHandler.Instance.saveImage(rotatedImage) { (success, imageUrl) in
            if let index = self.uploadingIds.indexOf(view.id){
                ThreadHelper.runOnMainThread({
                    //self.setLoading(false, rightBarButtonItem: self.cancelButton)
                    //self.btnSave.enabled = true
                    
                    view.displayLoading(false)
                    if success {
                        let photo = Photo()
                        photo.original = imageUrl
                        self.post.photos!.append(photo)
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert, Error"), message: NSLocalizedString("Error uploading photo", comment: "Alert, error message uploading photo"));
                        self.deleteClicked(view)
                    }
                    
                    self.uploadingIds.removeAtIndex(index)
                    self.updateCreateButton()
                })
            }
        }
        
        picker.dismissViewControllerAnimated(true, completion: nil)
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
        if let index = self.uploadingIds.indexOf(smallImageView.id!){
            self.uploadingIds.removeAtIndex(index)
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
}
