//
//  DispatchManager.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

// swiftlint:disable file_length
import Foundation
#if os(iOS)
import UIKit
#else
#endif

protocol DispatchManagerProtocol {
    var dispatchers: [Dispatcher]? { get set }
    var dispatchListeners: [DispatchListener]? { get set }
    var dispatchValidators: [DispatchValidator]? { get set }
    var config: TealiumConfig { get set }

    init(dispatchers: [Dispatcher]?,
         dispatchValidators: [DispatchValidator]?,
         dispatchListeners: [DispatchListener]?,
         connectivityManager: ConnectivityModule,
         config: TealiumConfig)

    func processTrack(_ request: TealiumTrackRequest)
    func handleDequeueRequest(reason: String)

}

class DispatchManager: DispatchManagerProtocol {

    var dispatchers: [Dispatcher]?
    var dispatchValidators: [DispatchValidator]?
    var dispatchListeners: [DispatchListener]?
    var logger: TealiumLoggerProtocol?
    var persistentQueue: TealiumPersistentDispatchQueue!
    var diskStorage: TealiumDiskStorageProtocol!
    var config: TealiumConfig
    var connectivityManager: ConnectivityModule

    var shouldDequeue: Bool {
        if let dispatchers = dispatchers, !dispatchers.isEmpty {
            return persistentQueue.currentEvents >= eventsBeforeAutoDispatch &&
                hasSufficientBattery(track: persistentQueue.peek()?.last)
        }
        return false
    }

    // when to start trimming the queue (default 20) - e.g. if offline
    var maxQueueSize: Int {
        if let maxQueueSize = config.dispatchQueueLimit, maxQueueSize >= 0 {
            return maxQueueSize
        }
        return TealiumValue.defaultMaxQueueSize
    }

    // max number of events in a single batch
    var maxDispatchSize: Int {
        config.batchSize
    }

    var eventsBeforeAutoDispatch: Int {
        config.dispatchAfter
    }

    var isBatchingEnabled: Bool {
        config.batchingEnabled ?? false
    }

    var batchingBypassKeys: [String]? {
        get {
            config.batchingBypassKeys
        }

        set {
            config.batchingBypassKeys = newValue
        }
    }

    var batchExpirationDays: Int {
        config.dispatchExpiration ?? TealiumValue.defaultBatchExpirationDays
    }

    var isRemoteAPIEnabled: Bool {
        #if os(iOS)
        return config.remoteAPIEnabled ?? false
        #else
        return false
        #endif
    }

    var lowPowerModeEnabled = false
    var lowPowerNotificationObserver: NSObjectProtocol?

    convenience init (dispatchers: [Dispatcher]?,
                      dispatchValidators: [DispatchValidator]?,
                      dispatchListeners: [DispatchListener]?,
                      connectivityManager: ConnectivityModule,
                      config: TealiumConfig,
                      diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.init(dispatchers: dispatchers, dispatchValidators: dispatchValidators, dispatchListeners: dispatchListeners, connectivityManager: connectivityManager, config: config)
        self.diskStorage = diskStorage
    }

