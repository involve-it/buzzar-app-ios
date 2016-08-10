//
//  SearchPostsViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/5/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class SearchResult {
    var name = ""
    var subName = ""
}

class SearchPostsViewController: UIViewController {
    
    
    //@IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var stackViewBtnMore: UIView!
    @IBOutlet weak var innerStackView: UIStackView!
    @IBOutlet weak var moreCategoryView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    //Container View
    @IBOutlet var viewMoreFiltersSearch: UIView!
    
    let searchBar = UISearchBar()
    let blueColor = UIColor(red: 0/255, green: 118/255, blue: 255/255, alpha: 1)
    
    var moreFiltersSearchViewController =  MoreFiltersSearchViewController()
    
    var heightViewNavBars: CGFloat = 0.0
    
    var searchResults = [Post]()
    
    var hasSearched = false
    var isLoading = false
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createSearchBar()
        
        
        //heightViewNavBars = UIApplication.sharedApplication().statusBarFrame.size.height + searchBar.frame.height + stackViewBtnMore.frame.height
        heightViewNavBars = stackViewBtnMore.frame.height
        
        //Add some point margin at the top
        tableView.contentInset = UIEdgeInsets(top: heightViewNavBars, left: 0, bottom: 0, right: 0)
    
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        searchBar.becomeFirstResponder()
        
        //print("viewDidLoad size: w:\(self.view.bounds.size.width), h: \(self.view.bounds.size.height)")
    }
    
    //Тут можно поменять стили вью или статус бара и т.д.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.translucent = false
        //Remove Shadow in nc
        let img = UIImage()
        self.navigationController?.navigationBar.shadowImage = img
        self.navigationController?.navigationBar.setBackgroundImage(img, forBarMetrics: .Default)
        //Set background color
        self.navigationController?.navigationBar.barTintColor = blueColor
        
        setBackBarButtonCustom()
    }
    
    //Тут можно менять размеры сабвью и т.д.
    override func viewWillLayoutSubviews() {}
    
    //View будет удален из иерархии вьюх. Можно отменить стили, которые были выставлены для nav...
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchBar.resignFirstResponder()
    }
    
    func createSearchBar() {
        searchBar.showsCancelButton = false
        searchBar.placeholder = "Search posts"
        searchBar.delegate = self
        self.navigationItem.titleView = searchBar
    }
    
    func setBackBarButtonCustom() {
        //Initialising "back button"
        let btnLeftMenu: UIButton = UIButton()
        btnLeftMenu.setImage(UIImage(named: "goBackBtn"), forState: UIControlState.Normal)
        btnLeftMenu.addTarget(self, action: #selector(SearchPostsViewController.onGoBack), forControlEvents: .TouchUpInside)
        btnLeftMenu.frame = CGRectMake(0, 0, 39/2, 63/2)
        let barButton = UIBarButtonItem(customView: btnLeftMenu)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    func onGoBack() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    @IBAction func CloseViewMoreFiltersSearch(sender: UIButton) {
        closeViewMoreFilters()
    }
    
    
    @IBAction func openViewMoreFiltersSearch(sender: UIButton) {
        openViewMoreFilters()
    }
    
    
    func closeViewMoreFilters() {
        self.searchBar.becomeFirstResponder()
        
        self.viewMoreFiltersSearch.alpha = 1
        self.innerStackView.alpha = 0
        self.moreCategoryView.hidden = false
        
        UIView.animateWithDuration(0.15, delay: 0, options: [.CurveLinear], animations: {
            
            self.innerStackView.alpha = 1
            self.viewMoreFiltersSearch.alpha = 0
            self.moreCategoryView.hidden = true
            
            }, completion: { (_) in
                self.tableView.scrollEnabled = true
                self.viewMoreFiltersSearch.removeFromSuperview()
        })
    }
    
    func openViewMoreFilters() {
        //Size height colculate
        self.viewMoreFiltersSearch.frame = CGRectMake(0, heightViewNavBars, self.view.frame.width, self.view.frame.height - heightViewNavBars)
        self.view.addSubview(self.viewMoreFiltersSearch)
        
        
        self.tableView.scrollEnabled = false
        self.viewMoreFiltersSearch.alpha = 0
        self.innerStackView.alpha = 1
        self.moreCategoryView.hidden = true
        
        self.searchBar.resignFirstResponder()
        
        UIView.animateWithDuration(0.15, delay: 0, options: [.CurveLinear], animations: {
            
            self.innerStackView.alpha = 0
            self.viewMoreFiltersSearch.alpha = 1
            self.moreCategoryView.hidden = false
            
            }, completion: nil)
    }
    
    func tabelViewStyleDefault() {
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        tableView.layoutMargins = UIEdgeInsets()
        tableView.separatorInset = UIEdgeInsets()
    }
    
    func tableViewStyleOwn() {
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
    }
    
}



//MARK: EXTENSION - searchBar, tabelView

extension SearchPostsViewController: UISearchBarDelegate {
    
    //User tap search button
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            
            isLoading = true
            tableView.reloadData()
            
            hasSearched = true
            //searchResults = [SearchResult]()
            
            //MARK: LOAD POSTS
            if CachingHandler.Instance.status != .Complete {
                print("ERROR LOAD POST")
            } else if let posts = CachingHandler.Instance.postsAll {
                searchResults = posts
                
                isLoading = false
                tableView.reloadData()
            }
     
            if searchResults.count != 0 {}
        }
        
        
        
        
        
        //If search text != Shiners
        isLoading = false
        tableView.reloadData()
    }
    
    //Top position for Bar
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    //Text changed
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count == 0 {
            
            self.tabelViewStyleDefault()
 
            hasSearched = false
            tableView.reloadData()
        }
    }
    
    
    
    
}


extension SearchPostsViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if isLoading {
            45
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath) as! LoadingCell
            let spinner = cell.loadingSpinner
            spinner.startAnimating()
            return cell
            
        } else if searchResults.count == 0 {
            
            //if need img
            tableView.estimatedRowHeight = 44.0
            tableView.rowHeight = UITableViewAutomaticDimension
            
            self.tableViewStyleOwn()
            
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath)
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell, forIndexPath: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            
            cell.txtTitlePost.text = searchResult.title
            //if need img
            
            return cell
        }
    }
    
}


extension SearchPostsViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
    
}

//Statusbar LightContent
extension UINavigationController {
    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return self.topViewController!.preferredStatusBarStyle()
    }
}












