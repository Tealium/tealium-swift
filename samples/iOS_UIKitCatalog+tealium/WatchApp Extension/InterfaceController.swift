//
//  InterfaceController.swift
//  WatchApp Extension
//
//  Created by Craig Rouse on 14/11/2018.
//  Copyright © 2018 Apple. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        TealiumHelper.shared.start()
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    @IBAction func track() {
        print("track")
        let helper = TealiumHelper.shared
        helper.track(title: "Hello from watchOS", data: ["screen": "Main Interface Controller"])
    }
    
}
