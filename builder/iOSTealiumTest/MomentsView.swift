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
    @AppStorage("engineId") private var engineId = ""
    @State private var isEngineIdEditable = true
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Enter Engine ID", text: $engineId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEngineIdEditable)
                    if isEngineIdEditable {
                        Button("Confirm") {
                            isEngineIdEditable = false
                            loadData()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    } else {
                        Button("Edit") {
                            isEngineIdEditable = true
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Button(action: {
                    loadData()
                }) {
                    Text("Moments API Request")
                        .padding()
                        .foregroundColor(.white)
                        .background(isLoading ? Color.gray : Color.blue)
                        .cornerRadius(8)
                }
                .disabled(engineId.isEmpty || isEngineIdEditable || isLoading)
                
                List {
                    RowView(label: "Audiences", content: $audiencesContent)
                    RowView(label: "Badges", content: $badgesContent)
                    RowView(label: "Numbers", content: $numbersContent)
                    RowView(label: "Dates", content: $datesContent)
                    RowView(label: "Strings", content: $stringsContent)
                }
            }
            .navigationBarTitle("Moments API")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            TealiumHelper.shared.trackView(title: "Moments API View", data: nil)
            if !engineId.isEmpty {
                isEngineIdEditable = false
            }
        }
    }
    
    func loadData() {
        isLoading = true
        TealiumHelper.shared.fetchMoments(engineId: engineId) { engineResponse in
            isLoading = false
            switch engineResponse {
            case .success(let engineResponse):
                stringsContent = engineResponse.strings
                    .sorted(by: { $0.key < $1.key })
                    .compactMap {
                        "\($0.key) : \($0.value)"
                    }
                    .joined(separator: "\n")
                audiencesContent = engineResponse.audiences
                    .joined(separator: "\n")
                badgesContent = engineResponse.badges
                    .joined(separator: "\n")
                datesContent = engineResponse.dates
                    .sorted(by: { $0.key < $1.key })
                    .compactMap {
                        "\($0.key) : \($0.value)"
                    }
                    .joined(separator: "\n")
                numbersContent = engineResponse.numbers
                    .sorted(by: { $0.key < $1.key })
                    .compactMap {
                        "\($0.key) : \(String(format: "%.2f", $0.value))"
                    }
                    .joined(separator: "\n")
            case .failure(let error):
                print("Error fetching moments:", error.localizedDescription)
                alertMessage = error.localizedDescription
                if let suggestion = (error as? LocalizedError)?.recoverySuggestion {
                    alertMessage += "\n\(suggestion)"
                }
                showAlert = true
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
