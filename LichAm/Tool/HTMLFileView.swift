//
//  SwiftUIView.swift
//  LichAm
//
//  Created by HuyDuc.Dev on 18/11/25.
//

import SwiftUI
import UIKit
import WebKit

struct HTMLFileView: UIViewRepresentable {

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        if let url = Bundle.main.url(forResource: "meo_600_gplx_mobile", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
