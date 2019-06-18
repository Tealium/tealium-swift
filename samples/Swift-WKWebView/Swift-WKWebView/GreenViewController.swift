//
//  GreenViewController.swift
//  Swift-WKWebView
//
//  Created by Craig Rouse on 18/04/2019.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class GreenViewController: UIViewController {

    let teal = TealiumHelper.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.navigationController == nil {
            teal.tealium.updateRootView(self.view)
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        teal.tealium.updateRootView(self.view)
        teal.trackView(title: "Green Screen", data: nil)
    }
    
    @IBAction func trackButtonPress(_ sender: Any) {
        if self.navigationController == nil {
            teal.tealium.updateRootView(self.view)
        }
        print("Green button")
        teal.track(title: "Green Button", data: ["button_name":"Green Button"])
    }
    
    @IBAction func dismissFromView(_ sender: Any) {
        guard self.navigationController != nil else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        self.navigationController?.popToRootViewController(animated: true)
    }
}
