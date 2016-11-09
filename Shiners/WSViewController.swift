//
//  WSViewController.swift
//  Shiners
//
//  Created by Вячеслав on 07/11/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class WSViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.pagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = UIColor.whiteColor()
        return cv
    }()
    
    struct cellId {
        static let WelcomeScreen = "wsCellId"
        static let LoginCell = "wsLoginCell"
    }
    
    let nextLabelBtn        = NSLocalizedString("Next", comment: "Log in page, button Next")
    let skipLabelBtn        = NSLocalizedString("Skip", comment: "Log in page, button Skip")
    
    let firstPageTitle      = NSLocalizedString("", comment: "")
    let secondPageTitle     = NSLocalizedString("", comment: "")
    let thirdPageTitle      = NSLocalizedString("", comment: "")
    
    let firstPageMessage    = NSLocalizedString("", comment: "")
    let secondPageMessage   = NSLocalizedString("", comment: "")
    let thirdPageMessage    = NSLocalizedString("", comment: "")
    
    let langString = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as! String
    
    let pages: [Page] = {
        let firstPage = Page(title: "Создай свое объявление", message: "Оно будет перемещаться вместе с тобой, как твоя виртуальная визитка, которую могут увидеть люди вокруг", imageName: "page1")
        let secondPage = Page(title: "Ты находишь / тебя находят", message: "Используй светлячки для поиска живых объявлений от людей, которые находятся рядом с тобой", imageName: "page2")
        let thirdPage = Page(title: "Договаривайся / встречайся", message: "Найдя нужный живой пост рядом, напиши его владельцу и договорись о встрече прямо здесь и сейчас!", imageName: "page3")
        
        return [firstPage, secondPage, thirdPage]
    }()
    
    lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.pageIndicatorTintColor = UIColor.grayColor()
        pc.currentPageIndicatorTintColor = UIColor.orangeColor()
        pc.numberOfPages = self.pages.count + 1
        return pc
    }()
    
    lazy var skipButton: UIButton = {
        let b = UIButton(type: .System)
        b.setTitle(self.skipLabelBtn, forState: .Normal)
        b.backgroundColor = UIColor(white: 0.2, alpha: 0.3)
        b.layer.cornerRadius = 4.0
        b.setTitleColor(UIColor(netHex: 0xFFFFFF), forState: .Normal)
        b.addTarget(self, action: #selector(btnSkipPage), forControlEvents: .TouchUpInside)
        return b
    }()
    
    func btnSkipPage() {
        pageControl.currentPage = pages.count - 1
        btnNextPage()
    }
    
    lazy var nextButton: UIButton = {
        let b = UIButton(type: .System)
        b.setTitle(self.nextLabelBtn, forState: .Normal)
        b.backgroundColor = UIColor(white: 0.2, alpha: 0.3)
        b.layer.cornerRadius = 4.0
        b.setTitleColor(UIColor(netHex: 0xFFFFFF), forState: .Normal)
        b.addTarget(self, action: #selector(btnNextPage), forControlEvents: .TouchUpInside)
        return b
    }()
    
    func btnNextPage() {
        
        if pageControl.currentPage == pages.count {
            return
        }
        
        if pageControl.currentPage == pages.count - 1 {
            moveControlOfConstaintScreen()
            
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
        
        let indexPath = NSIndexPath(forItem: self.pageControl.currentPage + 1, inSection: 0)
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
        self.pageControl.currentPage += 1
    }
    
    var pageControlBottomAnchor: NSLayoutConstraint?
    var skipBottomAnchor: NSLayoutConstraint?
    var nextBottomAnchor: NSLayoutConstraint?
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count + 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId.WelcomeScreen, forIndexPath: indexPath) as! cellPage
        
        if indexPath.item == pages.count {
            let loginCell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId.LoginCell, forIndexPath: indexPath) as! LoginCell
            
        
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("settingsLogOutUser") as! NavigationControllerBase
            vc.navigationBarHidden = true
            vc.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
            self.addChildViewController(vc)
            
            loginCell.addSubview(vc.view)
            vc.didMoveToParentViewController(self)
            //loginCell.delegate = self
            return loginCell
        }
        
        let page = pages[indexPath.row]
        cell.page = page
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(skipButton)
        view.addSubview(nextButton)
        
        collectionView.anchorToTop(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
        
        let widthConstant: CGFloat = (langString == "ru") ? 95 : 65
        pageControlBottomAnchor = pageControl.anchor(nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 60)[1]
        skipBottomAnchor = skipButton.anchor(nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: nil, topConstant: 0, leftConstant: 16, bottomConstant: 16, rightConstant: 0, widthConstant: widthConstant, heightConstant: 32)[1]
        nextBottomAnchor = nextButton.anchor(nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 16, rightConstant: 16, widthConstant: widthConstant, heightConstant: 32).first
        
        //Register Cell
        registerCells()
    }
    
    
    private func registerCells() {
        collectionView.registerClass(cellPage.self, forCellWithReuseIdentifier: cellId.WelcomeScreen)
        collectionView.registerClass(LoginCell.self, forCellWithReuseIdentifier: cellId.LoginCell)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let pageNumber = Int(targetContentOffset.memory.x / self.view.frame.width)
        self.pageControl.currentPage = pageNumber
        
        //We are on the last page
        if pageNumber == self.pages.count {
            moveControlOfConstaintScreen()
        } else {
            pageControlBottomAnchor?.constant = 0
            skipBottomAnchor?.constant = -16
            nextBottomAnchor?.constant = -16
        }
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    private func moveControlOfConstaintScreen() {
        pageControlBottomAnchor?.constant = 60
        skipBottomAnchor?.constant = 60
        nextBottomAnchor?.constant = 60
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    

}
