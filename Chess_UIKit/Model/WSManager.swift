//
//  WSManager.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 23.01.2023.
//

import Foundation
import Starscream
import Network

// MARK: - WSManagerDelegate

protocol WSManagerDelegate: AnyObject {
    func managerDidConnectSocket(_ manager: WSManager, with headers: [String: String])
    func managerDidDisconnectSocket(_ manager: WSManager, with reason: String, and code: UInt16)
    func managerDidReceive(_ manager: WSManager, data: Data)
    func managerDidReceive(_ manager: WSManager, text: String)
    func managerDidEncounterError(_ manager: WSManager, with message: String)
    func managerDidLostInternetConnection(_ manager: WSManager)
}

extension WSManagerDelegate {
    
    func managerDidConnectSocket(_ manager: WSManager, with headers: [String: String]) {
        print("websocket is connected: \(headers)")
    }
    
    func managerDidDisconnectSocket(_ manager: WSManager, with reason: String, and code: UInt16) {
        print("websocket is disconnected: \(reason) with code: \(code)")
    }
    
    func managerDidReceive(_ manager: WSManager, data: Data) {
        print("Received data: \(data.count)")
    }
    
    func managerDidReceive(_ manager: WSManager, text: String) {
        print("Received text: \(text)")
    }
    
    func managerDidEncounterError(_ manager: WSManager, with message: String) {
        print(message)
    }
    
    func managerDidLostInternetConnection(_ manager: WSManager) {
        print("Lost internet connection")
    }
    
}

// MARK: - WSManager

//class that represents logic of the client side of WebSocket
class WSManager: WebSocketDelegate {
    
    // MARK: - WebSocketDelegate
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            connectedToWSServer = true
            delegate?.managerDidConnectSocket(self, with: headers)
            activatePingTimer()
        case .disconnected(let reason, let code):
            connectedToWSServer = false
            delegate?.managerDidDisconnectSocket(self, with: reason, and: code)
        case .text(let string):
            delegate?.managerDidReceive(self, text: string)
        case .binary(let data):
            delegate?.managerDidReceive(self, data: data)
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
    private var reconnectTimer: Timer?
    private var monitorTask: Task<Void,Error>?
    
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
    
    func startReconnecting() {
        if !connectedToWSServer && reconnectTimer == nil {
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: constants.requestTimeout, repeats: true, block: { [weak self] timer in
                guard let self else { return }
                if !self.connectedToWSServer {
                    self.connectToWebSocketServer()
                }
                else {
                    timer.invalidate()
                }
            })
        }
        if let reconnectTimer {
            RunLoop.main.add(reconnectTimer, forMode: .common)
        }
    }
    
    func stopReconnecting() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
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
        monitorTask?.cancel()
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
        if pingTimer == nil {
            pingTimer = Timer.scheduledTimer(withTimeInterval: constants.requestTimeout, repeats: true, block: { [weak self] _ in
                guard let self else { return }
                Task {
                    if let jsonData = try? JSONEncoder().encode("Hello") {
                        self.socket.write(ping: jsonData)
                    }
                }
            })
        }
        if let pingTimer {
            RunLoop.main.add(pingTimer, forMode: .common)
        }
    }
    
    func deactivatePingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func handleWebSocketError(_ error: Error?) {
        if let error = error as? WSError {
            delegate?.managerDidEncounterError(self, with: "websocket encountered an error: \(error.message)")
        }
        else if let error {
            delegate?.managerDidEncounterError(self, with: "websocket encountered an error: \(error.localizedDescription)")
        }
        else {
            delegate?.managerDidEncounterError(self, with: "websocket encountered an error")
        }
    }
    
    //TODO: - Need to be tested on real devices with real server
    //not working properly on simulators
    private func configureNWPathMonitor() {
        monitorTask = Task {
            for await path in monitor.paths() {
                if path.status == .satisfied {
                    connectedToTheInternet = true
                }
                else {
                    connectedToWSServer = false
                    connectedToTheInternet = false
                    delegate?.managerDidLostInternetConnection(self)
                }
            }
        }
    }
    //
    
}

// MARK: - Constants

private struct WSManager_Constants {
    static let websocketAddress = "http://localhost:1337"
    static let requestTimeout = 5.0
}
