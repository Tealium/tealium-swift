//
//  BlueViewController.swift
//  Swift-WKWebView
//
//  Created by Craig Rouse on 18/04/2019.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class BlueViewController: UIViewController {

    let teal = TealiumHelper.shared
    @IBOutlet weak var traceId: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        traceId.delegate = self
        view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        teal.trackView(title: "Blue Screen", data: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func onPush(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let greenViewController = storyBoard.instantiateViewController(withIdentifier: "GreenViewController")
        navigationController?.show(greenViewController, sender: nil)
    }
    
    @IBAction func trackButtonPress(_ sender: Any) {
        print("Blue button")
        teal.track(title: "Blue Button", data: ["button_name":"Blue Button"])
    }
}

extension BlueViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let id = textField.accessibilityIdentifier, id == "traceId" {
            if let traceIdText = textField.text, traceIdText.count == 5 {
                TealiumHelper.shared.joinTrace(traceId: traceIdText)
            } else {
                traceId.text = ""
                TealiumHelper.shared.leaveTrace()
            }
        }
    }
}
