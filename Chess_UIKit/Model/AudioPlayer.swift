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

    //loaded music or sounds
    private var loadedAudio = [AudioFile]()
    
    static let sharedInstance = AudioPlayer()
    
    private typealias constants = AudioPlayer_Constants
    
    // MARK: - Inits
    
    //singleton
    private init() {}
    
    // MARK: - Methods
    
    func playSound(_ sound: SoundItem, volume: Float = constants.defaultVolume) {
        if (sound as? Sounds != nil && soundsEnabled) || (sound as? Music != nil && musicEnabled) {
            if let audioFile = loadedAudio.first(where: {$0.sound.name == sound.name}) {
                audioFile.updateExpectedStatus(newValue: .playing)
            }
            else if let soundPath = sound.getFullPath() {
                guard let audioData = NSDataAsset(name: soundPath)?.data else { return }
                let audioFile = AudioFile(sound: sound, data: audioData)
                loadedAudio.append(audioFile)
                //processes big files asynchronously, to avoid blocking UI
                //in chess app it is not necessary to play music(sounds can`t have such big size) immediately,
                //otherwise we could have add callback here and loadingSpinner in UI
                //or another solution is to load all sounds and music at the start of the app
                if audioFile.sizeMB > constants.bigFileSizeMB {
                    audioFile.updateCurrentStatus(newValue: .loading)
                    DispatchQueue.global().async {[weak self] in
                        self?.loadAudio(audioFile, volume: volume)
                    }
                }
                else {
                    loadAudio(audioFile, volume: volume)
                }
                audioFile.updateExpectedStatus(newValue: .playing)
            }
        }
    }
    
    private func loadAudio(_ audioFile: AudioFile, volume: Float) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let audioPlayer = try AVAudioPlayer(data: audioFile.data)
            audioPlayer.volume = volume
            audioPlayer.numberOfLoops = audioFile.sound as? Music != nil ? constants.numberOfLoopsForMusic : 0
            audioFile.updatePlayer(newValue: audioPlayer)
            audioFile.updateCurrentStatus(newValue: audioFile.expectedStatus)
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func pauseSound(_ sound: SoundItem) {
        if let audioFile = loadedAudio.first(where: {$0.sound.name == sound.name}) {
            audioFile.updateExpectedStatus(newValue: .paused)
        }
    }
    
}

// MARK: - Constants

private struct AudioPlayer_Constants {
    static let numberOfLoopsForMusic = -1
    static let defaultVolume: Float = 1.0
    static let bigFileSizeMB = 100.0
}
