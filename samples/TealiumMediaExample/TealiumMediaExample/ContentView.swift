//
//  ContentView.swift
//  TealiumMediaExample
//

import SwiftUI
import AVKit
import TealiumSwift

struct ContentView: View {
    @State private var video = Video()
    @State private var _session: MediaSession?
    private let demoURL = Bundle.main.url(forResource: "tealium", withExtension: "mp4")!
    private let media = MediaContent(name: "Tealium Customer Data Hub",
                                        streamType: .dvod,
                                        mediaType: .video,
                                        qoe: QoE(bitrate: 5000),
                                        trackingType: .interval, // change to test different types
                                        state: .closedCaption,
                                        duration: 130)
    
    
    var mediaSession: MediaSession? {
        get {
            _session
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
                        // Simulate bitrate change
                        mediaSession?.bitrate = 4000
                        mediaSession?.endBuffer()
                    }
                    .onPlayToEndTime {
                        // When content plays to end, end the chapter, content, and session
                        mediaSession?.endChapter()
                        mediaSession?.endContent()
                        mediaSession?.endSession()
                        video.time = .zero
                    }
                    .onReplay {
                        // Restart media and chapter
                        mediaSession?.play()
                        mediaSession?.startChapter(Chapter(name: "Chapter 1", duration: 30))
                    }
                    .onStateChanged { state in
                        switch state {
                        case .loading:
                            video.stateText = "Loading..."
                        case .playing(let totalDuration):
                            guard !video.isBackgrounded else { return }
                            video.paused = false
                            video.stateText = "Playing!"
                            video.totalDuration = totalDuration
                            if !video.started {
                                // If state is playing and video has not already started, start session
                                mediaSession?.startSession()
                                video.started = true
                            }
                            mediaSession?.play()
                            if !video.started {
                                // If state is playing and video has not already started, start chapter
                                mediaSession?.startChapter(Chapter(name: "Chapter 1", duration: 30))
                            }
                        case .paused(let playProgress, let bufferProgress):
                            video.stateText = "Paused: play \(Int(playProgress * 100))% buffer \(Int(bufferProgress * 100))%"
                            if !video.paused {
                                mediaSession?.pause()
                                video.paused = true
                            }
                        case .error(let error):
                            video.stateText = "Error: \(error)"
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            // For older devices, make sure Teal has been initialized before starting session
                            _session = TealiumHelper.mediaSession(from: media)
                            self.video.play = true
                        })
                    }
                    .aspectRatio(1.78, contentMode: .fit)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.7), radius: 6, x: 0, y: 2)
                    .padding()
                
                Text(video.stateText)
                    .padding()
                
                HStack {
                    TealiumIconButton(iconName: self.video.play ? "pause.fill" : "play.fill") {
                        self.video.play.toggle()
                    }

                    Divider().frame(height: 20)
                    
                    // Update player state on toggle
                    TealiumIconButton(iconName: self.video.mute ? "speaker.slash.fill" : "speaker.fill") {
                        self.video.mute.toggle()
                        if self.mediaSession?.playerState == .mute {
                            self.mediaSession?.playerState = .closedCaption
                        }
                        self.mediaSession?.playerState = .mute
                    }

                    Divider().frame(height: 20)
                    
                    TealiumIconButton(iconName: "repeat", color: self.video.autoReplay ? .tealBlue : .gray) {
                        self.video.autoReplay.toggle()
                    }

                }
                
                HStack {
                    TealiumIconButton(iconName: "gobackward.15") {
                        mediaSession?.startSeek(at: self.video.time.seconds)
                        self.video.time = CMTimeMakeWithSeconds(max(0, self.video.time.seconds - 15),
                                                                preferredTimescale: self.video.time.timescale)
                        mediaSession?.endSeek(at: self.video.time.seconds)
                        // Simulate dropped frames
                        mediaSession?.droppedFrames = 15
                    }

                    Divider().frame(height: 20)
                    
                    Text("\(formattedTime) / \(formattedDuration)")
                    
                    Divider().frame(height: 20)
                    
                    TealiumIconButton(iconName: "goforward.15") {
                        mediaSession?.startSeek(at: self.video.time.seconds)
                        self.video.time = CMTimeMakeWithSeconds(min(self.video.totalDuration,
                                                                    self.video.time.seconds + 15),
                                                                preferredTimescale: self.video.time.timescale)
                        mediaSession?.endSeek(at: self.video.time.seconds)
                        // Simulate dropped frames
                        mediaSession?.droppedFrames = 20
                    }
                }.padding()
                
                TealiumTextButton(title: "Chapter 1 Skip") {
                    mediaSession?.skipChapter()
                    mediaSession?.startChapter(Chapter(name: "Chapter 2", duration: 30))
                }
                
                TealiumTextButton(title: "Ad 1 Start") {
                    self.video.play = false
                    mediaSession?.startAdBreak(AdBreak(name: "Ad Break 1"))
                    mediaSession?.startAd(Ad(name: "Ad 1"))
                }
                
                TealiumTextButton(title: "Ad 1 Skip, Ad 2 Start") {
                    mediaSession?.skipAd()
                    mediaSession?.startAd(Ad(name: "Ad 2"))
                }
                
                TealiumTextButton(title: "Ad 2 Complete") {
                    self.video.play = true
                    mediaSession?.endAd()
                    mediaSession?.endAdBreak()
                }
                
                Spacer()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    self.video.isBackgrounded = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    self.video.isBackgrounded = false
                    self.video.started = false
                    self.mediaSession?.backgroundStatusResumed = true
                    
            }
            .onDisappear { self.video.play = false }
            .navigationTitle("TealiumMediaTest")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var formattedTime: String {
        let m = Int(video.time.seconds / 60)
        let s = Int(video.time.seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", arguments: [m, s])
    }
    
    private var formattedDuration: String {
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
