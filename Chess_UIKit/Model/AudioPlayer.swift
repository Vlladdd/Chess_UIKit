//
//  AudioPlayer.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 03.01.2023.
//

import UIKit
import AVFoundation

//class that represents logic of the audio player
class AudioPlayer {
    
    // MARK: - Properties
    
    var musicEnabled = true
    var soundsEnabled = true
    
    private var audioPlayers = [AVAudioPlayer]()
    
    static let sharedInstance = AudioPlayer()
    
    private typealias constants = AudioPlayer_Constants
    
    // MARK: - Inits
    
    //singleton
    private init() {}
    
    // MARK: - Methods
    
    func playSound(_ sound: Sound, volume: Float = constants.defaultVolume) {
        guard let audioData = NSDataAsset(name: "\(sound.folderName)/\(sound.name)")?.data else { return }
        if (sound as? Sounds != nil && soundsEnabled) || (sound as? Music != nil && musicEnabled) {
            if let audioPlayer = audioPlayers.first(where: {$0.data == audioData}) {
                if sound as? Sounds != nil && audioPlayer.isPlaying {
                    audioPlayer.pause()
                    audioPlayer.currentTime = 0
                }
                audioPlayer.play()
            }
            else {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    let audioPlayer = try AVAudioPlayer(data: audioData)
                    audioPlayer.volume = volume
                    audioPlayer.numberOfLoops = sound as? Music != nil ? constants.numberOfLoopsForMusic : 0
                    audioPlayers.append(audioPlayer)
                    audioPlayer.play()
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func stopSound(_ sound: Sound) {
        guard let audioData = NSDataAsset(name: "\(sound.folderName)/\(sound.name)")?.data else { return }
        if let audioPlayer = audioPlayers.first(where: {$0.data == audioData}) {
            audioPlayer.stop()
        }
    }
    
}

// MARK: - Constants

private struct AudioPlayer_Constants {
    static let numberOfLoopsForMusic = -1
    static let defaultVolume: Float = 1.0
}
