//
//  ImagePickerHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

open class ImagePickerHandler{
    
    open weak var delegate: UIImagePickerControllerDelegate?
    open weak var viewController: UIViewController?
    open var imagePickerController = UIImagePickerController()
    
    public init(viewController: UIViewController, delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate){
        self.delegate = delegate
        self.viewController = viewController
        self.imagePickerController.delegate = delegate;
    }
    
    open func displayImagePicker(){
        var alertViewController = UIAlertController(title: NSLocalizedString("Choose Image", comment: "Alert title, Choose Image"), message: nil, preferredStyle: .actionSheet)
        
        var index = 0;
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Camera", comment: "Alert title, Camera"), style: .default, handler: { (_) in
                self.imagePickerController.sourceType = .camera
                self.viewController?.present(self.imagePickerController, animated: true, completion: nil);
            }));
            index += 1;
        }
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Photo Library", comment: "Alert title, Photo Library"), style: .default, handler: { (_) in
                self.imagePickerController.sourceType = .photoLibrary
                self.viewController?.present(self.imagePickerController, animated: true, completion: nil);
            }));
            index += 1;
        }
        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert title, Cancel"), style: .cancel, handler: nil));
        if (index == 0){
            alertViewController = UIAlertController(title: NSLocalizedString("Permissions", comment: "Alert title, Permissions"), message: NSLocalizedString("Please allow access to Camera or Photo Library in Privacy Settings", comment: "Alert message, Please allow access to Camera or Photo Library in Privacy Settings"), preferredStyle: .alert);
            alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok"), style: .default, handler: nil));
        }
        self.viewController?.present(alertViewController, animated: true, completion: nil)
    }
}
