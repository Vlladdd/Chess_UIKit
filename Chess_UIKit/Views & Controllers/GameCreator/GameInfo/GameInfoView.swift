//
//  GameInfoView.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 06.03.2023.
//

import UIKit

//class that represents view with game info, which is basically just multiple DataLines
class GameInfoView: UIScrollView, PickerDelegate {
    
    // MARK: - PickerDelegate
    
    func doneAction<T>(_ picker: Picker<T>) where T : RawRepresentable, T.RawValue == String {
        if let picker = picker as? Picker<GameModes> {
            if let rewindLine {
                if let mode = picker.pickedData, mode as GameModes == .oneScreen {
                    if rewindLine.isHidden {
                        UIView.animate(withDuration: constants.animationDuration, animations: {
                            rewindLine.isHidden = false
                        })
                        audioPlayer.playSound(Sounds.moveSound2)
                    }
                }
                else {
                    if !rewindLine.isHidden {
                        UIView.animate(withDuration: constants.animationDuration, animations: {
                            rewindLine.isHidden = true
                        })
                        audioPlayer.playSound(Sounds.moveSound2)
                    }
                }
            }
        }
    }
    
    // MARK: - Properties
    
    private typealias constants = GameInfoView_Constants
    
    private(set) var modePicker: Picker<GameModes>!
    private(set) var colorPicker: Picker<GameColors>!
    private(set) var rewindLine: DataLine!
    //chess timer availability
    private(set) var timerSwitch = UISwitch()
    
    private let font: UIFont
    private let storage = Storage.sharedInstance
    private let audioPlayer = AudioPlayer.sharedInstance
    
    private var totalTimeMinutesLine: DataLine!
    private var totalTimeSecondsLine: DataLine!
    private var additionalTimeMinutesLine: DataLine!
    private var additionalTimeSecondsLine: DataLine!
    private var additionalTimeLine: DataLine!
    private var totalTimeLine: DataLine!
    
    // MARK: - Inits
    
