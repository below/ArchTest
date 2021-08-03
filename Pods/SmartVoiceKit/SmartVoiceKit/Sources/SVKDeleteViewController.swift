//
//
// Software Name: Smart Voice Kit - SmartvoiceKit
//
// SPDX-FileCopyrightText: Copyright (c) 2017-2021 Orange
//
// This software is confidential and proprietary information of Orange.
// You are not allowed to disclose such Confidential Information nor to copy, use,
// modify, or distribute it in whole or in part without the prior written
// consent of Orange.
//
// Author: The current developers of this code can be
// found in the authors.txt file at the root of the project
//
// Software description: Smart Voice Kit is the iOS SDK that allows to
// integrate the Smart Voice Hub voice assistant into your app.
//
// Module description: The main framework for the Smart Voice Kit is the iOS SDK
// to integrate the Smart Voice Hub Audio Assistant inside your App.
//


import UIKit

protocol SVKDeleteDelegate: class {
    func deleteSelectedMessages(conversations: SVKConversationDescription)
    func cancelRequest()
}

public class SVKDeleteViewController: UIViewController {
    /// The tableView thats handles bubbles display
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var deleteHeaderView: SVKTableDeleteHeader!
    @IBOutlet weak var deleteHistroyButton: SVKCustomButtonHighlighted!
    @IBOutlet weak var cancelHistroyButton: SVKCustomButton!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsContainer: SVKStandardPageButtonView!
    
    //Holds all the conversation bubbles
    internal var conversation = SVKConversationDescription()
    
    /// The delete view controller delegate
    weak var delegate: SVKDeleteDelegate?
    
    /// Used to manage the delete check/uncheck of cells and avoid
    /// weird scrolling/artefact displays on various iOS version
    /// see method tableView...wilDisplayCell and tableView...estimatedRowHeight
    var cellHeightDict = [Int:CGFloat]()
        
    /// Cells that need to be animated after selection
    public var cellsToAnimate: [IndexPath] = []

    internal var bubbleKeyIndex: Int = 0
    internal var nextBubbleKey: Int {
        bubbleKeyIndex += 1
        return bubbleKeyIndex
    }
    var isDefaultErrorsExpanded = false
    
    /// true if the viewController is in edit mode
    override public var isEditing: Bool {
        set {
            tableView.allowsMultipleSelectionDuringEditing = newValue
            self.tableView.setEditing(newValue, animated: true)
        }
        get {
            return tableView.isEditing && tableView.allowsMultipleSelectionDuringEditing
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        isEditing = true
        addGestureRecognizer()
        setTitleHeader()
        deleteHistroyButton.setTitle("DC.history.delete.button".localized, for: UIControl.State.normal)
        cancelHistroyButton.setTitle("navigationBar.menu.cancel".localized, for: UIControl.State.normal)
        tableView.backgroundView = UIView(frame: .zero)
        
        let nib = UINib(nibName: "SVKSectionHeader", bundle: SVKBundle)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "SVKSectionIdentifier")
        if !isDefaultErrorsExpanded {
            expandAllError()
            isDefaultErrorsExpanded = !isDefaultErrorsExpanded
        }
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buttonsContainer.updateSeparatorLine()
        tableView.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        DispatchQueue.main.async {
            let indexPath = self.conversation.lastElementIndexPath
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    public func setTitleHeader() {
        if navigationController == nil {
            if #available(iOS 11.0, *) {
                let topArea = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
                headerHeightConstraint.constant = SVKConstant.HeaderHeight.defaultHeight + topArea
            } else {
                headerHeightConstraint.constant = SVKConstant.HeaderHeight.heightWithSafeArea
            }
            deleteHeaderView.backgroundColor = SVKConversationAppearance.shared.tintColor
        }
    }
    
    // calls delegate method to notify SVKConversationViewController to delete messages
    @IBAction func didTapOnDeleteBtn(_ sender: Any) {
        delegate?.deleteSelectedMessages(conversations: conversation)
        self.dismiss(animated: true, completion: nil)
        //deleteSelectedHistoryEntries()
    }
    
    @IBAction func didTapOnCancelBtn(_ sender: Any) {
        delegate?.cancelRequest()
        self.dismiss(animated: true, completion: nil)
    }
}

// TableView methods
extension SVKDeleteViewController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return conversation.sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversation[section].elements.count
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 62.0
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let bubbleDescription = self.conversation[indexPath]
        cellHeightDict[bubbleDescription.bubbleKey] = cell.frame.size.height
        
