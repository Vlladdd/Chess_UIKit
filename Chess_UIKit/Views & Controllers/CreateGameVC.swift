//
//  CreateGameVC.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 15.09.2022.
//

import UIKit

//VC that represents view to create game
class CreateGameVC: UIViewController {
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //we are making retain cycle, when attaching our functions to picker, so need to break it
        modePicker.breakRetainCycle()
        timerPicker.breakRetainCycle()
    }
    
    // MARK: - Properties
    
    private typealias constants = CreateGameVC_Constants
    
    var currentUser: User!
    
    // MARK: - Buttons Methods
    
    @objc private func changeTotalMinutes(_ sender: UIStepper? = nil) {
        if let sender = sender {
            totalTimeMinutesValue.text = String(Int(sender.value))
        }
    }
    
    @objc private func changeTotalSeconds(_ sender: UIStepper? = nil) {
        if let sender = sender {
            totalTimeSecondsValue.text = String(Int(sender.value))
        }
    }
    
    @objc private func changeAdditionalMinutes(_ sender: UIStepper? = nil) {
        if let sender = sender {
            additionalTimeMinutesValue.text = String(Int(sender.value))
        }
    }
    
    @objc private func changeAdditionalSeconds(_ sender: UIStepper? = nil) {
        if let sender = sender {
            additionalTimeSecondsValue.text = String(Int(sender.value))
        }
    }
    
    @objc private func createGame(_ sender: UIBarButtonItem? = nil) {
        let alert = UIAlertController(title: "Error", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        let condition1 = timerPicker.pickedData != nil && modePicker.pickedData != nil
        let condition2 = rewindPicker.pickedData != nil || modePicker.pickedData == .multiplayer
        if condition1 && condition2 && colorPicker.pickedData != nil {
            switch modePicker.pickedData! {
            case .oneScreen:
                let secondUser = User(email: "Player2", nickname: "Player2")
                var totalTime = 0
                var additionalTime = 0
                if timerPicker.pickedData == .yes {
                    totalTime = (Int(totalTimeMinutesValue.text!) ?? 0).seconds + (Int(totalTimeSecondsValue.text!) ?? 0)
                    additionalTime = (Int(additionalTimeMinutesValue.text!) ?? 0).seconds + (Int(additionalTimeSecondsValue.text!) ?? 0)
                }
                let gameLogic = GameLogic(firstUser: currentUser, secondUser: secondUser, gameMode: .oneScreen, firstPlayerColor: colorPicker.pickedData!, rewindEnabled: rewindPicker.pickedData! == .yes ? true : false, totalTime: totalTime, additionalTime: additionalTime)
                let gameVC = GameViewController()
                gameVC.gameLogic = gameLogic
                gameVC.currentUser = currentUser
                gameVC.modalPresentationStyle = .fullScreen
                dismiss(animated: true) {
                    UIApplication.getTopMostViewController()?.present(gameVC, animated: true)
                }
            //TODO: -
            case .multiplayer:
                print(1)
            }
            //
        }
        else {
            alert.message = "Pick data for all fields!"
            present(alert, animated: true)
        }
    }
    
    @objc private func close(_ sender: UIBarButtonItem? = nil) {
        dismiss(animated: true)
    }
    
    // MARK: - Local Methods
    
    private func doneModePicker() {
        let viewToToggle = rewindLine
        if let mode = modePicker.pickedData, mode as GameModes == .oneScreen {
            if viewToToggle.isHidden {
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    viewToToggle.isHidden = false
                })
            }
        }
        else {
            if !viewToToggle.isHidden {
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    viewToToggle.isHidden = true
                })
            }
        }
    }
    
    private func doneTimerPicker() {
        let viewsToToggle = [totalTimeLine, totalTimeMinutesLine, totalTimeSecondsLine, additionalTimeLine, additionalTimeMinutesLine, additionalTimeSecondsLine]
        if let enableTimer = timerPicker.pickedData, enableTimer as Answers == .yes {
            if viewsToToggle.first!.isHidden {
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    for view in viewsToToggle {
                        view.isHidden = false
                    }
                })
            }
        }
        else {
            if !viewsToToggle.first!.isHidden {
                UIView.animate(withDuration: constants.animationDuration, animations: {
                    for view in viewsToToggle {
                        view.isHidden = true
                    }
                })
            }
        }
    }
    
    // MARK: - UI
    
    // MARK: - UI Properties
    
    private lazy var font = UIFont.systemFont(ofSize: min(view.frame.width, view.frame.height) / constants.dividerForFont)
    private lazy var modePicker = Picker(placeholder: "Pick mode", font: font, data: GameModes.allCases, doneAction: doneModePicker)
    private lazy var colorPicker = Picker(placeholder: "Pick color", font: font, data: GameColors.allCases)
    private lazy var timerPicker = Picker(placeholder: "Pick answer", font: font, data: Answers.allCases, doneAction: doneTimerPicker)
    private lazy var rewindPicker = Picker(placeholder: "Pick answer", font: font, data: Answers.allCases)
    
    private var rewindLine = UIStackView()
    private var totalTimeLine = UIStackView()
    private var totalTimeMinutesLine = UIStackView()
    private var totalTimeSecondsLine = UIStackView()
    private var additionalTimeLine = UIStackView()
    private var additionalTimeMinutesLine = UIStackView()
    private var additionalTimeSecondsLine = UIStackView()
    
    private let scrollView = UIScrollView()
    private let scrollViewContent = UIView()
    private let totalTimeMinutesValue = UILabel()
    private let totalTimeSecondsValue = UILabel()
    private let additionalTimeMinutesValue = UILabel()
    private let additionalTimeSecondsValue = UILabel()
    //size is random, without it, it will make unsatisfied constraints errors
    private let toolbar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 44.0)))
    private let dataFieldsStack = UIStackView()
    
    // MARK: - UI Methods
    
    private func makeUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        makeToolBar()
        makeScrollView()
        makeDataFields()
    }
    
    private func makeDataFields() {
        dataFieldsStack.setup(axis: .vertical, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        let modeLine = makeModeLine()
        makeRewindLine()
        let colorLine = makeColorLine()
        let timerLine = makeTimerLine()
        makeTotalTimeLines()
        makeAdditionalTimeLines()
        dataFieldsStack.addArrangedSubviews([modeLine, rewindLine, colorLine, timerLine, totalTimeLine, totalTimeMinutesLine, totalTimeSecondsLine])
        dataFieldsStack.addArrangedSubviews([additionalTimeLine, additionalTimeMinutesLine, additionalTimeSecondsLine])
        scrollViewContent.addSubview(dataFieldsStack)
        let dataConstraints = [dataFieldsStack.centerXAnchor.constraint(equalTo: scrollViewContent.centerXAnchor), dataFieldsStack.topAnchor.constraint(equalTo: scrollViewContent.topAnchor), dataFieldsStack.leadingAnchor.constraint(equalTo: scrollViewContent.layoutMarginsGuide.leadingAnchor), dataFieldsStack.trailingAnchor.constraint(equalTo: scrollViewContent.layoutMarginsGuide.trailingAnchor), dataFieldsStack.bottomAnchor.constraint(lessThanOrEqualTo: scrollViewContent.bottomAnchor)]
        NSLayoutConstraint.activate(dataConstraints)
    }
    
    private func makeModeLine() -> UIStackView {
        let modeLabel = UILabel()
        modeLabel.setup(text: "Mode", alignment: .center, font: font)
        return makeDataLine(with: [modeLabel, modePicker])
    }
    
    private func makeRewindLine() {
        let rewindLabel = UILabel()
        rewindLabel.setup(text: "Enable rewind", alignment: .center, font: font)
        rewindLine = makeDataLine(with: [rewindLabel, rewindPicker], isHidden: true)
    }
    
    private func makeColorLine() -> UIStackView {
        let colorLabel = UILabel()
        colorLabel.setup(text: "Your color", alignment: .center, font: font)
        return makeDataLine(with: [colorLabel, colorPicker])
    }
    
    private func makeTimerLine() -> UIStackView {
        let timerLabel = UILabel()
        timerLabel.setup(text: "Enable timer", alignment: .center, font: font)
        return makeDataLine(with: [timerLabel, timerPicker])
    }
    
    private func makeDataLine(with views: [UIView], isHidden: Bool = false) -> UIStackView {
        let data = UIStackView()
        data.setup(axis: .horizontal, alignment: .fill, distribution: .fillEqually, spacing: constants.optimalSpacing)
        for view in views {
            data.addArrangedSubview(view)
        }
        data.isHidden = isHidden
        return data
    }
    
    private func makeTotalTimeLines() {
        let totalTimeLabel = UILabel()
        totalTimeLabel.setup(text: "Total time", alignment: .center, font: font)
        let totalTimeMinutesLabel = UILabel()
        totalTimeMinutesLabel.setup(text: "Minutes", alignment: .center, font: font)
        totalTimeMinutesValue.setup(text: "1", alignment: .center, font: font)
        totalTimeMinutesValue.labelWithBorderAndCornerRadius()
        let totalTimeMinutesStepper = UIStepper()
        totalTimeMinutesStepper.stepperWith(minValue: constants.minMinutesForTotalTimer, maxValue: constants.maxMinutesForTotalTimer, stepValue: constants.stepValueForTimer, and: #selector(changeTotalMinutes))
        let totalTimeSecondsLabel = UILabel()
        totalTimeSecondsLabel.setup(text: "Seconds", alignment: .center, font: font)
        totalTimeSecondsValue.setup(text: "0", alignment: .center, font: font)
        totalTimeSecondsValue.labelWithBorderAndCornerRadius()
        let totalTimeSecondsStepper = UIStepper()
        totalTimeSecondsStepper.stepperWith(minValue: constants.minSecondsForTimer, maxValue: constants.maxSecondsForTimer, stepValue: constants.stepValueForTimer, and: #selector(changeTotalSeconds))
        totalTimeLine = makeDataLine(with: [totalTimeLabel], isHidden: true)
        totalTimeMinutesLine = makeDataLine(with: [totalTimeMinutesLabel, makeSpecialViewForStepper(totalTimeMinutesStepper), totalTimeMinutesValue], isHidden: true)
        totalTimeSecondsLine = makeDataLine(with: [totalTimeSecondsLabel, makeSpecialViewForStepper(totalTimeSecondsStepper), totalTimeSecondsValue], isHidden: true)
    }
    
    private func makeAdditionalTimeLines() {
        let additionalTimeLabel = UILabel()
        additionalTimeLabel.setup(text: "+Time per turn", alignment: .center, font: font)
        let additionalTimeMinutesLabel = UILabel()
        additionalTimeMinutesLabel.setup(text: "Minutes", alignment: .center, font: font)
        additionalTimeMinutesValue.setup(text: "0", alignment: .center, font: font)
        additionalTimeMinutesValue.labelWithBorderAndCornerRadius()
        let additionalTimeMinutesStepper = UIStepper()
        additionalTimeMinutesStepper.stepperWith(minValue: constants.minMinutesForAdditionalTimer, maxValue: constants.maxMinutesForAdditionalTimer, stepValue: constants.stepValueForTimer, and: #selector(changeAdditionalMinutes))
        let additionalTimeSecondsLabel = UILabel()
        additionalTimeSecondsLabel.setup(text: "Seconds", alignment: .center, font: font)
        additionalTimeSecondsValue.setup(text: "0", alignment: .center, font: font)
        additionalTimeSecondsValue.labelWithBorderAndCornerRadius()
        let additionalTimeSecondsStepper = UIStepper()
        additionalTimeSecondsStepper.stepperWith(minValue: constants.minSecondsForTimer, maxValue: constants.maxSecondsForTimer, stepValue: constants.stepValueForTimer, and: #selector(changeAdditionalSeconds))
        additionalTimeLine = makeDataLine(with: [additionalTimeLabel], isHidden: true)
        additionalTimeMinutesLine = makeDataLine(with: [additionalTimeMinutesLabel, makeSpecialViewForStepper(additionalTimeMinutesStepper), additionalTimeMinutesValue], isHidden: true)
        additionalTimeSecondsLine = makeDataLine(with: [additionalTimeSecondsLabel, makeSpecialViewForStepper(additionalTimeSecondsStepper), additionalTimeSecondsValue], isHidden: true)
    }
    
    //stepper is not well animatable
    //by putting it in another view and making layer.masksToBounds = true, we are fixing this problem
    private func makeSpecialViewForStepper(_ stepper: UIStepper) -> UIView {
        let specialView = UIView()
        specialView.translatesAutoresizingMaskIntoConstraints = false
        specialView.layer.masksToBounds = true
        specialView.addSubview(stepper)
        let specialViewConstraints = [stepper.centerXAnchor.constraint(equalTo: specialView.centerXAnchor), stepper.centerYAnchor.constraint(equalTo: specialView.centerYAnchor)]
        NSLayoutConstraint.activate(specialViewConstraints)
        return specialView
    }
    
    private func makeToolBar() {
        let toolbarBackgroundColor = traitCollection.userInterfaceStyle == .dark ? constants.darkModeBackgroundColor : constants.lightModeBackgroundColor
        let toolbarBackground = toolbarBackgroundColor.image()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.setBackgroundImage(toolbarBackground, forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(toolbarBackground, forToolbarPosition: .any)
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        let closeButton = UIBarButtonItem(title: "Close", style: UIBarButtonItem.Style.plain, target: self, action: #selector(close))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let createGameButton = UIBarButtonItem(title: "Create", style: UIBarButtonItem.Style.done, target: self, action: #selector(createGame))
        toolbar.setItems([closeButton, spaceButton, createGameButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        view.addSubview(toolbar)
        let toolbarConstraints = [toolbar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor), toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor), toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
        NSLayoutConstraint.activate(toolbarConstraints)
    }
    
    private func makeScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewContent.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delaysContentTouches = false
        view.addSubview(scrollView)
        scrollView.addSubview(scrollViewContent)
        let contentHeight = scrollViewContent.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        let scrollViewConstraints = [scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor), scrollView.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor, constant: constants.optimalDistance), scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)]
        let contentConstraints = [scrollViewContent.topAnchor.constraint(equalTo: scrollView.topAnchor), scrollViewContent.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor), scrollViewContent.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor), scrollViewContent.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor), scrollViewContent.widthAnchor.constraint(equalTo: scrollView.widthAnchor), contentHeight]
        NSLayoutConstraint.activate(scrollViewConstraints + contentConstraints)
    }
    
    
}

// MARK: - Constants

private struct CreateGameVC_Constants {
    static let optimalDistance = 20.0
    static let dividerForFont: CGFloat = 13
    static let optimalSpacing = 5.0
    static let animationDuration = 0.5
    static let optimalAlpha = 0.5
    static let darkModeBackgroundColor = UIColor.black.withAlphaComponent(optimalAlpha)
    static let lightModeBackgroundColor = UIColor.white.withAlphaComponent(optimalAlpha)
    static let defaultAnchorPoint = CGPoint(x: 0.5, y: 0.5)
    static let anchorPointForDataInDataStack = CGPoint(x: 0.5, y: 0)
    static let transformForLabelInDataStack = CGAffineTransform(scaleX: 0.01, y: 0.01)
    static let transformForTextFieldAndStepperInDataStack = CGAffineTransform(scaleX: 1, y: 0.01)
    static let minMinutesForTotalTimer = 1.0
    static let minMinutesForAdditionalTimer = 0.0
    static let maxMinutesForTotalTimer = 60.0
    static let maxMinutesForAdditionalTimer = 1.0
    static let minSecondsForTimer = 0.0
    static let maxSecondsForTimer = 59.0
    static let stepValueForTimer = 1.0
}
