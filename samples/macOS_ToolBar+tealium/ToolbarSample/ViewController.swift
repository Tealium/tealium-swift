/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The primary view controller holding the toolbar and text view.
 */

import Cocoa

class ViewController: NSViewController, NSTextViewDelegate {

    @IBOutlet var textView: NSTextView!
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.textView.delegate = self
        if #available(OSX 10.12.1, *) {
            // Opt-out of text completion in this simplified version.
            if ((NSClassFromString("NSTouchBar")) != nil) {
                self.textView?.isAutomaticTextCompletionEnabled = false
            }
        } else {
            // Fallback on earlier versions
        }
        
        self.view.window?.makeFirstResponder(self.textView)
        
        // Do any additional setup after loading the view.
        
        let tealium = Tealium(config: defaultTealiumConfig)
        
        tealium.track(type: TealiumTrackType.activity,
                       title: "test",
                       data: nil,
                       completion: { (success, info, error) in
                        
                        guard let info = info else {
                            print("Tealium Test track complete with no callback info returned.")
                            return
                        }
                        
                        print("Tealium Test track complete with callback info: \n \(info)")

        })
    }

    override var representedObject: Any?
    {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // MARK: - NSTextViewDelegate
    
    func textView(_ textView: NSTextView, shouldUpdateTouchBarItemIdentifiers identifiers: [NSTouchBarItemIdentifier]) -> [NSTouchBarItemIdentifier] {
        
        return []   // We want to show only our NSTouchBarItem instances.
    }
    
}