    required init(dispatchers: [Dispatcher]?,
                  dispatchValidators: [DispatchValidator]?,
                  dispatchListeners: [DispatchListener]?,
                  connectivityManager: ConnectivityModule,
                  config: TealiumConfig) {
        self.config = config
        self.connectivityManager = connectivityManager
        self.dispatchers = dispatchers
        self.dispatchValidators = dispatchValidators

        self.dispatchListeners = dispatchListeners

        if let logger = config.logger {
            self.logger = logger
        }

        // allows overriding for unit tests
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: TealiumDispatchQueueConstants.moduleName)
        }
        persistentQueue = TealiumPersistentDispatchQueue(diskStorage: self.diskStorage)
        removeOldDispatches()
        if config.lifecycleAutoTrackingEnabled {
            Tealium.lifecycleListeners.addDelegate(delegate: self)
        }
        registerForPowerNotifications()
    }

    func processTrack(_ request: TealiumTrackRequest) {
        // first release the queue if the dispatch limit has been reached
        if shouldDequeue {
            handleDequeueRequest(reason: "Processing track request")
        }
        var newRequest = request

        if checkShouldQueue(request: &newRequest) {
            enqueue(newRequest, reason: nil)
            return
        }

        if checkShouldDrop(request: newRequest) {
            return
        }

        if checkShouldPurge(request: newRequest) {
            self.clearQueue()
            return
        }

        #if os(iOS)
        triggerRemoteAPIRequest(request)
        #endif

        self.connectivityManager.checkIsConnected { result in
            switch result {
            case .success:
                let shouldQueue = self.shouldQueue(request: newRequest)
                if shouldQueue.0 == true {
                    let batchingReason = shouldQueue.1? [TealiumKey.queueReason] as? String ?? TealiumKey.batchingEnabled

                    self.enqueue(newRequest, reason: batchingReason)
                    // batch request and release if necessary
                    return
                }

                guard let dispatchers = self.dispatchers, !dispatchers.isEmpty else {
                    self.enqueue(newRequest, reason: "Dispatchers Not Ready")
                    return
                }

                self.runDispatchers(for: newRequest)
            case .failure:
                self.enqueue(newRequest, reason: "connectivity")
            }
        }

    }

    func checkShouldQueue(request: inout TealiumTrackRequest) -> Bool {
        guard let dispatchValidators = dispatchValidators else {
            return false
        }
        return dispatchValidators.filter {
            let response = $0.shouldQueue(request: request)
            if let data = response.1 {
                var newData = request.trackDictionary
                newData += data
                request.data = newData.encodable
                if response.0 == true {
                    let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Track request enqueued by Dispatch Validator: \($0.id)", info: data, logLevel: .info, category: .track)
                    self.logger?.log(logRequest)
                }
            }
            return response.0
        }.count > 0
    }

    func runDispatchers (for request: TealiumRequest) {
        if request is TealiumTrackRequest || request is TealiumBatchTrackRequest {
            self.dispatchListeners?.forEach {
                $0.willTrack(request: request)
            }
        }
        self.logTrackSuccess([], request: request)
        dispatchers?.forEach { module in
            let moduleId = module.id
            module.dynamicTrack(request) { result, data in
                switch result {
                case .failure(let error):
                    self.logModuleResponse(for: moduleId, request: request, info: data, success: false, error: error)
                case .success:
                    self.logModuleResponse(for: moduleId, request: request, info: data, success: true, error: nil)
                }

            }
        }
    }

    func removeOldDispatches() {
        let currentDate = Date()
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(-batchExpirationDays, for: .day)
        let sinceDate = Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
        persistentQueue.removeOldDispatches(maxQueueSize, since: sinceDate)
    }

    func enqueue(_ request: TealiumTrackRequest,
                 reason: String?) {
        defer {
            if shouldDequeue {
                handleDequeueRequest(reason: "Dispatch queue limit reached.")
            }
        }
        removeOldDispatches()
        // no conditions preventing queueing, so queue request
        var requestData = request.trackDictionary
        if requestData[TealiumKey.queueReason] == nil {
            requestData[TealiumKey.queueReason] = reason ?? TealiumKey.batchingEnabled
        }
        requestData[TealiumKey.wasQueued] = "true"
        var newRequest = TealiumTrackRequest(data: requestData)
        newRequest.uuid = request.uuid
        persistentQueue.appendDispatch(newRequest)

        logQueue(request: newRequest, reason: reason)
    }

    func clearQueue() {
        persistentQueue.clearQueue()
    }

    func handleDequeueRequest(reason: String) {
        self.connectivityManager.checkIsConnected { result in
            switch result {
            case .success:
                // dummy request to check if queueing active
                var request = TealiumTrackRequest(data: ["release_request": true])

                guard let dispatchers = self.dispatchers, !dispatchers.isEmpty else {
                    return
                }

                guard !self.checkShouldQueue(request: &request),
                      !self.checkShouldDrop(request: request),
                      !self.checkShouldPurge(request: request) else {
                    return
                }

                if let count = self.persistentQueue.peek()?.count, count > 0 {
                    let logRequest = TealiumLogRequest(title: "Dispatch Manager",
                                                       message: "Releasing queued dispatches. Reason: \(reason)",
                                                       info: nil,
                                                       logLevel: .info,
                                                       category: .track)
                    self.logger?.log(logRequest)

                    self.dequeue()
                }
            case .failure:
                return
            }
        }
    }

    func dequeue() {
        if var queuedDispatches = persistentQueue.dequeueDispatches() {
            queuedDispatches = queuedDispatches.map {
                var request = $0
                _ = checkShouldQueue(request: &request)
                return request
            }

            let batches: [[TealiumTrackRequest]] = queuedDispatches.chunks(maxDispatchSize)

            batches.forEach { batch in

                switch batch.count {
                case let val where val <= 1:
                    if var data = batch.first?.trackDictionary {
                        // for all release calls, bypass the queue and send immediately
                        data += [TealiumDispatchQueueConstants.bypassQueueKey: true]
                        let request = TealiumTrackRequest(data: data)
                        runDispatchers(for: request)
                    }

                case let val where val > 1:
                    let batchRequest = TealiumBatchTrackRequest(trackRequests: batch)
                    runDispatchers(for: batchRequest)
                default:
                    // should never reach here
                    return
                }

            }
        }
    }

    func triggerRemoteAPIRequest(_ request: TealiumTrackRequest) {
        guard isRemoteAPIEnabled else {
            return
        }
        let request = TealiumRemoteAPIRequest(trackRequest: request)
        runDispatchers(for: request)
    }

}

