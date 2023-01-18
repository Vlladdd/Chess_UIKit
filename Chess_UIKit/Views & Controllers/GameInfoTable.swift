//
//  GameInfoTable.swift
//  Chess_UIKit
//
//  Created by Vlad Nechyporenko on 26.09.2022.
//

import UIKit

//class that represents custom table
class GameInfoTable: UITableView, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    private var data: [Int: [String]] = [:]
    private var dataFont: UIFont!
    
    private typealias constants = GameInfoTable_Constants
    
    // MARK: - Inits
    
    init(gameData: GameLogic, dataFont: UIFont) {
        super.init(frame: .zero, style: .insetGrouped)
        self.dataFont = dataFont
        data[0] = ["Game mode", gameData.gameMode.asString]
        data[1] = ["Rewind enabled", gameData.rewindEnabled ? Answers.yes.asString : Answers.no.asString]
        if gameData.timerEnabled {
            data[2] = ["Total time", gameData.totalTime.timeAsString]
            data[3] = ["+Time per turn", gameData.additionalTime.timeAsString]
        }
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    private func setup() {
        backgroundColor = backgroundColor?.withAlphaComponent(constants.optimalAlpha)
        register(UITableViewCell.self, forCellReuseIdentifier: constants.keyForTableCell)
        dataSource = self
        delegate = self
        translatesAutoresizingMaskIntoConstraints = false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: constants.keyForTableCell, for: indexPath as IndexPath)
        var content = cell.defaultContentConfiguration()
        content.text = "\(data[indexPath.section]?.second ?? "")"
        content.textProperties.font = dataFont
        cell.contentConfiguration = content
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    //at first i had titleForHeaderInSection and willDisplayHeaderForSection, but for some reasons
    //UITableView.automaticDimension doesn`t work properly, when we change font of header in willDisplayHeaderView,
    //so instead i decided to make custom view for header and now it works perfect
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let headerLabel = UILabel()
        headerLabel.setup(text: data[section]?.first ?? "", alignment: .center, font: UIFont.boldSystemFont(ofSize: dataFont.pointSize * constants.multiplayerForHeaderFont))
        headerView.addSubview(headerLabel)
        let headerLabelConstraints = [headerLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor), headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor), headerLabel.heightAnchor.constraint(equalTo: headerView.heightAnchor, multiplier: constants.multiplayerForHeaderLabelHeight)]
        NSLayoutConstraint.activate(headerLabelConstraints)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

// MARK: - Constants

private struct GameInfoTable_Constants {
    static let optimalAlpha = 0.5
    static let multiplayerForHeaderLabelHeight = 0.8
    static let multiplayerForHeaderFont = 1.5
    static let keyForTableCell = "MyCell"
}
