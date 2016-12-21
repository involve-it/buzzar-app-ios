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
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    struct cellId {
        static let WelcomeScreen = "wsCellId"
        static let LoginCell = "wsLoginCell"
    }
    
    let nextLabelBtn = NSLocalizedString("Next", comment: "Log in page, button Next")
    let skipLabelBtn = NSLocalizedString("Skip", comment: "Log in page, button Skip")
    
    let langString = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as! String
    
    let pages: [Page] = {
        let firstPage = Page(title: NSLocalizedString("Create your post", comment: ""), message: NSLocalizedString("It will move with you, showing your availability to people around you", comment: ""), imageName: "page1")
        let secondPage = Page(title: NSLocalizedString("Find and get found", comment: ""), message: NSLocalizedString("Use Shiners to search live ads from people around or let them find your live post", comment: ""), imageName: "page2")
        let thirdPage = Page(title: NSLocalizedString("Connect and meet", comment: ""), message: NSLocalizedString("After finding the right post contact its owner to meet him immediately!", comment: ""), imageName: "page3")
        
        return [firstPage, secondPage, thirdPage]
    }()
    
    lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.pageIndicatorTintColor = UIColor.gray
        pc.currentPageIndicatorTintColor = UIColor.orange
        pc.numberOfPages = self.pages.count + 1
        return pc
    }()
    
    lazy var skipButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(self.skipLabelBtn, for: UIControlState())
        b.backgroundColor = UIColor(white: 0.2, alpha: 0.3)
        b.layer.cornerRadius = 4.0
        b.setTitleColor(UIColor(netHex: 0xFFFFFF), for: UIControlState())
        b.addTarget(self, action: #selector(btnSkipPage), for: .touchUpInside)
        return b
    }()
    
    func btnSkipPage() {
        pageControl.currentPage = pages.count - 1
        btnNextPage()
    }
    
    lazy var nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(self.nextLabelBtn, for: UIControlState())
        b.backgroundColor = UIColor(white: 0.2, alpha: 0.3)
        b.layer.cornerRadius = 4.0
        b.setTitleColor(UIColor(netHex: 0xFFFFFF), for: UIControlState())
        b.addTarget(self, action: #selector(btnNextPage), for: .touchUpInside)
        return b
    }()
    
    func btnNextPage() {
        
        if pageControl.currentPage == pages.count {
            return
        }
        
        if pageControl.currentPage == pages.count - 1 {
            moveControlOfConstaintScreen()
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
        
        let indexPath = IndexPath(item: self.pageControl.currentPage + 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.pageControl.currentPage += 1
    }
    
    var pageControlBottomAnchor: NSLayoutConstraint?
    var skipBottomAnchor: NSLayoutConstraint?
    var nextBottomAnchor: NSLayoutConstraint?
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId.WelcomeScreen, for: indexPath) as! cellPage
        
        if indexPath.item == pages.count {
            let loginCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId.LoginCell, for: indexPath) as! LoginCell

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "settingsLogOutUser") as! NavigationControllerBase
            vc.isNavigationBarHidden = true
            
            //SettingsViewController
            let bb = vc.viewControllers[0] as! SettingsViewController
            bb.isBtnDismiss = true
            
            vc.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
            self.addChildViewController(vc)
            
            loginCell.addSubview(vc.view)
            vc.didMove(toParentViewController: self)
            //loginCell.delegate = self
            return loginCell
        }
        
        let page = pages[indexPath.row]
        cell.page = page
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
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
    
    
    fileprivate func registerCells() {
        collectionView.register(cellPage.self, forCellWithReuseIdentifier: cellId.WelcomeScreen)
        collectionView.register(LoginCell.self, forCellWithReuseIdentifier: cellId.LoginCell)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let pageNumber = Int(targetContentOffset.pointee.x / self.view.frame.width)
        self.pageControl.currentPage = pageNumber
        
        //We are on the last page
        if pageNumber == self.pages.count {
            moveControlOfConstaintScreen()
        } else {
            pageControlBottomAnchor?.constant = 0
            skipBottomAnchor?.constant = -16
            nextBottomAnchor?.constant = -16
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    fileprivate func moveControlOfConstaintScreen() {
        pageControlBottomAnchor?.constant = 60
        skipBottomAnchor?.constant = 60
        nextBottomAnchor?.constant = 60
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.Welcome)
    }
}
