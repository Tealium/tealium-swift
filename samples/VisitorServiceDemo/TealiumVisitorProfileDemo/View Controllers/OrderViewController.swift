//
//  OrderViewController.swift
//  TealiumVisitorProfileDemo
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

// Image Credit: https://www.flaticon.com/authors/smashicons 🙏
class OrderViewController: UIViewController {

    @IBOutlet weak var orderNumber: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        orderNumber.text = "Thank you! Your order number is: ORDABC\(Int.random(in: 0...1000) * 1000)"
    }

}

extension OrderViewController {
    static let screenClass = "screen_class"
    static let orderId = "order_id"
    static let orderCurrency = "order_currency"
    static let orderTotal = "order_total"
}
