//
//  CheckoutViewController.swift
//  TealiumVisitorProfileDemo
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class CheckoutViewController: UIViewController {

    @IBOutlet weak var checkoutStepLabel: UILabel!
    @IBOutlet weak var checkoutProgress: UIButton!
    @IBOutlet weak var checkoutTextField1: UITextField!
    @IBOutlet weak var checkoutTextField2: UITextField!
    @IBOutlet weak var checkoutSegmentedControl: UISegmentedControl!
    @IBOutlet weak var checkoutOptionsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        checkoutTextField1.delegate = self
        checkoutTextField2.delegate = self
    }

    @IBAction func onCheckoutProgressTapped(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else {
            return
        }
        if title.contains("Payment") {
            let value = checkoutSegmentedControl.titleForSegment(at: checkoutSegmentedControl.selectedSegmentIndex)
            TealiumHelper.trackEvent(name: "checkout_progress", dataLayer: ["checkout_step": "shipping", "checkout_option": value!])
            TealiumHelper.trackView(title: "payment", dataLayer: ["screen_class": "\(self.classForCoder)"])
            checkoutStepLabel.text = "Payment"
            checkoutTextField1.text = ""
            checkoutTextField2.text = ""
            checkoutTextField1.placeholder = "Credit Card Number"
            checkoutTextField2.placeholder = "Name on Card"
            checkoutTextField1.isSecureTextEntry = true
            checkoutSegmentedControl.replaceSegments(withTitles: ["Visa", "AMEX", "Discover"])
            checkoutSegmentedControl.selectedSegmentIndex = 0
            checkoutOptionsLabel.text = "Select Payment Option"
            checkoutProgress.setTitle("Place Order", for: .normal)
        } else {
            let value = checkoutSegmentedControl.titleForSegment(at: checkoutSegmentedControl.selectedSegmentIndex)
            TealiumHelper.trackEvent(name: "checkout_progress", dataLayer: ["checkout_step": "payment", "checkout_option": value!])
            let notification = Notification(name: Notification.Name(CheckoutViewController.placedOrderClicked), object: nil, userInfo: nil)
            NotificationCenter.default.post(notification)

            checkoutStepLabel.text = "Shipping"
            checkoutTextField1.text = ""
            checkoutTextField2.text = ""
            checkoutTextField1.placeholder = "Full Street Address"
            checkoutTextField2.placeholder = "City, State, Zip"
            checkoutTextField1.isSecureTextEntry = true
            checkoutSegmentedControl.replaceSegments(withTitles: ["Fedex", "UPS", "USPS"])
            checkoutSegmentedControl.selectedSegmentIndex = 0
            checkoutOptionsLabel.text = "Select Shipping Option"
            checkoutProgress.setTitle("Payment", for: .normal)

            let orderData: [String: Any] = [OrderViewController.orderId: Int.random(in: 0...1000) * 1000, OrderViewController.orderCurrency: "USD", OrderViewController.orderTotal: Int.random(in: 0...1000), OrderViewController.screenClass: "OrderViewController"]
            TealiumHelper.trackView(title: "order", dataLayer: orderData)
        }
    }

}

extension UISegmentedControl {
    public func replaceSegments<T: Sequence>(withTitles: T) where T.Iterator.Element == String {
        removeAllSegments()
        for title in withTitles {
            insertSegment(withTitle: title, at: numberOfSegments, animated: false)
        }
    }
}

extension CheckoutViewController: UITextFieldDelegate {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        checkoutTextField1.resignFirstResponder()
        checkoutTextField2.resignFirstResponder()
    }
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

extension CheckoutViewController {
    static let placedOrderClicked = "placed_order_clicked"
    static let screenClass = "screen_class"
}