        guard let cell = cell as? SVKTableViewCell else { return }
        if cellsToAnimate.contains(indexPath) {
            cell.updateCellBeforeDisplay()
            UIView.animate(withDuration: 0.3) {
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
            }

            cellsToAnimate.removeAll { $0 == indexPath }
        } else {
            cell.updateCellBeforeDisplay()
        }
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let bubbleDescription = self.conversation[indexPath]
        if let cellHeight = cellHeightDict[bubbleDescription.bubbleKey] {
            return cellHeight
        }
        return UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard isEditing else { return nil }
        
        let header = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "SVKSectionIdentifier") as! SVKTableSectionHeader
        header.titleLabel.text = SVKTools.formattedDate(from: self.conversation[section].title)
        header.isSelected = self.conversation[section].isSelected
        header.backgroundView?.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        header.titleLabel.textColor = SVKAppearanceBox.cardTextColor
        header.delegate = self
        header.section = section
        return header
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let bubbleDescription = conversation[indexPath.section].elements[indexPath.row]
        
        var tableViewCell: SVKTableViewCell!
        
        if let description = bubbleDescription as? SVKUserBubbleDescription {
            switch description.contentType {
            case .waitingIndicator:
                tableViewCell = tableView.dequeueReusableCell(SVKUserThinkingIndicatorTableViewCell.self, for: indexPath)

            default:
                tableViewCell = tableView.dequeueReusableCell(SVKUserTextTableViewCell.self, for: indexPath)
            }
        } else if bubbleDescription is SVKHeaderErrorBubbleDescription {
            tableViewCell = tableView.dequeueReusableCell(SVKErrorHeaderTableViewCell.self, for: indexPath)
            if let errorCell = tableViewCell as? SVKErrorHeaderTableViewCell {
                errorCell.isTapGestureEnabled = false
            }
            
        } else {
            let description = bubbleDescription as! SVKAssistantBubbleDescription
            
            if description.card?.version == 3 || description.card?.version == 2 || (description.card?.version == 1 && description.card?.type == .genericDefault) || (description.card?.version == 1 && description.card?.type == .generic) {
                tableViewCell = tableView.dequeueReusableCell(SVKGenericDefaultCardV3TableViewCell.self, for: indexPath)
            } else {
                switch description.contentType {
                case .waitingIndicator:
                    tableViewCell = tableView.dequeueReusableCell(SVKThinkingIndicatorTableViewCell.self, for: indexPath)
                    
                case .genericCard:
                    if let layout = description.card?.data?.layout {
                        switch layout {
                        case .partner:
                            tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardPartnerTableViewCell.self, for: indexPath)
                        default:
                            tableViewCell = tableView.dequeueReusableCell(SVKAssistantGenericTableViewCell.self, for: indexPath)
                        }
                    } else {
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantGenericTableViewCell.self, for: indexPath)
                    }
                    
                case .memolistCard,
                     .timerCard,
                     .iotCard:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantGenericTableViewCell.self, for: indexPath)
                    
                case .image:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantImageTableViewCell.self, for: indexPath)
                    
                case .imageCard:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardImageTableViewCell.self, for: indexPath)
                    
                case .weatherCard:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardImageTableViewCell.self, for: indexPath)
                    
                case .musicCard:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardPartnerTableViewCell.self, for: indexPath)
                    
                case .audioController:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantGenericTableViewCell.self, for: indexPath)
                    
                case .recipeCard:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardImageTableViewCell.self, for: indexPath)
                    
                case .disabledText:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantDisabledTextTableViewCell.self, for: indexPath)
                    
                default:
                    tableViewCell = tableView.dequeueReusableCell(SVKAssistantTextTableViewCell.self, for: indexPath)
                }
            }
        }

        // fill the cell with some content
        tableViewCell.fill(with: bubbleDescription)
        
        tableViewCell.isTimestampHidden = isEditing || bubbleDescription.isTimestampHidden
        tableViewCell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.view.frame.width)
        
        if isEditing {
            if self.conversation[indexPath.section].isLastElement(at: indexPath.row) {
                tableViewCell.bottomConstraint?.constant = 7
            } else if bubbleDescription is SVKAssistantBubbleDescription {
                if let cell = tableViewCell as? SVKTableViewCellProtocol,
                    cell.bubbleStyle != .top(.left) {
                    tableViewCell.bottomConstraint?.constant = 7
                }
            }
            tableViewCell.bubbleLeadingConstraint?.constant = 16
        }
        return tableViewCell
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == conversation.sections.count - 1 {
            return 16.0
        }
        return 8.0
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        return footer
    }
    
    func reloadSectionWithoutScroll(at indexSet: IndexSet) {
        UIView.performWithoutAnimation {
            self.tableView.reloadSections(indexSet, with: .none)
        }
    }
}

