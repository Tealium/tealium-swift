//
//  GamingViewController.swift
//  TealiumVisitorProfileDemo
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import SwiftConfettiView
import TealiumSwift
import UIKit

class GamingViewController: UIViewController {

    @IBOutlet weak var startTutorialButton: UIButton!
    @IBOutlet weak var stopTutorialButton: UIButton!
    @IBOutlet weak var achievementLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!

    var confettiView: SwiftConfettiView?

    var data = [String: Any]()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        TealiumHelper.trackScreen(self, name: "gaming")

        let confettiView = SwiftConfettiView(frame: self.view.bounds)
        self.view.addSubview(confettiView)
        confettiView.type = .star
        self.view.sendSubviewToBack(confettiView)

        TealiumHelper.updateExperience(basedOn: .highscorers) {
            self.confettiHandling(confettiView)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
    }

    func confettiHandling(_ confetti: SwiftConfettiView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.view.sendSubviewToBack(self.view)
            confetti.startConfetti()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 2.0) {
                confetti.stopConfetti()
            }
        }
    }

    @objc func share() {
        TealiumHelper.trackEvent(name: "share", dataLayer: [GamingViewController.contentType: "gaming screen", GamingViewController.shareId: "gamqwe123"])
        let vc = UIActivityViewController(activityItems: ["Gaming"], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }

    @IBAction func spendCurrency(_ sender: UIButton) {
        TealiumHelper.trackEvent(name: "spend_currency", dataLayer: [GamingViewController.productName: ["jewels"], "currency_type": GamingViewController.tokens, "number_of_tokens": 50])
    }

    @IBAction func earnCurrency(_ sender: UIButton) {
        TealiumHelper.trackEvent(name: "earn_currency", dataLayer: [GamingViewController.currencyType: "tokens", GamingViewController.tokens: 100])
    }

    @IBAction func achievementSwitch(_ sender: UISwitch) {
        if sender.isOn {
            TealiumHelper.trackEvent(name: "unlock_achievement", dataLayer: [GamingViewController.achievementId: "\(Int.random(in: 1...1000))"])
            achievementLabel.text = "Lock Achievement"
        } else {
            achievementLabel.text = "Unlock Achievement"
        }

    }

    @IBAction func levelStepper(_ sender: UIStepper) {
        levelLabel.text = String(Int(sender.value))
        data[GamingViewController.level] = String(Int(sender.value))
        data[GamingViewController.character] = "mario"
        TealiumHelper.trackEvent(name: "level_up", dataLayer: data)
    }

    @IBAction func startTutorial(_ sender: UIButton) {
        TealiumHelper.trackEvent(name: "start_tutorial", dataLayer: nil)
    }

    @IBAction func stopTutorial(_ sender: UIButton) {
        TealiumHelper.trackEvent(name: "stop_tutorial", dataLayer: nil)
    }

    @IBAction func postScore(_ sender: Any) {
        data[GamingViewController.score] = Int.random(in: 1...1000) * 1000
        TealiumHelper.trackEvent(name: "record_score", dataLayer: data)
    }

}

extension GamingViewController {
    static let contentType = "content_type"
    static let shareId = "share_id"
    static let productName = "product_name"
    static let currencyType = "currency_type"
    static let tokens = "tokens"
    static let achievementId = "acheivement_id"
    static let level = "level"
    static let character = "character"
    static let score = "score"
}
