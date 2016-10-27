//
//  AboutUsViewController.swift
//  Shiners
//
//  Created by Вячеслав on 25/10/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class AboutUsViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.delegate = self
        
        let url = NSURL(string: "https://shiners.2list.ru/about-us")
        loadWebView(url!, webView: self.webView)
        self.setLoading(true)
    }
    
    
    func loadWebView(url: NSURL, webView: UIWebView) {
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.setLoading(false)
    }
}

