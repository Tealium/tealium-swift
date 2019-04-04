//
//  ProductViewController.swift
//  FirebaseSample
//
//  Created by Christina Sund on 4/2/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // trackView sent to Tealium with the content_view event and screen_name blog. This will then get mapped to trigger the setScreenName("Blog Article"), screenClass: "blog") method in Firebase
        TealiumHelper.shared.trackView(title: "content_view", data: ["screen_name": "blog"])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