extension DispatchManager {

    func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {

        guard let request = request as? TealiumTrackRequest else {
            return (false, nil)
        }

        let canWrite = diskStorage.canWrite()

        guard canWrite else {
            return (false, nil)
        }
        #if os (watchOS)
        return (true, [TealiumKey.queueReason: TealiumKey.batchingEnabled])
        #else

        guard hasSufficientBattery(track: request) else {
            enqueue(request, reason: TealiumDispatchQueueConstants.insufficientBatteryQueueReason)
            return (true, [TealiumKey.queueReason: TealiumDispatchQueueConstants.insufficientBatteryQueueReason])
        }

        if request.trackDictionary[TealiumDispatchQueueConstants.bypassQueueKey] as? Bool == true {
            return (!(request.trackDictionary[TealiumDispatchQueueConstants.bypassQueueKey] as? Bool ?? false), nil)
        }

        guard isBatchingEnabled else {
            return (false, nil)
        }

        guard eventsBeforeAutoDispatch > 1 else {
            return (false, nil)
        }

        guard maxDispatchSize > 1 else {
            return (false, nil)
        }

        guard maxQueueSize > 1 else {
            return (false, nil)
        }

        guard canQueueRequest(request) else {
            return (false, nil)
        }

        return (true, [TealiumKey.queueReason: TealiumKey.batchingEnabled])
        #endif
    }

    func hasSufficientBattery(track: TealiumTrackRequest?) -> Bool {
        guard let track = track else {
            return true
        }
        guard config.batterySaverEnabled == true else {
            return true
        }

        if lowPowerModeEnabled == true {
            return false
        }

        guard let batteryPercentString = track.trackDictionary[DeviceDataKey.batteryPercent] as? String, let batteryPercent = Double(batteryPercentString) else {
            return true
        }

        guard batteryPercent != TealiumDispatchQueueConstants.simulatorBatteryConstant else {
            return true
        }

        guard batteryPercent >= TealiumDispatchQueueConstants.lowBatteryThreshold else {
            return false
        }
        return true
    }

    func canQueueRequest(_ request: TealiumTrackRequest) -> Bool {
        guard let event = request.event else {
            return false
        }
        var shouldQueue = true
        var bypassKeys = BypassDispatchQueueKeys.allCases.map { $0.rawValue }
        if let batchingBypassKeys = batchingBypassKeys {
            bypassKeys += batchingBypassKeys
        }
        for key in bypassKeys where key == event {
            shouldQueue = false
            break
        }

        return shouldQueue
    }

}

// Dispatch Validator Checks
extension DispatchManager {

