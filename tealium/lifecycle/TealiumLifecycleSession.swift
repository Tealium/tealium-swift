//
//  TealiumLifecycleSession.swift
//
//  Created by Jason Koo on 2/15/17.
//  Copyright © 2017 tealium. All rights reserved.
//

import Foundation

enum TealiumLifecycleSessionKey {
    static let wakeDate = "wake"
    static let sleepDate = "sleep"
    static let secondsElapsed = "seconds"
    static let wasLaunch = "wasLaunch"
}

// Represents a serializable block of time between a given wake and a sleep
public class TealiumLifecycleSession : NSObject, NSCoding {
    
    var appVersion : String = TealiumLifecycleSession.getCurrentAppVersion()
    var wakeDate : Date?
    var sleepDate : Date? {
        didSet {
            guard let wake = wakeDate else {
                return
            }
            guard let sleep = sleepDate else {
                return
            }
            let milliseconds = sleep.timeIntervalSince(wake)
            secondsElapsed = Int(milliseconds)
        }
    }
    var secondsElapsed : Int = 0
    var wasLaunch = false
    
    init(withLaunchDate : Date) {
        self.wakeDate = withLaunchDate
        self.wasLaunch = true
        super.init()
    }
    
    init(withWakeDate: Date) {
        self.wakeDate = withWakeDate
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        
        self.wakeDate = aDecoder.decodeObject(forKey: TealiumLifecycleSessionKey.wakeDate) as? Date
        self.sleepDate = aDecoder.decodeObject(forKey: TealiumLifecycleSessionKey.sleepDate) as? Date
        self.secondsElapsed = aDecoder.decodeInteger(forKey: TealiumLifecycleSessionKey.secondsElapsed) as Int
        self.wasLaunch = aDecoder.decodeBool(forKey: TealiumLifecycleSessionKey.wasLaunch) as Bool
    }
    
    public func encode(with aCoder: NSCoder) {
        
        aCoder.encode(self.wakeDate, forKey: TealiumLifecycleSessionKey.wakeDate)
        aCoder.encode(self.sleepDate, forKey: TealiumLifecycleSessionKey.sleepDate)
        aCoder.encode(self.secondsElapsed, forKey: TealiumLifecycleSessionKey.secondsElapsed)
        aCoder.encode(self.wasLaunch, forKey: TealiumLifecycleSessionKey.wasLaunch)
    }
    
    
    internal class func getCurrentAppVersion() -> String {
        
        let bundleInfo = Bundle.main.infoDictionary
        
        if let shortString = bundleInfo?["CFBundleShortVersionString"] as? String {
            return shortString
        }
        
        if let altString = bundleInfo?["CFBundleVersion"] as? String {
            return altString
        }
        
        return "(unknown)"
        
    }
    
    public override var debugDescription: String {
        return "<TealiumLifecycleSession: appVersion:\(appVersion): wake:\(String(describing: wakeDate)) sleep:\(String(describing: sleepDate)) secondsElapsed: \(secondsElapsed) wasLaunch: \(wasLaunch)>"
    }
}



public func ==(lhs: TealiumLifecycleSession, rhs: TealiumLifecycleSession ) -> Bool {
    
    if lhs.wakeDate != rhs.wakeDate { return false }
    if lhs.sleepDate != rhs.sleepDate { return false }
    if lhs.secondsElapsed != rhs.secondsElapsed { return false }
    if lhs.wasLaunch != rhs.wasLaunch { return false }
    return true
}

