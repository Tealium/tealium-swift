//
//  ContentView.swift
//  SwiftUIWebView
//
//  Copyright © 2020 Tealium. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()
    @State var showLoader = false
    @State var message = ""
    @State var webTitle = ""

    var webViewNavigationBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Spacer()
                Button(action: {
                    self.viewModel.webViewNavigationPublisher.send(.backward)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.gray)
                }
                Group {
                    Spacer()
                    Divider()
                    Spacer()
                }
                Button(action: {
                    self.viewModel.webViewNavigationPublisher.send(.forward)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.gray)
                }
                Group {
                    Spacer()
                    Divider()
                    Spacer()
                }
                Button(action: {
                    self.viewModel.webViewNavigationPublisher.send(.reload)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.gray).padding(.bottom, 4)
                }
                Spacer()
            }.frame(height: 45)
            Divider()
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text(webTitle).font(.title).onReceive(self.viewModel.showWebTitle.receive(on: RunLoop.main)) { value in
                    self.webTitle = value
                }
                WebView(url: TealiumHelper.shared.webViewType, viewModel: viewModel).overlay(
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .stroke(Color.gray, lineWidth: 0.5)
                ).padding(.leading, 20).padding(.trailing, 20)

                webViewNavigationBar
            }.onReceive(self.viewModel.showLoader.receive(on: RunLoop.main)) { value in
                self.showLoader = value
            }
            if showLoader {
                Loader()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
