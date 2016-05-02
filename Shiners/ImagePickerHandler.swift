//
//  ImagePickerHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/1/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class ImagePickerHandler{
    
    public weak var delegate: UIImagePickerControllerDelegate?
    public weak var viewController: UIViewController?
    public var imagePickerController = UIImagePickerController()
    
    public init(viewController: UIViewController, delegate: protocol<UIImagePickerControllerDelegate, UINavigationControllerDelegate>){
        self.delegate = delegate
        self.viewController = viewController
        self.imagePickerController.delegate = delegate;
    }
    
    public func displayImagePicker(){
        var alertViewController = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .ActionSheet)
        
        var index = 0;
        if UIImagePickerController.isSourceTypeAvailable(.Camera){
            alertViewController.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { (_) in
                self.imagePickerController.sourceType = .Camera
                self.viewController?.presentViewController(self.imagePickerController, animated: true, completion: nil);
            }));
            index += 1;
        }
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            alertViewController.addAction(UIAlertAction(title: "Photo Library", style: .Default, handler: { (_) in
                self.imagePickerController.sourceType = .PhotoLibrary
                self.viewController?.presentViewController(self.imagePickerController, animated: true, completion: nil);
            }));
            index += 1;
        }
        alertViewController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil));
        if (index == 0){
            alertViewController = UIAlertController(title: "Permissions", message: "Please allow access to Camera or Photo Library in Privacy Settings", preferredStyle: .Alert);
            alertViewController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil));
        }
        self.viewController?.presentViewController(alertViewController, animated: true, completion: nil)
    }
}
