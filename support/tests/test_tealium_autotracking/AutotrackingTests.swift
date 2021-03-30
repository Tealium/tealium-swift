//
//  AutotrackingTests.swift
//  TealiumAutotrackingTests-iOS
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

@testable import TealiumAutotracking
@testable import TealiumCore
import XCTest

class AutotrackingTests: XCTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }

    // MARK: Module
    func testInit_LoadsBlockList_WhenFileNameDefined() {
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        config.autoTrackingBlocklistFilename = "filename"
        
        let module = createModule(from: config, loader: MockJSONLoaderBlockListFile())

        XCTAssertEqual(["PaymentView", "EmojiView"], module.blockList)
    }
    
    func testInit_LoadsBlockList_WhenURLDefined() {
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        config.autoTrackingBlocklistURL = "url"
        
        let module = createModule(from: config, loader: MockJSONLoaderBlockListURL())

        XCTAssertEqual(["EcommView", "SillyView"], module.blockList)
    }
    
    func testInit_ErrorWhileLoadingBlockList() {
        let mockContext = MockTealiumContext()
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        config.autoTrackingBlocklistFilename = "filename"
        mockContext.config = config
        mockContext.jsonLoader = MockJSONLoaderError()
        
        _ = AutotrackingModule(context: mockContext,
                               delegate: nil,
                               diskStorage: nil) { _ in }

        XCTAssertEqual(mockContext.logRequest?.messages.first!, "BlockList could not be loaded. Error: couldNotDecode")
    }
    
    func testInit_DoesNotLoadBlockList_WhenNoConfigSettingDefined() {
        XCTAssertNil(createModule().blockList)
    }
    
    func testInit_SetsNotificationToken() {
        let module = createModule()

        XCTAssertNotNil(module.token)
    }
    
    func testRequestViewTrack_Returns_WhenLastEventEqualsViewName() {
        let mockContext = MockTealiumContext()
        let module = AutotrackingModule(context: mockContext,
                                        delegate: nil,
                                        diskStorage: nil) { _ in }
        module.lastEvent = "SomeView"
        
        module.requestViewTrack(viewName: "SomeView")
        
        XCTAssertEqual(mockContext.trackCalled, 0)
        XCTAssertEqual(mockContext.logRequest?.messages.first!, "Suppressing duplicate screen view: SomeView")
    }
    
    func testRequestViewTrack_Returns_WhenViewNameInBlockList() {
        let mockContext = MockTealiumContext()
        let module = AutotrackingModule(context: mockContext,
                                        delegate: nil,
                                        diskStorage: nil) { _ in }
        module.blockList = ["PaymentView", "EmojiView"]
        
        module.requestViewTrack(viewName: "PaymentView")
        
        XCTAssertEqual(mockContext.trackCalled, 0)
    }
    
    func testRequestViewTrack_CallsTrack_WhenViewNameNotInBlockList() {
        let mockContext = MockTealiumContext()
        let module = AutotrackingModule(context: mockContext,
                                        delegate: nil,
                                        diskStorage: nil) { _ in }
        module.blockList = ["EmojiView"]
        
        module.requestViewTrack(viewName: "PaymentView")
        
        XCTAssertEqual(mockContext.trackCalled, 1)
        XCTAssertEqual(module.lastEvent, "PaymentView")
    }
    
    func testRequestViewTrack_CallsDelegateMethodAndAddsDataToPayload() {
        let expect = expectation(description: "testRequestViewTrack_CallsDelegateMethodAndAddsDataToPayload")
        
        let mockContext = MockTealiumContext()
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        let mockDelegate = MockAutoTrackingDelegate()
        mockDelegate.asyncExpectation = expect
        config.autoTrackingCollectorDelegate = mockDelegate
        mockContext.config = config
        let module = AutotrackingModule(context: mockContext,
                                        delegate: nil,
                                        diskStorage: nil) { _ in }
        
        module.requestViewTrack(viewName: "PaymentView")
        
        XCTAssertEqual(mockDelegate.screenName, "PaymentView")
        XCTAssertTrue(mockContext.trackDictionary["delegate_method_succeeded"] as! Bool)
        
        wait(for: [expect], timeout: 1.0)
    }
    
    func testWillTrack_RecordsLastEvent() {
        let mockContext = MockTealiumContext()
        let module = AutotrackingModule(context: mockContext,
                                        delegate: nil,
                                        diskStorage: nil) { _ in }
        let request = TealiumTrackRequest(data: ["tealium_event": "helloWorld"])
        
        module.willTrack(request: request)
        
        XCTAssertEqual(module.lastEvent, "helloWorld")
    }
    
    // MARK: Utils
    func testViewTitle_Set_WhenDefinedOnViewController() {
        let mockTealiumVC = MockTealiumViewController()
        mockTealiumVC.title = "TestViewTitle"
        XCTAssertEqual(mockTealiumVC.viewTitle, "TestViewTitle")
    }
    
    func testViewTitle_Default_WhenNotDefinedOnViewController() {
        let mockTealiumVC = MockTealiumViewController()
        XCTAssertEqual(mockTealiumVC.viewTitle, "MockTealium")
    }
    
    func testViewNotification_NotificationPosted_OnViewDidAppear() {
        let mockTealiumVC = MockTealiumViewController()
        let mockNotificationCenter = MockNotificationCenter()
        mockTealiumVC.notificationCenter = mockNotificationCenter
        mockTealiumVC.viewDidAppear(true)
        XCTAssertEqual(mockNotificationCenter.didPostNotification?.name.rawValue,
                       "com.tealium.autotracking.view")
        XCTAssertEqual(mockNotificationCenter.didPostNotification?.userInfo?[
        "view_name"] as! String, "MockTealium")
    }

    // MARK: Helper Methods
    func createModule(from config: TealiumConfig? = nil,
                loader: JSONLoadable? = nil) -> AutotrackingModule {
        let localConfig = config ?? testTealiumConfig.copy
        let tealium = Tealium(config: localConfig)
        let context = TealiumContext(config: localConfig,
                                     dataLayer: DummyDataManager(),
                                     jsonLoader: loader ?? MockJSONLoader(),
                                     tealium: tealium)
        return AutotrackingModule(context: context,
                                  delegate: self,
                                  diskStorage: nil) { _ in }
    }
    
}

