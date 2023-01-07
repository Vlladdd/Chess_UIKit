//
//  AudioFile.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 07.01.2023.
//

import Foundation
import AVFoundation

//class that represents audio file
class AudioFile {
    
    // MARK: - Properties
    
    let sound: Sound
    let data: Data
    
    var sizeMB: Double {
        data.MB
    }
    var duration: Double {
        player?.duration ?? 0.0
    }
    
    private var player: AVAudioPlayer?
    
    private(set) var currentStatus = AudioStatus.notPlaying
    //we can`t pause an audio file, if it is not loaded, that is why we need that
    private(set) var expectedStatus = AudioStatus.notPlaying
    
    // MARK: - Inits
    
    init(sound: Sound, data: Data) {
        self.sound = sound
        self.data = data
    }
    
    // MARK: - Methods
    
    func updatePlayer(newValue: AVAudioPlayer) {
        player = newValue
    }
    
    func updateCurrentStatus(newValue: AudioStatus) {
        currentStatus = newValue
        playerAction()
    }
    
    func updateExpectedStatus(newValue: AudioStatus) {
        expectedStatus = newValue
        if currentStatus != .loading {
            currentStatus = newValue
            playerAction()
        }
    }
    
    private func playerAction() {
        switch currentStatus {
        case .notPlaying:
            break
        case .playing:
            play()
        case .paused:
            pause()
        case .loading:
            break
        }
    }
    
    private func play() {
        if let player {
            if sound as? Sounds != nil && player.isPlaying {
                player.pause()
                player.currentTime = 0
            }
            player.play()
        }
    }
    
    private func pause() {
        player?.pause()
    }
    
}
