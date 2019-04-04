//
//  LoggedInViewController.swift
//  FirebaseSample
//
//  Created by Christina Sund on 4/2/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class LoggedInViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // trackView sent to Tealium with the login event and customer_email. This will then get mapped to trigger the both the logEvent(AnalyticsEventLogin) and setUserId(<firebase_user_id>) methods in Firebase
        TealiumHelper.shared.trackView(title: "login", data: ["customer_id": "ABC1234"])
    }

}
