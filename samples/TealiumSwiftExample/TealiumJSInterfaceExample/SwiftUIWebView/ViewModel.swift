//
//  File.swift
//  SwiftUIWebView
//
//  Copyright © 2020 Tealium. All rights reserved.
//

import Combine
import Foundation

class ViewModel: ObservableObject {
    var webViewNavigationPublisher = PassthroughSubject<WebViewNavigation, Never>()
    var showWebTitle = PassthroughSubject<String, Never>()
    var showLoader = PassthroughSubject<Bool, Never>()
    var valuePublisher = PassthroughSubject<String, Never>()
}

enum WebViewNavigation {
    case backward, forward, reload
}

enum WebUrlType {
    case localUrl, publicUrl
}
