//
//  ContentView.swift
//  iOSTealiumMediaTest
//
//  Created by Christina S on 1/14/21.
//

import SwiftUI
import AVKit
import TealiumMedia

private let demoURL = Bundle.main.url(forResource: "tealium", withExtension: "mp4")!

struct ContentView: View {
    @State private var play: Bool = true
    @State private var time: CMTime = .zero
    @State private var autoReplay: Bool = true
    @State private var mute: Bool = false
    @State private var stateText: String = ""
    @State private var totalDuration: Double = 0
    @State private var started: Bool = false
    @State private var _session: MediaSession?
    
    let media = MediaCollection(name: "Tealium Customer Data Hub",
                                     streamType: .linear,
                                     mediaType: .video,
                                     qoe: QOE(bitrate: 5000))
    
    var mediaSession: MediaSession? {
        get {
            _session ?? TealiumHelper.mediaSession(from: media)
        }
        set {
            _session = newValue
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                CustomVideoPlayer(url: demoURL, play: $play, time: $time)
                    .autoReplay(autoReplay)
                    .mute(mute)
                    .onBufferChanged { progress in
                        mediaSession?.bufferStart()
                        mediaSession?.bufferComplete()
                    }
                    .onPlayToEndTime {
                        mediaSession?.chapterComplete()
                        mediaSession?.stop()
                        mediaSession?.close()
                        time = .zero
                    }
                    .onReplay {
                        mediaSession?.play()
                        mediaSession?.chapterStart(Chapter(name: "Chapter 1", duration: 30))
                    }
                    .onStateChanged { state in
                        switch state {
                        case .loading:
                            self.stateText = "Loading..."
                        case .playing(let totalDuration):
                            self.stateText = "Playing!"
                            self.totalDuration = totalDuration
                            if !started {
                                mediaSession?.start()
                                started = true
                            }
                            mediaSession?.play()
                            mediaSession?.chapterStart(Chapter(name: "Chapter 1", duration: 30))
                        case .paused(let playProgress, let bufferProgress):
                            self.stateText = "Paused: play \(Int(playProgress * 100))% buffer \(Int(bufferProgress * 100))%"
                            mediaSession?.pause()
                        case .error(let error):
                            self.stateText = "Error: \(error)"
                        }
                    }
                    .aspectRatio(1.78, contentMode: .fit)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.7), radius: 6, x: 0, y: 2)
                    .padding()
                
                Text(stateText)
                    .padding()
                
                HStack {
                    IconButtonView(iconName: self.play ? "pause.fill" : "play.fill") {
                        self.play.toggle()
                    }

                    Divider().frame(height: 20)
                    
                    IconButtonView(iconName: self.mute ? "speaker.slash.fill" : "speaker.fill") {
                        self.mute.toggle()
                    }

                    Divider().frame(height: 20)
                    
                    IconButtonView(iconName: "repeat", color: self.autoReplay ? .purple : .gray) {
                        self.autoReplay.toggle()
                    }

                }
                
                HStack {
                    IconButtonView(iconName: "gobackward.15") {
                        self.time = CMTimeMakeWithSeconds(max(0, self.time.seconds - 15), preferredTimescale: self.time.timescale)
                        mediaSession?.seek()
                        mediaSession?.seekComplete()
                    }

                    Divider().frame(height: 20)
                    
                    Text("\(formattedTime) / \(formattedDuration)")
                    
                    Divider().frame(height: 20)
                    
                    IconButtonView(iconName: "goforward.15") {
                        self.time = CMTimeMakeWithSeconds(min(self.totalDuration, self.time.seconds + 15), preferredTimescale: self.time.timescale)
                        mediaSession?.seek()
                        mediaSession?.seekComplete()
                    }
                }.padding()
                
                TextButtonView(title: "Trigger Ad Sequence") {
                    mediaSession?.adBreakStart(AdBreak(title: "Ad Break 1"))
                    mediaSession?.adStart(Ad(name: "Ad 1"))
                    mediaSession?.adSkip()
                    mediaSession?.adStart(Ad(name: "Ad 2"))
                    mediaSession?.adComplete()
                    mediaSession?.adBreakComplete()
                }
                
                Spacer()
            }
            .onDisappear { self.play = false }
            .navigationTitle("iOSTealiumMediaTest")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var formattedTime: String {
        let m = Int(time.seconds / 60)
        let s = Int(time.seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", arguments: [m, s])
    }
    
    var formattedDuration: String {
        let m = Int(totalDuration / 60)
        let s = Int(totalDuration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", arguments: [m, s])
    }
    
    func startSession() {
        
    }
}

struct ButtonView: View {
    var view: AnyView
    var action: () -> Void
    
    init(view: AnyView,
         _ action: @escaping () -> Void) {
        self.view = view
        self.action = action
    }
    
    var body: some View {
        Button(action: action) { view }
    }
}

struct TextButtonView: View {
    var title: String
    var action: () -> Void
    
    init(title: String, _ action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var buttonView: some View {
        Text(title)
           .frame(width: 200.0)
           .padding()
           .background(Color.gray)
           .foregroundColor(.white)
           .cornerRadius(10)
           .shadow(radius: 8)
           .overlay(
               RoundedRectangle(cornerRadius: 10)
                   .stroke(Color.purple, lineWidth: 2)
           )
    }
    
    var body: some View {
        ButtonView(view: AnyView(buttonView)) {
            action()
        }
    }
}

struct IconButtonView: View {
    var iconName: String
    var color: Color = .purple
    var action: () -> Void
    
    var buttonView: some View {
        Image(systemName: iconName)
    }
    
    var body: some View {
        ButtonView(view: AnyView(buttonView)) {
            action()
        }.accentColor(color).font(.title)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
