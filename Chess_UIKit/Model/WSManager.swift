//
//  WSManager.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 23.01.2023.
//

import Foundation
import Starscream
import Network

//class that represents logic of the client side of WebSocket
class WSManager: WebSocketDelegate {
    
    // MARK: - WebSocketDelegate
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            connectedToWSServer = true
            delegate?.socketConnected(with: headers)
            activatePingTimer()
        case .disconnected(let reason, let code):
            connectedToWSServer = false
            delegate?.socketDisconnected(with: reason, and: code)
        case .text(let string):
            delegate?.socketReceivedText(string)
        case .binary(let data):
            delegate?.socketReceivedData(data)
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            connectedToWSServer = false
            break
        case .error(let error):
            connectedToWSServer = false
            handleWebSocketError(error)
        }
    }
    
    // MARK: - Properties
    
    static private var sharedInstance: WSManager?
    
    private(set) var connectedToTheInternet = true
    private(set) var connectedToWSServer = false {
        didSet {
            if !connectedToWSServer {
                deactivatePingTimer()
            }
        }
    }
    
    weak var delegate: WSManagerDelegate?
    
    //to check internet connection
    private let monitor = NWPathMonitor()

    private var socket: Starscream.WebSocket!
    //checks connection to the server
    private var pingTimer: Timer?
    
    private typealias constants = WSManager_Constants
    
    // MARK: - Inits
    
    //singleton
    private init() {}
    
    // MARK: - Methods
    
    //we don`t need WSManager in guestMode, otherwise it will just sit in a memory for no reason
    static func getSharedInstance() -> WSManager? {
        if !Storage.sharedInstance.currentUser.guestMode && sharedInstance == nil {
            sharedInstance = WSManager()
        }
        return sharedInstance
    }
    
    func connectToWebSocketServer() {
        var request = URLRequest(url: URL(string: constants.websocketAddress)!)
        request.timeoutInterval = constants.requestTimeout
        socket = WebSocket(request: request)
        socket.connect()
        socket.delegate = self
        if monitor.pathUpdateHandler == nil {
            configureNWPathMonitor()
        }
    }
    
    func disconnectFromWebSocketServer() {
        socket.disconnect()
        connectedToWSServer = false
        WSManager.sharedInstance = nil
    }
    
    func writeText(_ text: String) {
        socket.write(string: text)
    }
    
    func writeObject(_ object: Encodable) {
        if let data = try? JSONEncoder().encode(object) {
            socket.write(data: data)
        }
    }
    
    func activatePingTimer() {
        if !(pingTimer?.isValid ?? false) {
            pingTimer = Timer.scheduledTimer(withTimeInterval: constants.requestTimeout, repeats: true, block: { [weak self] _ in
                if let jsonData = try? JSONEncoder().encode("Hello") {
                    self?.socket.write(ping: jsonData)
                }
            })
        }
    }
    
    func deactivatePingTimer() {
        pingTimer?.invalidate()
    }
    
    private func handleWebSocketError(_ error: Error?) {
        if let error = error as? WSError {
            delegate?.webSocketError(with: "websocket encountered an error: \(error.message)")
        }
        else if let error = error {
            delegate?.webSocketError(with: "websocket encountered an error: \(error.localizedDescription)")
        }
        else {
            delegate?.webSocketError(with: "websocket encountered an error")
        }
    }
    
    //TODO: - Need to be tested on real devices with real server
    //not working properly on simulators
    private func configureNWPathMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            if let self = self {
                DispatchQueue.main.sync {
                    if path.status == .satisfied {
                        self.connectedToTheInternet = true
                    }
                    else {
                        self.connectedToWSServer = false
                        self.connectedToTheInternet = false
                        self.delegate?.lostInternet()
                    }
                }
            }
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    //
    
}

// MARK: - Constants

private struct WSManager_Constants {
    static let websocketAddress = "http://localhost:1337"
    static let requestTimeout = 5.0
}
