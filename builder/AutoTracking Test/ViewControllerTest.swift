// 
// ViewControllerTest.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TealiumCore
import TealiumAutotracking

struct ViewControllerWrapper: View, UIViewControllerRepresentable {
    typealias UIViewControllerType = ViewControllerTest
    
    func makeUIViewController(context: Context) -> ViewControllerTest {
        let controller = ViewControllerTest()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ViewControllerTest, context: Context) {
        
    }
}

struct ViewControllerWrapper_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




class ViewControllerTest: TealiumViewController {
    
    var headerView: UIView!
    var titleLabel: UILabel!
    var _title: String? = "RealViewController"
    override var title: String? {
        get {
            _title
        }
        set {
            _title = newValue
        }
    }
    var numbersCollectionView: UICollectionView!
//    let numbersCollectionViewDelegateAndDataSource = NumbersCollectionViewDelegateAndDataSource()
    
    @objc
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupHeaderAndTitleLabel()
    }
    
    func setupHeaderAndTitleLabel() {
        // Initialize views and add them to the ViewController's view
        headerView = UIView()
        headerView.backgroundColor = .red
        self.view.addSubview(headerView)
        
        titleLabel = UILabel()
        titleLabel.text = "Wrapped View Controller"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: titleLabel.font.fontName, size: 20)
        headerView.addSubview(titleLabel)
        
        // Set position of views using constraints
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        headerView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1).isActive = true
        headerView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.1).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: headerView.widthAnchor, multiplier: 0.4).isActive = true
        titleLabel.heightAnchor.constraint(equalTo: headerView.heightAnchor, multiplier: 0.5).isActive = true
    }
    
    
}
