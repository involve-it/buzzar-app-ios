//
//  AboutUsViewController.swift
//  Shiners
//
//  Created by Вячеслав on 25/10/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class AboutUsViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "About US"
        
        let url = NSURL(string: "https://shiners.2list.ru/about-us")
        loadWebView(url!, webView: self.webView)
        
        //CFNetwork SSLHandshake failed (-9807)
        //http://stackoverflow.com/questions/30720813/cfnetwork-sslhandshake-failed-ios-9
    }
    
    
    func loadWebView(url: NSURL, webView: UIWebView) {
        webView.loadRequest(NSURLRequest(URL: url))
    }
}

