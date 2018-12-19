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
        
        #if AUTOTRACKING
            print("Autotracking Enabled for MasterViewController")
            TealiumAutotracking.addCustom(data: ["customAutotrackingKey":"customAutotrackingValue"], toObject: self)
        #endif
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if AUTOTRACKING
            print("Autotracking detected for MasterViewController")
        #else
            
            let helper = TealiumHelper.shared
            helper.trackView(title: "MasterViewController",
                             data: ["autotracked":"false"])
        #endif
    }
    
    @IBAction func unwindInMaster(_ segue: UIStoryboardSegue)  {
        /*
            Empty. Exists solely so that "unwind in master" segues can
            find this instance as a destination.
        */
    }
}
