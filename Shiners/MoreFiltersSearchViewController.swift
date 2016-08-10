//
//  MoreFiltersSearchViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/7/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class MoreFiltersSearchViewController: UIViewController {

    
    @IBOutlet weak var collectionView: UICollectionView!
   

    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    struct CollectionViewIdentifierCell {
        static let postCategoryNib = "CVCellNib"
    }
    
    let categoryOfPosts = [
        (image: "catJobs", label: "Jobs"),
        (image: "catTrainings", label: "Trainigs"),
        (image: "catConnect", label: "Connect"),
        (image: "catTrade", label: "Trade"),
        (image: "catHousing", label: "Housing"),
        (image: "catEvents", label: "Events"),
        (image: "catService", label: "Services"),
        (image: "catHelp", label: "Help")
    ]
    
    //Size Collection View Cell
    let sizeCVCell: (width: CGFloat, height: CGFloat) = (2, 4)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        
        
        
        collectionView.registerNib(UINib(nibName: CollectionViewIdentifierCell.postCategoryNib, bundle: nil), forCellWithReuseIdentifier: CollectionViewIdentifierCell.postCategoryNib)
       
    }
    
    //Here may changes size of the subviews
    override func viewWillLayoutSubviews() {
        
        /*
         let layout = UICollectionViewFlowLayout()
         layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
         layout.itemSize = CGSize(width: screenWidth / 2, height: screenHeight / 2)
         
         layout.minimumInteritemSpacing = 0
         layout.minimumLineSpacing = 0
        */
        
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
    }
    
    
    
    
}





extension MoreFiltersSearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryOfPosts.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CollectionViewIdentifierCell.postCategoryNib, forIndexPath: indexPath) as! CVCellNib
        
        cell.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
         cell.layer.borderColor = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1).CGColor
         cell.layer.borderWidth = 0.5
         cell.frame.size.width = screenWidth / sizeCVCell.width
         cell.frame.size.height = screenWidth / sizeCVCell.height
        
        
        cell.txtlabelPostCategory.text = categoryOfPosts[indexPath.row].label
        cell.imgPostCategory.image = UIImage(named: categoryOfPosts[indexPath.row].image)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = CGSize(width: screenWidth / sizeCVCell.width, height: screenWidth / sizeCVCell.height)
        return size
        
    }
    
    
}


