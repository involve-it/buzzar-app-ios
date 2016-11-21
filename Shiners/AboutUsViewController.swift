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
        
        let preferredLanguage = NSLocale.preferredLanguages()[0] as String
        var url: NSURL!
        if preferredLanguage == "ru"{
            url = NSURL(string: "https://shiners.ru/about-us?isiframe=true")
        } else {
            url = NSURL(string: "https://shiners.mobi/about-us?lat=37&lng=-120&isiframe=true")
        }
        loadWebView(url!, webView: self.webView)
        self.setLoading(true)
        AppAnalytics.logEvent(.SettingsLoggedInScreen_AboutUs)
    }
    
    
    func loadWebView(url: NSURL, webView: UIWebView) {
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.setLoading(false)
    }
}

