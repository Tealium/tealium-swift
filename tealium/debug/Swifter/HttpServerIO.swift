//
//  HttpServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation
import Dispatch

protocol HttpServerIODelegate {
    func socketConnectionReceived(socket: Socket)
}

public class HttpServerIO {
    
    public var socket = Socket(socketFileDescriptor: -1)
    private var sockets = Set<Socket>()

    var delegate : HttpServerIODelegate?
    
    public enum HttpServerIOState: Int32 {
        case starting
        case running
        case stopping
        case stopped
    }
    
    private var stateValue: Int32 = HttpServerIOState.stopped.rawValue
    
    public private(set) var state: HttpServerIOState {
        get {
            return HttpServerIOState(rawValue: stateValue)!
        }
        set(state) {
            #if !os(Linux)
            OSAtomicCompareAndSwapInt(self.state.rawValue, state.rawValue, &stateValue)
            #else
            //TODO - hehe :)
            self.stateValue = state.rawValue
            #endif
        }
    }
    
    public var operating: Bool { get { return self.state == .running } }
    
    private let queue = DispatchQueue(label: "swifter.httpserverio.clientsockets")
    
    public func port() throws -> Int {
        return Int(try socket.port())
    }
    
    public func isIPv4() throws -> Bool {
        return try socket.isIPv4()
    }
    
    public func getSocket() -> Socket {
        return self.socket
    }
    
    deinit {
        stop()
    }
    
    @available(macOS 10.10, *)
    public func start(_ port: in_port_t, forceIPv4: Bool = false, priority: DispatchQoS.QoSClass = DispatchQoS.QoSClass.background) throws {
        guard !self.operating else { return }
        stop()
        self.state = .starting
        self.socket = try Socket.tcpSocketForListen(port, forceIPv4)
        DispatchQueue.global(qos: priority).async { [weak self] in
            guard let `self` = self else { return }
            guard self.operating else { return }
            while let socket = try? self.socket.acceptClientSocket() {
                DispatchQueue.global(qos: priority).async { [weak self] in
                    guard let `self` = self else { return }
                    guard self.operating else { return }
                    self.queue.async {
                        self.sockets.insert(socket)
                    }
                    self.handleConnection(socket)
                    self.queue.async {
                        self.sockets.remove(socket)
                    }
                }
            }
            self.stop()
        }
        self.state = .running
    }
    
    public func stop() {
        guard self.operating else { return }
        self.state = .stopping
        // Shutdown connected peers because they can live in 'keep-alive' or 'websocket' loops.
        for socket in self.sockets {
            socket.close()
        }
        self.queue.sync {
            self.sockets.removeAll(keepingCapacity: true)
        }
        socket.close()
        self.state = .stopped
    }
    
    public func dispatch(_ request: HttpRequest) -> ([String: String], (HttpRequest) -> HttpResponse) {
        return ([:], { _ in HttpResponse.notFound })
    }
    
    private func handleConnection(_ socket: Socket) {
        let parser = HttpParser()
        while self.operating, let request = try? parser.readHttpRequest(socket) {
            let request = request
            request.address = try? socket.peername()
            let (params, handler) = self.dispatch(request)
            request.params = params
            let response = handler(request)
            var keepConnection = parser.supportsKeepAlive(request.headers)
            do {
                if self.operating {
                    keepConnection = try self.respond(socket, response: response, keepAlive: keepConnection)
                }
            } catch {
                print("Failed to send response: \(error)")
                break
            }
            if let session = response.socketSession() {
                delegate?.socketConnectionReceived(socket: socket)
                session(socket)
                break
            }
            if !keepConnection { break }
        }
        socket.close()
        
    }
    
    private struct InnerWriteContext: HttpResponseBodyWriter {
        
        let socket: Socket

        func write(_ file: String.File) throws {
            try socket.writeFile(file)
        }

        func write(_ data: [UInt8]) throws {
            try write(ArraySlice(data))
        }

        func write(_ data: ArraySlice<UInt8>) throws {
            try socket.writeUInt8(data)
        }

        func write(_ data: NSData) throws {
            try socket.writeData(data)
        }
        
        func write(_ data: Data) throws {
            try socket.writeData(data)
        }
    }
    
    private func respond(_ socket: Socket, response: HttpResponse, keepAlive: Bool) throws -> Bool {
        
        guard self.operating else { return false }

        try socket.writeUTF8("HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        
        let content = response.content()
        
        if content.length >= 0 {
            try socket.writeUTF8("Content-Length: \(content.length)\r\n")
        }
        
        if keepAlive && content.length != -1 {
            try socket.writeUTF8("Connection: keep-alive\r\n")
        }
        
        for (name, value) in response.headers() {
            try socket.writeUTF8("\(name): \(value)\r\n")
        }
        
        try socket.writeUTF8("\r\n")
    
        if let writeClosure = content.write {
            let context = InnerWriteContext(socket: socket)
            try writeClosure(context)
        }
        
        return keepAlive && content.length != -1;
    }
}