    init(font: UIFont) {
        self.font = font
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Buttons Methods
    
    //shows/hides info about chess timer
    @objc private func toggleTimerInfo(_ sender: UISwitch? = nil) {
        let viewsToToggle = [totalTimeLine, totalTimeMinutesLine, totalTimeSecondsLine, additionalTimeLine, additionalTimeMinutesLine, additionalTimeSecondsLine]
        if let sender {
            UIView.animate(withDuration: constants.animationDuration, animations: {
                for view in viewsToToggle {
                    view?.isHidden = !sender.isOn
                }
            })
            audioPlayer.playSound(Sounds.moveSound2)
        }
    }
    
    @objc private func changeTotalMinutes(_ sender: UIStepper? = nil) {
        if let sender {
            (totalTimeMinutesLine.data as? UILabel)?.text = String(Int(sender.value))
        }
    }
    
    @objc private func changeTotalSeconds(_ sender: UIStepper? = nil) {
        if let sender {
            (totalTimeSecondsLine.data as? UILabel)?.text = String(Int(sender.value))
        }
    }
    
    @objc private func changeAdditionalMinutes(_ sender: UIStepper? = nil) {
        if let sender {
            (additionalTimeMinutesLine.data as? UILabel)?.text = String(Int(sender.value))
        }
    }
    
    @objc private func changeAdditionalSeconds(_ sender: UIStepper? = nil) {
        if let sender {
            (additionalTimeSecondsLine.data as? UILabel)?.text = String(Int(sender.value))
        }
    }
    
    // MARK: - Local Methods
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        delaysContentTouches = false
        let gameInfoStack = UIStackView()
        gameInfoStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let modeLine = makeModeLine()
        modePicker = modeLine.data as? Picker<GameModes>
        modePicker.pickerDelegate = self
        makeRewindLine()
        let colorLine = makeColorLine()
        colorPicker = colorLine.data as? Picker<GameColors>
        let timerLine = makeTimerLine()
        timerSwitch = timerLine.data as! UISwitch
        totalTimeLine = makeTimeLine(with: "Total time")
        additionalTimeLine = makeTimeLine(with: "+Time per turn")
        totalTimeMinutesLine = makeValueTimeLine(with: "Minutes", minValue: constants.minMinutesForTotalTimer, maxValue: constants.maxMinutesForTotalTimer, and: #selector(changeTotalMinutes))
        totalTimeSecondsLine = makeValueTimeLine(with: "Seconds", minValue: constants.minSecondsForTimer, maxValue: constants.maxSecondsForTimer, and: #selector(changeTotalSeconds))
        additionalTimeMinutesLine = makeValueTimeLine(with: "Minutes", minValue: constants.minMinutesForAdditionalTimer, maxValue: constants.maxMinutesForAdditionalTimer, and: #selector(changeAdditionalMinutes))
        additionalTimeSecondsLine = makeValueTimeLine(with: "Seconds", minValue: constants.minSecondsForTimer, maxValue: constants.maxSecondsForTimer, and: #selector(changeAdditionalSeconds))
        let viewsToHide = [totalTimeLine, additionalTimeLine, totalTimeMinutesLine, totalTimeSecondsLine, additionalTimeMinutesLine, additionalTimeSecondsLine]
        for view in viewsToHide {
            view?.isHidden = true
        }
        gameInfoStack.addArrangedSubviews([modeLine, rewindLine, colorLine, timerLine, totalTimeLine, totalTimeMinutesLine, totalTimeSecondsLine])
        gameInfoStack.addArrangedSubviews([additionalTimeLine, additionalTimeMinutesLine, additionalTimeSecondsLine])
        let gameInfoStackHeight = gameInfoStack.heightAnchor.constraint(equalTo: heightAnchor)
        gameInfoStackHeight.priority = .defaultLow
        addSubview(gameInfoStack)
        let gameInfoStackConstraints = [gameInfoStack.topAnchor.constraint(equalTo: topAnchor), gameInfoStack.leadingAnchor.constraint(equalTo: leadingAnchor), gameInfoStack.trailingAnchor.constraint(equalTo: trailingAnchor), gameInfoStack.bottomAnchor.constraint(equalTo: bottomAnchor), gameInfoStack.widthAnchor.constraint(equalTo: widthAnchor), gameInfoStackHeight]
        NSLayoutConstraint.activate(gameInfoStackConstraints)
    }
    
    private func makeModeLine() -> DataLine {
        CGDLBuilder()
            .addLabel(with: font, and: "Mode")
            .addPicker(with: "Pick mode", font: font, data: storage.currentUser.guestMode ? [GameModes.oneScreen] : GameModes.allCases)
            .build()
    }
    
    private func makeRewindLine() {
        rewindLine = CGDLBuilder()
            .addLabel(with: font, and: "Enable rewind")
            .addSwitch(with: false, and: nil)
            .build()
        rewindLine.isHidden = (modePicker.pickedData ?? .multiplayer) != .oneScreen
    }
    
    private func makeColorLine() -> DataLine {
        CGDLBuilder()
            .addLabel(with: font, and: "Your color")
            .addPicker(with: "Pick color", font: font, data: GameColors.allCases)
            .build()
    }
    
    private func makeTimerLine() -> DataLine {
        CGDLBuilder()
            .addLabel(with: font, and: "Enable timer")
            .addSwitch(with: false, and: #selector(toggleTimerInfo))
            .build()
    }
    
    private func makeTimeLine(with name: String) -> DataLine {
        CGDLBuilder()
            .addLabel(with: font, and: name)
            .build()
    }
    
    private func makeValueTimeLine(with name: String, minValue: Double, maxValue: Double, and selector: Selector) -> DataLine {
        CGDLBuilder()
            .addLabel(with: font, and: name)
            .addStepper(with: minValue, maxValue: maxValue, stepValue: constants.stepValueForTimer, and: selector)
            .addLabel(with: font, and: String(Int(minValue)), isData: true)
            .build()
    }
    
    func getTotalTime() -> Int {
        let totalTimeMinutesValue = totalTimeMinutesLine.data as! UILabel
        let totalTimeSecondsValue = totalTimeSecondsLine.data as! UILabel
        return (Int(totalTimeMinutesValue.text!) ?? 0).seconds + (Int(totalTimeSecondsValue.text!) ?? 0)
    }
    
    func getAdditionalTime() -> Int {
        let additionalTimeMinutesValue = additionalTimeMinutesLine.data as! UILabel
        let additionalTimeSecondsValue = additionalTimeSecondsLine.data as! UILabel
        return (Int(additionalTimeMinutesValue.text!) ?? 0).seconds + (Int(additionalTimeSecondsValue.text!) ?? 0)
    }
    
}

// MARK: - Constants

private struct GameInfoView_Constants {
    static let optimalSpacing = 5.0
    static let animationDuration = 0.5
    static let minMinutesForTotalTimer = 1.0
    static let minMinutesForAdditionalTimer = 0.0
    static let maxMinutesForTotalTimer = 60.0
    static let maxMinutesForAdditionalTimer = 1.0
    static let minSecondsForTimer = 0.0
    static let maxSecondsForTimer = 59.0
    static let stepValueForTimer = 1.0
}
