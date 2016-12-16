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
        
        let preferredLanguage = Locale.preferredLanguages[0] as String
        var url: URL!
        if preferredLanguage == "ru"{
            url = URL(string: "https://shiners.ru/about-us?isiframe=true")
        } else {
            url = URL(string: "https://shiners.mobi/about-us?lat=37&lng=-120&isiframe=true")
        }
        loadWebView(url!, webView: self.webView)
        self.setLoading(true)
        AppAnalytics.logEvent(.SettingsLoggedInScreen_AboutUs)
    }
    
    
    func loadWebView(_ url: URL, webView: UIWebView) {
        webView.loadRequest(URLRequest(url: url))
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.setLoading(false)
    }
}

