/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controller used as the root of the split view's master-side navigation controller.
*/

import UIKit

class MasterViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        let extraData : [String:Any] = ["Key" : "value"]

        TealiumHelper.sharedInstance().track(title: "test",
                                             data: extraData)
    
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        let extraData : [String:Any] = ["screen_title" : "masterViewController",
                                        "tealium_event_type" : "view"]
        
        TealiumHelper.sharedInstance().track(title: "view",
                                             data: extraData)
        
    }
    
    @IBAction func unwindInMaster(_ segue: UIStoryboardSegue)  {
        /*
            Empty. Exists solely so that "unwind in master" segues can
            find this instance as a destination.
        */
    }
}
