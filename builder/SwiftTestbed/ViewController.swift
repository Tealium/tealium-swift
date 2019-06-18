//
//  ViewController.swift
//  SwiftTestbed
//
//  Created by Craig Rouse on 18/04/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    #if os(iOS)
    private var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func track(_ sender: Any) {
        let helper = TealiumHelper.shared
        helper.track(title: "hello", data:
            ["nested_object":["hello":123],
             "array_strings":["123","456"],
             "complex_nested_array": [
                "hello_again":["123","456"],
                ],
            ])
    }
    
}