    func checkShouldQueue(request: inout TealiumBatchTrackRequest) -> Bool {
        guard let dispatchValidators = dispatchValidators else {
            return false
        }
        let uuid = request.uuid
        return dispatchValidators.filter {
            let response = $0.shouldQueue(request: request)
            if response.0 == true,
               let data = response.1 {
                request = TealiumBatchTrackRequest(trackRequests: request.trackRequests.map { request in
                    let singleRequestUUID = request.uuid
                    var newData = request.trackDictionary
                    newData += data
                    var newRequest = TealiumTrackRequest(data: newData)
                    newRequest.uuid = singleRequestUUID
                    return newRequest
                })
                request.uuid = uuid
                let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Track request enqueued by Dispatch Validator: \($0.id)", info: data, logLevel: .info, category: .track)
                self.logger?.log(logRequest)
            }
            return response.0
        }.count > 0
    }

    func checkShouldDrop(request: TealiumRequest) -> Bool {
        guard let dispatchValidators = dispatchValidators else {
            return false
        }
        return dispatchValidators.filter {
            if $0.shouldDrop(request: request) == true {
                let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Track request dropped by Dispatch Validator: \($0.id)", info: nil, logLevel: .info, category: .track)
                self.logger?.log(logRequest)
                return true
            }
            return false
        }.count > 0
    }

    func checkShouldPurge(request: TealiumRequest) -> Bool {
        guard let dispatchValidators = dispatchValidators else {
            return false
        }
        return dispatchValidators.filter {
            if $0.shouldPurge(request: request) == true {
                let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Purge request received from Dispatch Validator: \($0.id)", info: nil, logLevel: .info, category: .track)
                self.logger?.log(logRequest)
                return true
            }
            return false
        }.count > 0
    }
}

// Logging
extension DispatchManager {

    func logModuleResponse (for module: String,
                            request: TealiumRequest,
                            info: [String: Any]?,
                            success: Bool,
                            error: Error?) {
        let message = success ? "Successful Track": "Failed with error: \(error?.localizedDescription ?? "")"
        let logLevel: TealiumLogLevel = success ? .info : .error
        var uuid: String?
        var event: String?
        switch request {
        case let request as TealiumBatchTrackRequest:
            uuid = request.uuid
            event = "batch"
        case let request as TealiumTrackRequest:
            uuid = request.uuid
            event = request.event
        default:
            uuid = nil
        }
        var messages = [String]()
        if let uuid = uuid, let event = event {
            messages.append("Event: \(event), Track UUID: \(uuid)")
        }
        messages.append(message)
        let logRequest = TealiumLogRequest(title: module, messages: messages, info: nil, logLevel: logLevel, category: .track)
        logger?.log(logRequest)
    }

    func logTrackSuccess(_ success: [String],
                         request: TealiumRequest) {
        var logInfo: [String: Any]? = [String: Any]()
        switch request {
        case let request as TealiumTrackRequest:
            logInfo = request.trackDictionary
        case let request as TealiumBatchTrackRequest:
            logInfo = request.compressed()
        default:
            return
        }

        let logRequest = TealiumLogRequest(title: "Dispatch Manager", message: "Sending dispatch", info: logInfo, logLevel: .info, category: .track)
        logger?.log(logRequest)
    }

    func logTrackFailure(_ failures: [(module: String, error: Error)],
                         request: TealiumRequest) {
        var logInfo: [String: Any]? = [String: Any]()
        switch request {
        case let request as TealiumTrackRequest:
            logInfo = request.trackDictionary
        case let request as TealiumBatchTrackRequest:
            logInfo = request.compressed()
        default:
            return
        }
        let logRequest = TealiumLogRequest(title: "Failed Track",
                                           messages: failures.map { "\($0.module) Error -> \($0.error.localizedDescription)" },
                                           info: logInfo,
                                           logLevel: .error,
                                           category: .track)
        logger?.log(logRequest)
    }

    func logQueue(request: TealiumTrackRequest,
                  reason: String?) {

        let message = """
        Event: \(request.trackDictionary[TealiumKey.event] as? String ?? "") queued for batch dispatch. Track UUID: \(request.uuid)
        """
        var messages = [message]
        if let reason = reason {
            messages.append("Queue Reason: \(reason)")
        }
        let logRequest = TealiumLogRequest(title: "Dispatch Manager", messages: messages, info: nil, logLevel: .info, category: .track)

        logger?.log(logRequest)
    }
}

// swiftlint:enable file_length