extension AutotrackingTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) { }
    func requestTrack(_ track: TealiumTrackRequest) { }
    func requestDequeue(reason: String) { }
}

class MockJSONLoaderBlockListFile: JSONLoadable {
    func fromFile<T: Codable>(_ file: String,
                              bundle: Bundle,
                              logger: TealiumLoggerProtocol?) throws -> T? {
        ["PaymentView", "EmojiView"] as? T
    }
    func fromURL<T: Codable>(url: String,
                             logger: TealiumLoggerProtocol?) throws -> T? { nil }
    func fromString<T: Codable>(json: String,
                                logger: TealiumLoggerProtocol?) throws -> T? { nil }
}

class MockJSONLoaderBlockListURL: JSONLoadable {
    func fromFile<T: Codable>(_ file: String,
                              bundle: Bundle,
                              logger: TealiumLoggerProtocol?) throws -> T? { nil }
    func fromURL<T: Codable>(url: String,
                             logger: TealiumLoggerProtocol?) throws -> T? {
        ["EcommView", "SillyView"] as? T
    }
    func fromString<T: Codable>(json: String,
                                logger: TealiumLoggerProtocol?) throws -> T? { nil }
}

class MockJSONLoaderError: JSONLoadable {
    func fromFile<T: Codable>(_ file: String,
                              bundle: Bundle,
                              logger: TealiumLoggerProtocol?) throws -> T? {
        throw JSONLoader.JSONLoaderError.couldNotDecode
    }
    func fromURL<T: Codable>(url: String,
                             logger: TealiumLoggerProtocol?) throws -> T? { nil }
    func fromString<T: Codable>(json: String,
                                logger: TealiumLoggerProtocol?) throws -> T? { nil }
}

class MockTealiumContext: TealiumContextProtocol {

    var trackCalled = 0
    var trackDictionary = [String: Any]()
    var logRequest: TealiumLogRequest?
    
    var config: TealiumConfig = TealiumConfig(account: "account",
                                              profile: "profile",
                                              environment: "env")
    var dataLayer: DataLayerManagerProtocol? = DummyDataManager()
    var jsonLoader: JSONLoadable? = MockJSONLoader()

    func track(_ dispatch: TealiumDispatch) {
        trackCalled += 1
        trackDictionary = dispatch.trackRequest.trackDictionary
    }
    
    func handleDeepLink(_ url: URL) { }
    
    func log(_ logRequest: TealiumLogRequest) {
        self.logRequest = logRequest
    }
    
}

class MockAutoTrackingDelegate: AutoTrackingDelegate {

    var screenName: String?
    var asyncExpectation: XCTestExpectation?

    func onCollectScreenView(screenName: String) -> [String: Any] {
        guard let expectation = asyncExpectation else {
            XCTFail("MockAutoTrackingDelegate was not setup correctly. Missing XCTExpectation reference")
            return [String: Any]()
        }
        self.screenName = screenName
        expectation.fulfill()
        return ["delegate_method_succeeded": true]
    }

}

class MockNotificationCenter: NotificationCenterObservable {
    
    var didPostNotification: Notification?
    var didAddObserverWithName : Notification.Name?
    var didCallRemoveObserver = false

    func post(_ notification: Notification) {
        didPostNotification = notification
    }
    
    func addObserver(forName name: NSNotification.Name?,
                     object obj: Any?,
                     queue: OperationQueue?,
                     using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        didAddObserverWithName = name
        return Mock()
    }
    
    func removeObserver(_ observer: Any) {
        didCallRemoveObserver = true
    }
    
    class Mock: NSObject { }
}

class MockTealiumViewController: TealiumViewController {}