// Add tap gesture to select/unselect conversations
extension SVKDeleteViewController: UIGestureRecognizerDelegate {
    private func addGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.tableView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.delegate = self
    }
    
    @objc
    private func handleTap(_ sender: UITapGestureRecognizer) {
        
        guard sender.state == .ended else { return }
        
        if self.tableView.indexPathForRow(at: sender.location(in: self.tableView)) == nil, isEditing {
            if let section = self.tableView.headerView(forSection: 0) as? SVKTableSectionHeader,
                section.frame.contains(sender.location(in: self.tableView)) {
                
                let firstSection = self.conversation.sections[0]
                if !firstSection.isSelected {
                    SVKAnalytics.shared.log(event: "myactivity_delete_selection_group")
                }
                firstSection.isSelected = !firstSection.isSelected
                self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
                var indexPaths:[IndexPath] = []
                for i in 0..<firstSection.elements.count {
                    firstSection.elements[i].isSelected = firstSection.isSelected
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
                
                if (indexPaths.count > 0) {
                    self.tableView.reloadRows(at: indexPaths, with: .none)
                }
                updateNumberOfSelectedItems()
                
                return
            }
        }
        
        
        guard let indexPath = self.tableView.indexPathForRow(at: sender.location(in: self.tableView)) else { return }
        
        let sectionDescription = self.conversation[indexPath.section]

        if isEditing {
            // section
            let sectionHeader = self.tableView.headerView(forSection: indexPath.section) as? SVKTableSectionHeader
            if !sectionDescription.elements[indexPath.row].isSelected {
                SVKAnalytics.shared.log(event: "myactivity_delete_selection_item")
            }
            update(selection: !sectionDescription.elements[indexPath.row].isSelected, forElementAtIndex: indexPath)
            sectionDescription.isSelected = false
            sectionHeader?.isSelected = false
            sectionHeader?.setNeedsLayout()
            updateNumberOfSelectedItems()
        }
    }
    
    private func update(selection isSelected: Bool, forElementAtIndex indexPath: IndexPath) {
        
        let selectedElement = conversation[indexPath.section].elements[indexPath.row]
        conversation[indexPath.section].elements[indexPath.row].isSelected = isSelected
        let relatedIndexPaths = conversation.indexPathOfElements(from: indexPath) {
            $0.historyID == selectedElement.historyID
        }
        for index in relatedIndexPaths {
            conversation[index.section].elements[index.row].isHighlighted = isSelected
            conversation[index.section].elements[index.row].isSelected = isSelected
        }
        
        if let visibleCells = tableView.indexPathsForVisibleRows {
            cellsToAnimate = relatedIndexPaths.filter { visibleCells.contains($0) }
        }
        self.tableView.reloadRows(at: relatedIndexPaths, with: .none)
    }
    
    internal func updateNumberOfSelectedItems() {
        var count = 0
        for s in 0..<conversation.sections.count {
            for r in 0..<conversation[s].elements.count {
                if conversation[s].elements[r].isSelected && conversation[s].elements[r].bubbleIndex == 0 {
                    count += 1
                }
            }
        }
        updateNumberOfSelectedItemsText(count: count)
    }
    
    internal func updateNumberOfSelectedItemsText(count: Int) {
        let key = count == 1 ? "DC.history.delete.count.format.single" : "DC.history.delete.count.format"
        deleteHeaderView.label.setTextWhileKeepingAttributes(string: String(format: key.localized, count))
        if count == 0 {
            self.deleteHistroyButton.isEnabled = false
        } else {
            self.deleteHistroyButton.isEnabled = true
        }
    }
    
    internal func resetItemsSelected() {
        for s in 0..<conversation.sections.count {
            for r in 0..<conversation[s].elements.count {
                conversation[s].elements[r].isSelected = false
                conversation[s].elements[r].isHighlighted = false
            }
        }
        updateNumberOfSelectedItemsText(count: 0)
    }
}

