//
//  MediaModule.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//
#if !os(tvOS) && !os(macOS)
import UIKit
#endif
#if media
import TealiumCore
#endif

public class MediaModule: Collector {
    
    public var id: String = "Media"
    public var config: TealiumConfig
    public var data: [String : Any]?
    weak var delegate: ModuleDelegate?
    var activeSessions = [MediaSession]()
    
    public required init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.config = context.config
        self.delegate = delegate
        #if !os(tvOS) && !os(macOS)
        Tealium.lifecycleListeners.addDelegate(delegate: self)
        #endif
    }
    
    /// Creates a `MediaSession` for a given tracking type
    /// - Parameter media: `MediaCollection` containing meta information
    /// - Returns: `MediaSession` type
    public func createSession(from media: MediaContent) -> MediaSession {
        let session = MediaSessionFactory.create(from: media, with: delegate)
        activeSessions.append(session)
        return session
    }
    
}
#if !os(tvOS) && !os(macOS)
extension MediaModule: TealiumLifecycleEvents {
    
    #if os(iOS)
    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif
    
    public func sleep() {
        guard config.enableBackgroundMediaTracking else {
            return
        }
        activeSessions.forEach { session in
            #if os(iOS)
            var backgroundTaskId: UIBackgroundTaskIdentifier?
            session.backgroundStatusResumed = false
            backgroundTaskId = MediaModule.sharedApplication?.beginBackgroundTask {
                if let taskId = backgroundTaskId {
                    MediaModule.sharedApplication?.endBackgroundTask(taskId)
                    backgroundTaskId = .invalid
                }
            }
                        
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline:
                                                .now() + config.backgroundMediaAutoEndSessionTime) {
                self.sendEndSessionInBackground(session)
            }

            if let taskId = backgroundTaskId {
                TealiumQueues.backgroundSerialQueue.asyncAfter(deadline:
                                                                .now() + (config.backgroundMediaAutoEndSessionTime + 1.0)) {
                    MediaModule.sharedApplication?.endBackgroundTask(taskId)
                    backgroundTaskId = .invalid
                }
            }
            #elseif os(watchOS)
            let pInfo = ProcessInfo()
            pInfo.performExpiringActivity(withReason: "Tealium Swift: End Media Session") { willBeSuspended in
                if !willBeSuspended {
                    TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + self.config.backgroundMediaAutoEndSessionTime) {
                        self.sendEndSessionInBackground(session)
                    }
                }
            }
            #else
            sendEndSessionInBackground(session)
            #endif
        }
    }
    
    public func wake() {
        guard config.enableBackgroundMediaTracking else {
            return
        }
        activeSessions.forEach { session in
            session.backgroundStatusResumed = true
        }
    }
    public func launch(at date: Date) { }
    
    func sendEndSessionInBackground(_ session: MediaSession) {
        if !session.backgroundStatusResumed {
            session.endSession()
        }
    }
}
#endif
