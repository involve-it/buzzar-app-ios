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
    @IBOutlet weak var createPost: UIBarButtonItem!
    
    var post: Post!
    
    private var imagePickerHandler: ImagePickerHandler?
    private var images = [UIImage]()
    
    var imageCount = 0
    
    var currentLocationInfo: GeocoderInfo?
    
    override func viewDidLoad() {
        self.svImages.hidden = true;
        self.lblNoImages.hidden = false;
        
        self.imagePickerHandler = ImagePickerHandler(viewController: self, delegate: self)
        self.post.photos = [Photo]()
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
        let rotatedImage = image.correctlyOrientedImage().resizeImage()
        self.images.append(rotatedImage)
        let view = self.addImageToScrollView(rotatedImage, index: self.images.count - 1)
        view.activityIndicator.startAnimating()
        imageCount = imageCount + 1
        self.createPost.enabled = false
        
        ImageCachingHandler.Instance.saveImage(rotatedImage) { (success, imageUrl) in
            ThreadHelper.runOnMainThread({
                //self.setLoading(false, rightBarButtonItem: self.cancelButton)
                //self.btnSave.enabled = true
                view.activityIndicator.stopAnimating()
                if success {
                    let photo = Photo()
                    photo.original = imageUrl
                    self.post.photos!.append(photo)
                } else {
                    self.showAlert(NSLocalizedString("Error", comment: "Alert, Error"), message: NSLocalizedString("Error uploading photo", comment: "Alert, error message uploading photo"));
                    self.deleteClicked(view)
                }
                
                self.imageCount = self.imageCount - 1
                if self.imageCount != 0 {
                    self.createPost.enabled = false
                } else {
                    self.createPost.enabled = true
                }
                
                
            })
            
        }
        
        picker.dismissViewControllerAnimated(true, completion: nil)
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
        self.images.removeAtIndex(view.id!)
        self.redrawImagesScrollView()
        if self.images.count == 0{
            self.svImages.hidden = true
            self.lblNoImages.hidden = false
        }
    }
    
    
    
}
