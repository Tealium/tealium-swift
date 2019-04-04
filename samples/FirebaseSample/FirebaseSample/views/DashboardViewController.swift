//
//  ViewController.swift
//  FirebaseSample
//
//  Created by Christina Sund on 4/2/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController {

    enum DashboardViewControllerKeys {
        static let userLoyalty = "user_loyalty_status"
    }

    enum LoyaltyStatusOptions {
        static let vip = "vip"
        static let basic = "basic"
    }

    var loyaltyStatus: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func toggleLoyaltyStatus(_ status: String?) -> String {
        if let status = status {
            return status == LoyaltyStatusOptions.basic ? LoyaltyStatusOptions.vip : LoyaltyStatusOptions.basic
        } else {
            return LoyaltyStatusOptions.basic
        }
    }

    @IBAction func setLoyaltyStatus(_ sender: Any) {
        if let currentLoyaltyStatus = UserDefaults.standard.object(forKey: DashboardViewControllerKeys.userLoyalty) as? String {
            loyaltyStatus = currentLoyaltyStatus
        }
        let toggle = toggleLoyaltyStatus(loyaltyStatus)
        // trackEvent sent to Tealium with the set_loyalty_status event and associated parameters. This will then get mapped to trigger the setUserProperty(<toggle>, forName: "user_loyalty_status") method in Firebase
        TealiumHelper.shared.track(title: "set_loyalty_status", data: ["user_loyalty_status": toggle])
        self.showSimpleAlert(title: "setUserProperty", message: "Firebase .setUserProperty called with user_loyalty_status set to \(toggle)")
        UserDefaults.standard.set(toggle, forKey: DashboardViewControllerKeys.userLoyalty)
    }

    @IBAction func addToCart(_ sender: Any) {
        let addToCartData = ["product_id": ["ABC123"], "product_price": ["14.99"], "product_quantity": ["1"], "product_name": ["Premium Widget"]]
        // trackEvent sent to Tealium with the cart_add event and associated parameters. This will then get mapped in TiQ to trigger the logEvent("add_to_cart", firebase_event_params) method in Firebase
        TealiumHelper.shared.track(title: "cart_add", data: addToCartData)
        self.showSimpleAlert(title: "logEvent", message: "Firebase .logEvent called with the cart_add event and properties. This will send the add_to_cart event to Firebase with these parameters: \(addToCartData)")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Dashboard"
        navigationItem.backBarButtonItem = backItem
    }


}

