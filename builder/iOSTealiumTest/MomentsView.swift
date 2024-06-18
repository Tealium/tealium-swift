//
//  MomentsView.swift
//  iOSTealiumTest
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import SwiftUI

struct MomentsView: View {
    @State private var audiencesContent = "Awaiting API request"
    @State private var badgesContent = "Awaiting API request"
    @State private var numbersContent = "Awaiting API request"
    @State private var datesContent = "Awaiting API request"
    @State private var stringsContent = "Awaiting API request"
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Moments API Request") {
                        loadData()
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
            .navigationBarTitle("Moments API")
        }.onAppear {
            TealiumHelper.shared.trackView(title: "Moments API View", data: nil)
        }
    }

    func loadData() {
        TealiumHelper.shared.fetchMoments { engineResponse in
                switch engineResponse {
                case .success(let engineResponse):
                    stringsContent = engineResponse.strings
                        .sorted(by: { $0.key < $1.key })
                        .compactMap {
                        "\($0.key) : \($0.value)"
                    }.joined(separator: "\n")
                    audiencesContent = engineResponse.audiences
                        .joined(separator: "\n")
                    badgesContent = engineResponse.badges
                        .joined(separator: "\n")
                    datesContent = engineResponse.dates
                        .sorted(by: { $0.key < $1.key })
                        .compactMap {
                        "\($0.key) : \($0.value)"
                    }.joined(separator: "\n")
                    numbersContent = engineResponse.numbers
                        .sorted(by: { $0.key < $1.key })
                        .compactMap {
                        "\($0.key) : \(String(format: "%.2f", $0.value))"
                    }.joined(separator: "\n")
                case .failure(let error):
                    print("Error fetching moments:", error.localizedDescription)
                    if let suggestion = (error as? LocalizedError)?.recoverySuggestion {
                        print("Recovery suggestion:", suggestion)
                    }
            }
            
        }
    }
}

struct RowView: View {
    var label: String
    @Binding var content: String

    var body: some View {
        HStack {
            Text(label + ":")
                .bold()
            Spacer()
            Text(content)
        }
    }
}
