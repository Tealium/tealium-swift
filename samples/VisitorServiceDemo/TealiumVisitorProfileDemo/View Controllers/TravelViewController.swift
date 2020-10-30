//
//  TravelViewController.swift
//  TealiumVisitorProfileDemo
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import SCLAlertView
import TealiumSwift
import UIKit

class TravelViewController: UIViewController {

    @IBOutlet weak var originTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var numberOfPassengersLabel: UILabel!
    @IBOutlet weak var numberOfRoomsLabel: UILabel!
    @IBOutlet weak var travelClassLabel: UISegmentedControl!
    var alertShown = false

    var data = [String: Any]()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        TealiumHelper.trackScreen(self, name: "travel")

        TealiumHelper.updateExperience(basedOn: .travelers) {
            DispatchQueue.main.async {
                if !self.alertShown { // remove this if block to show alert every time tab is clicked
                    self.alertShown = true
                    self.showAlert()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        originTextField.delegate = self
        destinationTextField.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self

        travelClassLabel.selectedSegmentIndex = 2
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
    }

    @objc func share() {
        TealiumHelper.trackEvent(name: "share", dataLayer: [TravelViewController.contentType: "travel screen", TravelViewController.shareId: "traqwe123"])
        let vc = UIActivityViewController(activityItems: ["Travel"], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }

    @IBAction func changeNumberOfPassengers(_ sender: UIStepper) {
        numberOfPassengersLabel.text = String(Int(sender.value))
        data[TravelViewController.passengers] = String(Int(sender.value))
    }

    @IBAction func changeNumberOfRooms(_ sender: UIStepper) {
        numberOfRoomsLabel.text = String(Int(sender.value))
        data[TravelViewController.rooms] = String(Int(sender.value))
    }

    @IBAction func changeTravelClass(_ sender: UISegmentedControl) {
        data[TravelViewController.travelClass] = sender.titleForSegment(at: sender.selectedSegmentIndex)
    }

    @IBAction func submit(_ sender: UIButton) {
        guard let stringStartDate = startDateTextField.text else { return }
        guard let stringEndDate = endDateTextField.text else { return }
        guard let endDate = stringEndDate.toDate(with: "MMddyyyy") else { return }
        guard let startDate = stringStartDate.toDate(with: "MMddyyyy") else { return }
        let numberOfNights = endDate.daysFrom(earlierDate: startDate)
        data[TravelViewController.origin] = originTextField.text
        data[TravelViewController.destination] = destinationTextField.text
        data[TravelViewController.startDate] = stringStartDate
        data[TravelViewController.endDate] = stringEndDate
        data[TravelViewController.nights] = numberOfNights
        TealiumHelper.trackEvent(name: "travel_order", dataLayer: data)
    }

    func showAlert() {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 24)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: true
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.showSuccess("You travel a lot!",
                          subTitle: "Take 10% off your next flight!",
                          closeButtonTitle: "OK",
                          animationStyle: .topToBottom)
    }

}

extension TravelViewController: UITextFieldDelegate {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        originTextField.resignFirstResponder()
        destinationTextField.resignFirstResponder()
        startDateTextField.resignFirstResponder()
        endDateTextField.resignFirstResponder()
    }
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

extension TravelViewController {
    static let contentType = "content_type"
    static let shareId = "share_id"
    static let passengers = "number_of_passengers"
    static let rooms = "number_of_rooms"
    static let travelClass = "travel_class"
    static let origin = "travel_origin"
    static let destination = "travel_destination"
    static let startDate = "travel_start_date"
    static let endDate = "travel_end_date"
    static let nights = "number_of_nights"
}
