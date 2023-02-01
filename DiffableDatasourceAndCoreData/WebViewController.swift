//
//  WebViewController.swift
//  DiffableDatasourceAndCoreData
//
//  Created by Stefan Schmitt on 01/02/2023.
//

import Foundation
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate {
    
    var urlToLoad: URL!
    
    private weak var webView: WKWebView!
    
    override func loadView() {
        let webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
        self.webView = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: urlToLoad))
    }
}