// Select/Unselect all conversations by tapping on header
extension SVKDeleteViewController: SVKTableSectionHeaderDelegate {
    func toggleSelection(section: Int) {
        let sectionDescription = self.conversation[section]
        if !sectionDescription.isSelected {
            SVKAnalytics.shared.log(event: "myactivity_delete_selection_group")
        }
        sectionDescription.isSelected = !sectionDescription.isSelected
        self.reloadSectionWithoutScroll(at: IndexSet(integer: section))
        for i in 0..<sectionDescription.elements.count {
            if (sectionDescription.elements[i].bubbleIndex == 0) {
                update(selection: sectionDescription.isSelected, forElementAtIndex: IndexPath(row: i, section: section))
            }
        }

        updateNumberOfSelectedItems()
    }
}

// It will expand & show all the error conversations
extension SVKDeleteViewController: SVKActionErrorDelegate {
    func toggleAction(from description: SVKHeaderErrorBubbleDescription) {}
    
    internal func expandAllError() {
        let collapsedHeaders = self.conversation.filter { (bubbleDescrition) -> Bool in
            if let bubbleErrorDescriton = bubbleDescrition as? SVKHeaderErrorBubbleDescription, !bubbleErrorDescriton.isExpanded {
                return true
            } else {
                return false
            }
        }
        
        let collapsedHeadersIndex = collapsedHeaders.map { (bubbleDescription) -> IndexPath in
            let ip = self.conversation.firstIndex { (bubbleDescriptionIt) -> Bool in
                return bubbleDescription.bubbleKey == bubbleDescriptionIt.bubbleKey
            }
            return ip ?? self.conversation.endIndex
        }

        collapsedHeadersIndex.reversed().forEach { (indexPath) in
            if var bubbleDescription = self.conversation[indexPath] as? SVKHeaderErrorBubbleDescription,  !bubbleDescription.isExpanded {
                bubbleDescription.isExpanded = true
                self.conversation[indexPath] = bubbleDescription
                var errorDescriptionEntries = bubbleDescription.bubbleDescriptionEntries
                let nextIndex = self.conversation.index(after: indexPath)
                insertBubbles(from: &errorDescriptionEntries, at: nextIndex.row, in: nextIndex.section, scrollEnabled: false,animation: .fade)
                bubbleDescription.bubbleDescriptionEntries = errorDescriptionEntries
                self.conversation[indexPath] = bubbleDescription
            }
        }
        resetItemsSelected()
        tableView.superview?.layoutIfNeeded()
        tableView.reloadData()
    }
}

