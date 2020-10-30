//
//  LoginViewController.swift
//  TealiumVisitorProfileDemo
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

// Image Credit: https://www.flaticon.com/authors/freepik 🙏
class LoginViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TealiumHelper.trackScreen(self, name: "login")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        password.isSecureTextEntry = true
        username.delegate = self
        password.delegate = self
    }

    @IBAction func onLogin(_ sender: Any) {
        TealiumHelper.trackEvent(name: "user_login", dataLayer: [LoginViewController.customerId: username.text ?? "ABC123", LoginViewController.signUpMethod: "apple", LoginViewController.username: username.text!])
    }

}

extension LoginViewController: UITextFieldDelegate {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        username.resignFirstResponder()
        password.resignFirstResponder()
    }
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

extension LoginViewController {
    static let customerId = "customer_id"
    static let signUpMethod = "signup_method"
    static let username = "username"
}

extension LoginViewController {
    override func loadView() {
        super.loadView()
        let ac = UIAlertController(title: "Enter Trace ID", message: nil, preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "Start Trace", style: .default) { [unowned ac] _ in
            guard let trace = ac.textFields![0].text else {
                return
            }
            tealiumTraceId = trace
            TealiumHelper.joinTrace(id: tealiumTraceId)
        }

        ac.addAction(submitAction)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
}
