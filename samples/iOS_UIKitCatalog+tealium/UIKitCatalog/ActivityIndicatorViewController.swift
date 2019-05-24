/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIActivityIndicatorView.
*/

import UIKit

class ActivityIndicatorViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var grayStyleActivityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var tintedActivityIndicatorView: UIActivityIndicatorView!
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureGrayActivityIndicatorView()
        configureTintedActivityIndicatorView()
        
        // When activity is done, use UIActivityIndicatorView.stopAnimating().
    }
    
    // MARK: - Configuration

    func configureGrayActivityIndicatorView() {
        grayStyleActivityIndicatorView.style = .gray
        
        grayStyleActivityIndicatorView.startAnimating()
        
        grayStyleActivityIndicatorView.hidesWhenStopped = true
    }
    
    func configureTintedActivityIndicatorView() {
        tintedActivityIndicatorView.style = .gray
        
        tintedActivityIndicatorView.color = UIColor.applicationPurpleColor
        
        tintedActivityIndicatorView.startAnimating()
    }
}
