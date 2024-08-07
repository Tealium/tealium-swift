//
//  VisitorServiceView.swift
//  iOSTealiumTest
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumVisitorService
import SwiftUI

struct VisitorServiceView: View {
    @State private var audiencesContent = "Awaiting API request"
    @State private var badgesContent = "Awaiting API request"
    @State private var numbersContent = "Awaiting API request"
    @State private var datesContent = "Awaiting API request"
    @State private var stringsContent = "Awaiting API request"
    @State private var visitorProfile: TealiumVisitorProfile? = nil
    @ObservedObject var tealiumHelper = TealiumHelper.shared
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Visitor Service Request") {
                    TealiumHelper.shared.track(title: "Some Event", data: [:])
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)

                List {
                    RowView(label: "Audiences", content: $audiencesContent)
                    RowView(label: "Badges", content: $badgesContent)
                    RowView(label: "Numbers", content: $numbersContent)
                    RowView(label: "Dates", content: $datesContent)
                    RowView(label: "Strings", content: $stringsContent)
                }
            }
            .onReceive(tealiumHelper.$visitorProfile) { visitorProfile in
                if let strings = visitorProfile?.strings {
                    self.stringsContent = strings
                        .compactMap({ string in
                        string.value
                    }).joined(separator: "\n")
                }
                
                if let audiences = visitorProfile?.audiences {
                    self.audiencesContent = audiences.compactMap({ string in
                        string.value
                    }).joined(separator: "\n")
                }
                if let badges = visitorProfile?.badges {
                    self.badgesContent = badges.compactMap({ badge in
                        badge.key
                    }).joined(separator: "\n")
                }
                if let dates = visitorProfile?.dates {
                    datesContent = dates
                        .sorted(by: { $0.key < $1.key })
                        .compactMap {
                            "\($0.key) : \($0.value)"
                        }.joined(separator: "\n")
                }
                if let numbers = visitorProfile?.numbers {
                    numbersContent = numbers
                        .sorted(by: { $0.key < $1.key })
                        .compactMap {
                        "\($0.key) : \(String(format: "%.2f", $0.value))"
                    }.joined(separator: "\n")
                }
            }
            .navigationBarTitle("Visitor Service Demo")
        }
    }
}

