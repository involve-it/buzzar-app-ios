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
    
    private var imagePickerHandler: ImagePickerHandler?
    private var images = [UIImage]()
    
    var uploadingIds = [Int]()
    
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
        let callback: MeteorMethodCallback = { (success, errorId, errorMessage, result) in
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
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.setLoading(true)
        
        let rotatedImage = image.correctlyOrientedImage().resizeImage()
        self.images.append(rotatedImage)
        let id = self.images.count - 1
        let view = self.addImageToScrollView(rotatedImage, index: id)
        view.imageView.addSubview(view.coverImageView)
        view.activityIndicator.startAnimating()
        self.uploadingIds.append(id)
        
        ImageCachingHandler.Instance.saveImage(rotatedImage) { (success, imageUrl) in
            if let index = self.uploadingIds.indexOf(id){
                ThreadHelper.runOnMainThread({
                    //self.setLoading(false, rightBarButtonItem: self.cancelButton)
                    //self.btnSave.enabled = true
                    
                    view.coverImageView.removeFromSuperview()
                    view.activityIndicator.stopAnimating()
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
        
        var x = self.calculateImagesWidth(index)
        let view = SmallImageView(x: x, y: 8, id: index, delegate: self, image: image)
        
        self.svImages.addSubview(view)
        x = self.calculateImagesWidth(index + 1)
        
        self.svImages.contentSize = CGSizeMake(CGFloat(x), self.svImages.frame.size.height);
        self.svImages.layoutSubviews()
        
        return view
    }
    
    func redrawImagesScrollView(){
        self.svImages.subviews.forEach({ (view) in
            view.removeFromSuperview()
        })
        
        var index = 0
        self.images.forEach { (image) in
            self.addImageToScrollView(image, index: index)
            index += 1
        }
    }
    
    func calculateImagesWidth(count: Int) -> Float {
        return (8 + Float(count) * Float(SmallImageView.width + 16))
        //return Float(self.svImages.frame.width) * Float(self.images.count)
    }
    
    func deleteClicked(view: SmallImageView) {
        if let index = self.uploadingIds.indexOf(view.id!){
            self.uploadingIds.removeAtIndex(index)
        }
        self.images.removeAtIndex(view.id!)
        self.redrawImagesScrollView()
        if self.images.count == 0{
            self.svImages.hidden = true
            self.lblNoImages.hidden = false
        }
        self.updateCreateButton()
    }
}
