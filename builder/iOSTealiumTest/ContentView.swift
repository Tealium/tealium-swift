//
//  ContentView.swift
//  iOSTealiumTest
//
//  Copyright © 2020 Tealium. All rights reserved.
//
import Combine
import SwiftUI
import StoreKit
import AppTrackingTransparency

class IAPHelper: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = IAPHelper()

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        requestProduct()
    }
    
    func requestProduct() {
         let request = SKProductsRequest(productIdentifiers: ["com.tealium.iOSTealiumTestApp.product1"])
         request.delegate = self
         request.start()
    }

    var product: SKProduct? {
        willSet {
          DispatchQueue.main.async {
            self.objectWillChange.send()
          }
        }
      }
    // Create the SKProductsRequestDelegate protocol method
    // to receive the array of products.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.products.isEmpty {
            product = response.products.first!
        }
    }
    
    func buyProduct() {
        let payment = SKPayment(product: product!)
        SKPaymentQueue.default().add(payment)
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue,
                               updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
          switch transaction.transactionState {
          case .purchased:
            complete(transaction: transaction)
            break
          case .failed:
              break
            break
          case .restored:
              break
            break
          case .deferred:
            break
          case .purchasing:
            break
          }
        }
      }
     
      private func complete(transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
      }
}

struct ContentView: View {
    @ObservedObject var iapHelper = IAPHelper.shared
    @State private var traceId: String = ""
    @State private var showAlert = false
    // Timed event start
    var playButton: some View {
        TealiumIconButton(iconName: "play.fill") {
            TealiumHelper.shared.track(title: "product_view",
                                       data: ["product_id": ["prod123"]])
        }
    }
    
    // Timed event stop
    var stopButton: some View {
        TealiumIconButton(iconName: "stop.fill") {
            TealiumHelper.shared.track(title: "order_complete",
                                       data: ["order_id": "ord123"])
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        TealiumTextField($traceId, imageName: "person.fill", placeholder: "Enter Trace Id")
                            .padding(.bottom, 20)
                        TealiumTextButton(title: "Start Trace") {
                            TealiumHelper.shared.joinTrace(self.traceId)
                        }
                        TealiumTextButton(title: "Leave Trace") {
                            TealiumHelper.shared.leaveTrace()
                        }
                        TealiumTextButton(title: "Track View") {
                            TealiumHelper.shared.trackView(title: "screen_view", data: nil)
                        }
                        TealiumTextButton(title: "Track Event") {
                            TealiumHelper.shared.track(title: "button_tapped",
                                                       data: ["event_category": "example",
                                                              "event_action": "tap",
                                                              "event_label": "Track Event"])
                        }
                        TealiumTextButton(title: "Hosted Data Layer") {
                            TealiumHelper.shared.track(title: "hdl-test",
                                                       data: ["product_id": "abc123"])
                        }
                        TealiumTextButton(title: "SKAdNetwork Conversion") {
                            TealiumHelper.shared.track(title: "conversion_event",
                                                       data: ["conversion_value": 10])
                        }
                        TealiumTextButton(title: "Toggle Consent Status") {
                            TealiumHelper.shared.toggleConsentStatus()
                        }
                        TealiumTextButton(title: "Reset Consent") {
                            TealiumHelper.shared.resetConsentPreferences()
                        }
                        TealiumTextButton(title: "ATT Authorization") {
                            if ATTrackingManager.trackingAuthorizationStatus == ATTrackingManager.AuthorizationStatus.notDetermined {
                                ATTrackingManager.requestTrackingAuthorization { status in
                                    print("ATT Status ", status.rawValue)
                                }
                            } else {
                                showAlert.toggle()
                            }
                        }
                    }
                    Group {
                        if let product = iapHelper.product {
                            TealiumTextButton(title: "Purchase \(product.localizedTitle)") {
                                iapHelper.buyProduct()
                            }
                        }
                    }
                    Spacer()
                }
                .navigationTitle("iOSTealiumTest")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: playButton, trailing: stopButton)
                .padding(36)
                .alert(isPresented: $showAlert, content: {
                    Alert(title: Text("ATT Tracking Authorization Already Asked"), message: Text("Current Consent is: \(ATTrackingManager.AuthorizationStatus.string(from: ATTrackingManager.trackingAuthorizationStatus.rawValue))"), dismissButton: .default(Text("OK")))
                })
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone X"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 8"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 11 SE (1st generation)"))
        }
        
    }
}