extension SVKDeleteViewController {
    /**
     Insert bubbles in the conversation or in the history
     - parameter descriptions: bubbles descriptions
     - parameter position: the position from where the bubbles must be inserted
     - parameter section: the section in where the bubbles must be inserted
     - parameter scrollEnabled: true if the tableView should scrolls after insertions. Default is true
     */
    func insertBubbles(from descriptions: inout [SVKBubbleDescription], at position: Int = Int.max, in section: Int = Int.max, scrollEnabled: Bool = true, shouldClear: Bool = false,idForScrool: String? = nil,animation: UITableView.RowAnimation = .none) {
        
        guard descriptions.count > 0 else { return }
        
        // updating the tableview
        var numberOfInsertedRows = 0
        var numberOfInsertedSections = 0
        var indexPath = IndexPath(row: position, section: section)
        if position == Int.max || section == Int.max {
            indexPath = self.conversation.endIndex
        }
        for (i,d) in descriptions.enumerated() {
            
            self.tableView.beginUpdates()
            var description = d
            if let descriptionTimestamp = SVKTools.date(from: description.timestamp), !description.isEmpty {
                description.bubbleKey = self.nextBubbleKey
                if (self.conversation.sections.count == 0) {
                    // Creation de la premiere section si besoin
                    self.conversation.insert(SVKSectionDescription(timestamp: description.timestamp), at: 0)
                    indexPath = IndexPath(row: 0, section: 0)
                }
                
                let sectionDescription = self.conversation[indexPath.section]
                if sectionDescription.shouldContains(bubbleDescription: description) {
                    // l'insertion se fait en haut de la section
                    self.conversation[indexPath.section].elements.insert(description, at: indexPath.row)
                    if (numberOfInsertedSections == 0) {
                        numberOfInsertedRows += 1
                    }
                } else if indexPath.section - 1 >= 0, self.conversation[indexPath.section - 1 ].shouldContains(bubbleDescription: description) {
                    let newSection = indexPath.section - 1
                    let newRow = self.conversation[newSection].elements.count
                    self.conversation[newSection].elements.insert(description, at: self.conversation[newSection].elements.count)
                        indexPath = IndexPath(row: newRow, section: newSection)
                        numberOfInsertedSections += 1
                } else if indexPath.section + 1 < self.conversation.sections.count, self.conversation[indexPath.section + 1 ].shouldContains(bubbleDescription: description) {
                    let newSection = indexPath.section + 1
                    let newRow = 0
                    self.conversation[newSection].elements.insert(description, at: self.conversation[newSection].elements.count)
                        indexPath = IndexPath(row: newRow, section: newSection)
                        numberOfInsertedSections += 1
                } else if sectionDescription.timestamp < descriptionTimestamp {
                    // Ajout d'une nouvelle section tout en bas et insertion dans la nouvelle section
                    self.conversation.append(SVKSectionDescription(timestamp: description.timestamp))
                    indexPath = IndexPath(row: 0, section: indexPath.section + 1)
                    self.conversation[indexPath.section].elements.insert(description, at: 0)
                    numberOfInsertedSections += 1
                } else {
                    // Ajout d'une nouvelle section en haut et insertion dans la nouvelle section
                    self.conversation.insert(SVKSectionDescription(timestamp: description.timestamp), at: indexPath.section )
                    indexPath = IndexPath(row: 0, section: indexPath.section)
                    self.conversation[indexPath.section].elements.insert(description, at: 0)
                    numberOfInsertedSections += 1
                }
            
            } else {
                SVKLogger.warn("DATA NOT INSERTED: \(description)")
            }
            descriptions[i] = description
            self.tableView.endUpdates()
        }

        /// force the tableView to update it's content size
        self.tableView.layoutIfNeeded()
    }
}
