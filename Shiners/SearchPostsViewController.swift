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
    var postsAllLoad = [Post]()
    
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
        
        heightViewNavBars = stackViewBtnMore.frame.height
        
        //Add some point margin at the top
        if !stackViewBtnMore.isHidden {
            tableView.contentInset = UIEdgeInsetsMake(heightViewNavBars, 0, 0, 0)
            tableView.scrollIndicatorInsets = UIEdgeInsetsMake(heightViewNavBars, 0, 0, 0)
        }
    
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        searchBar.becomeFirstResponder()
        
        //Получаем первичный неотсортированный массив posts
        if CachingHandler.Instance.status != .complete {
            print("ERROR LOAD POST")
        } else if let posts = CachingHandler.Instance.postsAll {
            postsAllLoad = posts
        }
    }
    
    //Тут можно поменять стили вью или статус бара и т.д.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isTranslucent = false
        //Remove Shadow in nc
        let img = UIImage()
        self.navigationController?.navigationBar.shadowImage = img
        self.navigationController?.navigationBar.setBackgroundImage(img, for: .default)
        //Set background color
        self.navigationController?.navigationBar.barTintColor = blueColor
        
        //setBackBarButtonCustom()
    }
    
    //Тут можно менять размеры сабвью и т.д.
    override func viewWillLayoutSubviews() {}
    
    //View будет удален из иерархии вьюх. Можно отменить стили, которые были выставлены для nav...
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchBar.resignFirstResponder()
    }
    
    func createSearchBar() {
        searchBar.barTintColor = UIColor.white
        searchBar.showsCancelButton = true
        searchBar.placeholder = NSLocalizedString("Search posts", comment: "Search placeholder, Search posts")
        searchBar.delegate = self
        
        self.navigationItem.titleView = searchBar
    }
    
    func setBackBarButtonCustom() {
        //Initialising "back button"
        let btnLeftMenu: UIButton = UIButton()
        btnLeftMenu.setImage(UIImage(named: "goBackBtn"), for: UIControlState())
        btnLeftMenu.addTarget(self, action: #selector(SearchPostsViewController.onGoBack), for: .touchUpInside)
        btnLeftMenu.frame = CGRect(x: 0, y: 0, width: 39/2, height: 63/2)
        let barButton = UIBarButtonItem(customView: btnLeftMenu)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    func onGoBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    
    @IBAction func CloseViewMoreFiltersSearch(_ sender: UIButton) {
        closeViewMoreFilters()
    }
    
    
    @IBAction func openViewMoreFiltersSearch(_ sender: UIButton) {
        openViewMoreFilters()
    }
    
    
    func closeViewMoreFilters() {
        self.searchBar.becomeFirstResponder()
        
        self.viewMoreFiltersSearch.alpha = 1
        self.innerStackView.alpha = 0
        self.moreCategoryView.isHidden = false
        
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveLinear], animations: {
            
            self.innerStackView.alpha = 1
            self.viewMoreFiltersSearch.alpha = 0
            self.moreCategoryView.isHidden = true
            
            }, completion: { (_) in
                self.tableView.isScrollEnabled = true
                self.viewMoreFiltersSearch.removeFromSuperview()
        })
    }
    
    func openViewMoreFilters() {
        //Size height colculate
        self.viewMoreFiltersSearch.frame = CGRect(x: 0, y: heightViewNavBars, width: self.view.frame.width, height: self.view.frame.height - heightViewNavBars)
        self.view.addSubview(self.viewMoreFiltersSearch)
        
        
        self.tableView.isScrollEnabled = false
        self.viewMoreFiltersSearch.alpha = 0
        self.innerStackView.alpha = 1
        self.moreCategoryView.isHidden = true
        
        self.searchBar.resignFirstResponder()
        
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveLinear], animations: {
            
            self.innerStackView.alpha = 0
            self.viewMoreFiltersSearch.alpha = 1
            self.moreCategoryView.isHidden = false
            
            }, completion: nil)
    }
    
    func tabelViewStyleDefault() {
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView.layoutMargins = UIEdgeInsets()
        tableView.separatorInset = UIEdgeInsets()
    }
    
    func tableViewStyleOwn() {
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
    }
    
}



//MARK: EXTENSION - searchBar, tabelView

extension SearchPostsViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    //User tap search button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        
        //Когда пользователь нажимает на кнопку поиска
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            
            isLoading = true
            hasSearched = true
            tableView.reloadData()
            
            if searchResults.count != 0 {}
        }
        
        //If search text != Shiners
        isLoading = false
        tableView.reloadData()
    }

    //Текст в поле поиска меняется
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count == 0 {
            self.tabelViewStyleDefault()
            hasSearched = false
            tableView.reloadData()
        } else {
            isLoading = false
            hasSearched = true
            filterContentForSearchText(searchText)
            tableView.reloadData()
        }
    }
    
    //Простая функция для поиска
    func filterContentForSearchText(_ searchText: String) {
        searchResults = postsAllLoad.filter({ (post) -> Bool in
            let nameMatch = post.title?.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
            return nameMatch != nil
        })
    }
    
    //Top position for Bar
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}


extension SearchPostsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath) as! LoadingCell
            let spinner = cell.loadingSpinner
            spinner?.startAnimating()
            return cell
        } else if searchResults.count == 0 {
            tableView.estimatedRowHeight = 44.0
            tableView.rowHeight = UITableViewAutomaticDimension
            
            self.tableViewStyleOwn()
            
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            
            let searchResult = searchResults[indexPath.row]
            
            cell.txtTitlePost.text = searchResult.title

            return cell
        }
    }
    
}


extension SearchPostsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
    
}

//Statusbar LightContent
extension UINavigationController {
    override open var preferredStatusBarStyle : UIStatusBarStyle {
        if self.topViewController != nil {
            return self.topViewController!.preferredStatusBarStyle
        } else {
            return UIStatusBarStyle.default
        }
    }
}













