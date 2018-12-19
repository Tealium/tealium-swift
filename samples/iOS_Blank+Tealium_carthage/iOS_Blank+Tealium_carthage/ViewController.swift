//
//  ViewController.swift
//  iOS_Blank+Tealium_carthage
//
//  Created by Jason Koo on 7/25/17.
//  Copyright © 2017 tealium. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var triggerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TealiumHelper.shared.tealium?.autotracking()?.addCustom(data: ["customAutotrackingKey":"customAutotrackingValue"], toObject: triggerButton)
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if AUTOTRACKING
            print("*** ViewController: showing autotracking enabled.")
        #else
            print("*** ViewController: showing autotracking disabled.")
            TealiumHelper.shared.tealium?.trackView(title: "testView",
                                                              data: nil,
                                                              completion: { (success, info, error) in
                                                                
                        //
            })
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func triggerTrack(_ sender: Any) {

        #if AUTOTRACKING
        #else
        TealiumHelper.shared.track(title: "test",
                                             data: nil)
        #endif
    }

}

