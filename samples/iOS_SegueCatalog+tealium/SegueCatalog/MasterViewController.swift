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
            TealiumAutotracking.addCustom(data: ["customAutotrackingKey":"customAutotrackingValue"], toObject: self)
        #endif
    
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if AUTOTRACKING
        #else
        TealiumHelper.sharedInstance().trackView(title: "MasterViewController",
                                                 data: ["someManuallyAddedKey":"someManuallyAddedValue"])
        #endif
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
    }
    
    @IBAction func unwindInMaster(_ segue: UIStoryboardSegue)  {
        /*
            Empty. Exists solely so that "unwind in master" segues can
            find this instance as a destination.
        */
    }
}
