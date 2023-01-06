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
    //to avoid loading same sound more than once
    private var loadedSounds = [Sound]()
    
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
                if !loadedSounds.contains(where: {$0.name == sound.name}) {
                    loadedSounds.append(sound)
                    //processes big files asynchronously, to avoid blocking UI
                    //in chess app it is not necessary to play music(sounds can`t have such big size) immediately,
                    //otherwise we could have add callback here and loadingSpinner in UI
                    //or another solution is to load all sounds and music at the start of the app
                    if audioData.MB > constants.bigFileSizeMB {
                        DispatchQueue.global().async {[weak self] in
                            self?.loadSound(sound, audioData: audioData, volume: volume)
                        }
                    }
                    else {
                        loadSound(sound, audioData: audioData, volume: volume)
                    }
                }
            }
        }
    }
    
    private func loadSound(_ sound: Sound, audioData: Data, volume: Float) {
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
    static let bigFileSizeMB = 100.0
}
