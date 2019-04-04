//
//  OrderViewController.swift
//  FirebaseSample
//
//  Created by Christina Sund on 4/2/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class OrderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let orderData = ["travel_class": "first", "order_id": "ORD129", "user_loyalty_status": UserDefaults.standard.object(forKey: "user_loyalty_status"), "customer_id": "ABC1234"]
        // trackView sent to Tealium with the purchase event and event parameters. This will then get mapped to trigger the both the logEvent(AnalyticsEventEcommercePurchase, parameters: <orderData>) methods in Firebase
        TealiumHelper.shared.trackView(title: "purchase", data: orderData as [String: Any])
    }

}
