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
import TealiumAutotracking
import TealiumCore
import TealiumInAppPurchase
import TealiumVisitorService

// StoreKit 2 Product requires iOS 15, while the demo app deploys to iOS 14.1.
@available(iOS 15, *)
@MainActor
class IAPHelper: ObservableObject {
    static let shared = IAPHelper()

    @Published var product: Product?

    init() {
        Task {
            product = try? await Product.products(for: ["com.tealium.iOSTealiumTestApp.product1"]).first
        }
    }

    func buyProduct() {
        guard let product = product else { return }
        Task {
            guard case .success(.verified(let transaction)) = try? await product.purchase() else { return }
            // StoreKit returns purchases made on this device to the purchase call and doesn't promise to emit them
            // on Transaction.updates, so they're tracked manually. Tealium sends one event even if both paths see it.
            TealiumHelper.shared.tealium?.inAppPurchase?.track(transaction)
            await transaction.finish()
        }
    }
}

@available(iOS 15, *)
struct PurchaseButton: View {
    @ObservedObject var iapHelper = IAPHelper.shared

    var body: some View {
        if let product = iapHelper.product {
            TealiumTextButton(title: "Purchase \(product.displayName)") {
                iapHelper.buyProduct()
            }
        }
    }
}

struct ContentView: View {
    @State private var traceId: String = ""
    @State private var showAlert = false
    @State private var navigateToMoments = false
    @State private var navigateToVisitorService = false
    @State private var email: String = TealiumHelper.shared.tealium?.dataLayer.all[TealiumDataKey.email] as? String ?? ""
    let name = "Main Screen"
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
        TealiumViewTrackable(constantName: name) {
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
                        if #available(iOS 15, *) {
                            PurchaseButton()
                        }
                        TealiumTextField($email, placeholder: "Enter email") {
                            applyEmail()
                        }
                        TealiumTextButton(title: "Clear Stored Visitor IDs") {
                            TealiumHelper.shared.tealium?.clearStoredVisitorIds()
                        }
                        TealiumTextButton(title: "Reset Visitor ID") {
                            TealiumHelper.shared.tealium?.resetVisitorId()
                        }
                        TealiumTextButton(title: "VisitorProfileRequest") {
                            TealiumHelper.shared.tealium?.visitorService?.requestVisitorProfile()
                        }
                        TealiumTextButton(title: "Moments API") {
                            navigateToMoments = true
                        }
                        TealiumTextButton(title: "Visitor Service") {
                            navigateToVisitorService = true
                        }
                        NavigationLink(destination: MomentsView(), isActive: $navigateToMoments) {
                              EmptyView()
                        }
                        NavigationLink(destination: VisitorServiceView(), isActive: $navigateToVisitorService) {
                              EmptyView()
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
    }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            print("onappear from app")
        }
    }
    
    func applyEmail() {
        if email.isEmpty {
            TealiumHelper.shared.tealium?.dataLayer.delete(for: TealiumDataKey.email)
        } else {
            TealiumHelper.shared.tealium?.dataLayer.add(key: TealiumDataKey.email, value: email, expiry: .forever)
        }
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
