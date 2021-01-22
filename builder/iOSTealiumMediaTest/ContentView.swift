//
//  ContentView.swift
//  iOSTealiumMediaTest
//
//  Created by Christina S on 1/14/21.
//

import SwiftUI
import AVKit
import TealiumMedia

struct ContentView: View {
    @State private var video = Video()
    @State private var _session: MediaSession?
    private let demoURL = Bundle.main.url(forResource: "tealium", withExtension: "mp4")!
    private let media = MediaCollection(name: "Tealium Customer Data Hub",
                                     streamType: .linear,
                                     mediaType: .video,
                                     qoe: QoE(bitrate: 5000))
    
    
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
                CustomVideoPlayer(url: demoURL, play: $video.play, time: $video.time)
                    .autoReplay(video.autoReplay)
                    .mute(video.mute)
                    .onBufferChanged { progress in
                        mediaSession?.startBuffer()
                        mediaSession?.endBuffer()
                    }
                    .onPlayToEndTime {
                        mediaSession?.endChapter()
                        mediaSession?.stop()
                        mediaSession?.endSession()
                        video.time = .zero
                    }
                    .onReplay {
                        mediaSession?.play()
                        mediaSession?.startChapter(Chapter(name: "Chapter 1", duration: 30))
                    }
                    .onStateChanged { state in
                        switch state {
                        case .loading:
                            self.video.stateText = "Loading..."
                        case .playing(let totalDuration):
                            self.video.stateText = "Playing!"
                            self.video.totalDuration = totalDuration
                            if !video.started {
                                mediaSession?.startSession()
                                video.started = true
                            }
                            mediaSession?.play()
                            mediaSession?.startChapter(Chapter(name: "Chapter 1", duration: 30))
                        case .paused(let playProgress, let bufferProgress):
                            self.video.stateText = "Paused: play \(Int(playProgress * 100))% buffer \(Int(bufferProgress * 100))%"
                            mediaSession?.pause()
                        case .error(let error):
                            self.video.stateText = "Error: \(error)"
                        }
                    }
                    .aspectRatio(1.78, contentMode: .fit)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.7), radius: 6, x: 0, y: 2)
                    .padding()
                
                Text(video.stateText)
                    .padding()
                
                HStack {
                    IconButtonView(iconName: self.video.play ? "pause.fill" : "play.fill") {
                        self.video.play.toggle()
                    }

                    Divider().frame(height: 20)
                    
                    IconButtonView(iconName: self.video.mute ? "speaker.slash.fill" : "speaker.fill") {
                        self.video.mute.toggle()
                    }

                    Divider().frame(height: 20)
                    
                    IconButtonView(iconName: "repeat", color: self.video.autoReplay ? .tealBlue : .gray) {
                        self.video.autoReplay.toggle()
                    }

                }
                
                HStack {
                    IconButtonView(iconName: "gobackward.15") {
                        self.video.time = CMTimeMakeWithSeconds(max(0, self.video.time.seconds - 15),
                                                                preferredTimescale: self.video.time.timescale)
                        mediaSession?.startSeek()
                        mediaSession?.endSeek()
                    }

                    Divider().frame(height: 20)
                    
                    Text("\(formattedTime) / \(formattedDuration)")
                    
                    Divider().frame(height: 20)
                    
                    IconButtonView(iconName: "goforward.15") {
                        self.video.time = CMTimeMakeWithSeconds(min(self.video.totalDuration,
                                                                    self.video.time.seconds + 15),
                                                                preferredTimescale: self.video.time.timescale)
                        mediaSession?.startSeek()
                        mediaSession?.endSeek()
                    }
                }.padding()
                
                TextButtonView(title: "Trigger Ad Sequence") {
                    mediaSession?.startAdBreak(AdBreak(title: "Ad Break 1"))
                    mediaSession?.startAd(Ad(name: "Ad 1"))
                    mediaSession?.skipAd()
                    mediaSession?.startAd(Ad(name: "Ad 2"))
                    mediaSession?.endAd()
                    mediaSession?.endAdBreak()
                }
                
                Spacer()
            }
            .onDisappear { self.video.play = false }
            .navigationTitle("iOSTealiumMediaTest")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var formattedTime: String {
        let m = Int(video.time.seconds / 60)
        let s = Int(video.time.seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", arguments: [m, s])
    }
    
    var formattedDuration: String {
        let m = Int(video.totalDuration / 60)
        let s = Int(video.totalDuration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", arguments: [m, s])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
