//
//  CategoryViewController.swift
//  TealiumVisitorProfileDemo
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

// Image Credit: https://www.flaticon.com/authors/xnimrodx 🙏
class CategoryViewController: UIViewController {

    var products = [String]()
    var prices = Array(30...1000)

    override func viewDidLoad() {
        super.viewDidLoad()
        products = ["1-blender", "2-fan", "3-iron", "4-kettle", "5-lamp",
                    "6-oven", "7-fridge", "8-scale", "9-stove", "10-toaster",
                    "11-television", "12-vacuum"]
        prices.shuffle()
    }

}

extension CategoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let productImageName = products[indexPath.item]
        let productName = products[indexPath.item].split(separator: "-")[1].capitalized
        let productPrice = "$\(prices[indexPath.item])"
        let notification = Notification(name: Notification.Name(CategoryViewController.productClicked), object: self, userInfo: [CategoryViewController.productImageName: productImageName, CategoryViewController.productName: productName, CategoryViewController.productPrice: productPrice])
        NotificationCenter.default.post(notification)
    }
}

extension CategoryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductImage", for: indexPath) as? ProductCell else {
            fatalError("Unable to dequeue ProductCell")
        }
        let product = products[indexPath.item]
        let productName = product.split(separator: "-")[1].capitalized
        cell.imageView.image = UIImage(named: product)
        cell.name.text = productName
        cell.price.text = "$\(prices[indexPath.item])"

        return cell
    }
}

extension CategoryViewController {
    static let productClicked = "product_clicked"
    static let productImageName = "product_image_name"
    static let productName = "product_name"
    static let productPrice = "product_price"
    static let categoryName = "category_name"
    static let screenClass = "screen_class"
}
