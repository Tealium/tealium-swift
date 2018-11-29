//
//  ViewController.swift
//  MacOSApp
//
//  Created by Craig Rouse on 14/11/2018.
//  Copyright © 2018 Apple. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        TealiumHelper.shared.start()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func track(_ sender: Any) {
        let helper = TealiumHelper.shared
        helper.track(title: "Hello from macOS", data: ["screen": "Main View Controller"])
    }
    
}

