//
//  ViewController.swift
//  TVApp
//
//  Created by Craig Rouse on 14/11/2018.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    @IBAction func track(_ sender: Any) {
        let helper = TealiumHelper.shared
        helper.track(title: "Hello from tvOS", data: ["screen": "Main View Controller"])
    }
}

