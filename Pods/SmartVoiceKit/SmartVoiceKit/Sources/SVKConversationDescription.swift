//
// Software Name: Smart Voice Kit - SmartvoiceKit
//
// SPDX-FileCopyrightText: Copyright (c) 2017-2020 Orange
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

import Foundation

/**
 This struct handles the data displayed by the conversation controller.
 
 Data are organized by section. A section groups elements by date.
 */
struct SVKConversationDescription {
    
    /** The sections. Each section contains elements of the same date */
    var sections = [SVKSectionDescription]()
    
    /// the collection iterator index
    var index = IndexPath(row: 0, section: 0)
    
    /**
     Returns true if the indexPath bounds fit the collection
     bounds
     - parameter indexPath: The indexPath to check
     - Returns true if the indexPath bounds fit the collection
     bounds false otherwise
     */
    func isBounded(indexPath: IndexPath) -> Bool {
        return indexPath.section >= 0 && indexPath.section < sections.count && indexPath.row >= 0 && indexPath.row < sections[indexPath.section].elements.count
    }
    
    /**
     Returns the section at index
     
     - parameter index: The index of the section to get
     - returns: Returns the section at index index
     */
    subscript(_ index: Int) -> SVKSectionDescription {
        return sections[index]
    }
    
    /**
     Returns the element wich is placed before indexPath
     
     This element could be in the previous indexPath.section
     - parameter indexPath: The indexPath from where the previous element should be retreive
     - returns: Returns the element at IndexPath before indexPath or nil
     */
    func elementBefore(_ indexPath: IndexPath) -> SVKBubbleDescription? {
        guard let indexPath = self.indexPath(before: indexPath) else { return nil }
        return self[indexPath]
    }
    
    /**
     Returns the element wich is placed after indexPath
     
     This element could be in the next indexPath.section
     - parameter indexPath: The indexPath from where the next element should be retreive
     - returns: Returns the element at IndexPath after indexPath or nil
     */
    func elementAfter(_ indexPath: IndexPath) -> SVKBubbleDescription? {
        guard let indexPath = self.indexPath(after: indexPath) else { return nil }
        return self[indexPath]
    }
    
    /**
     Returns true if the element is orphan
     
     An orphan element has no link with the previous and the nex element.
     The link is determine by the history ID
     */
    func isOrphanElement(at indexPath: IndexPath) -> Bool {
        let element = self[indexPath]
        let previousElement = self.elementBefore(indexPath)
        let nextElement = self.elementAfter(indexPath)
        return element.historyID != previousElement?.historyID && element.historyID != nextElement?.historyID
    }
    
    /**
     Remove the last element
     */
    func removeLastElement() {
        guard sections.count > 0 else { return }
        self[sections.count - 1].elements.removeLast()
    }
    
    /// The IndexPath of the last element
    var lastElementIndexPath: IndexPath {
        guard sections.count > 0 else { return IndexPath(row:0, section: 0) }
        let row = lastSection?.elements.count ?? 0
        return IndexPath(row: row - 1, section: sections.count - 1)
    }
    
    /**
     Returns the first element of the sequence that satisfies the given predicate.
     
     - parameter predicate: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element is a match.
     - returns: The first element of the sequence that satisfies predicate, or nil if there is no element that satisfies predicate.
     */
    func firstElement(where predicate: (SVKBubbleDescription) -> Bool) -> SVKBubbleDescription? {
        var element: SVKBubbleDescription? = nil
        for section in sections {
            let description = section.elements.first { predicate($0) }
            if description != nil {
                element = description
                break
            }
        }
        return element
    }
    
    // the last element
    var lastElement: SVKBubbleDescription? {
        return sections.last?.lastElement
    }

    public func firstIndex(where predicate: (Element) -> Bool) -> Index? {
        if isEmpty {
            return nil
        }
        var indexPath = startIndex
        while indexPath != endIndex {
            if predicate(self[indexPath]) {
                return indexPath
            }
            indexPath = self.index(after: indexPath)
        }
        return nil
    }
    /**
     Returns the indexPaths of the elements grouped the given predicate
     
     - parameter indexPath: The indexPath from where the search should began
     - parameter predicate: The predicate closure use to filter the elements
     - returns: The indexPaths of the elements grouped the given predicate
     */
    func indexPathOfElements(from indexPath: IndexPath, groupedBy predicate: (Element)->Bool) -> [IndexPath] {
        
        var indexPaths = [indexPath]
        var index = indexPath
        
        while let previousIndexPath = self.indexPath(before: index) {
            let element = self[previousIndexPath]
            if predicate(element) {
                indexPaths.insert(previousIndexPath, at: 0)
                index = previousIndexPath
            } else {
                break
            }
        }

        index = indexPath
        while let nextIndexPath = self.indexPath(after: index) {
            let element = self[nextIndexPath]
            if predicate(element) {
                indexPaths.append(nextIndexPath)
                index = nextIndexPath
            } else {
                break
            }
        }

        return indexPaths
    }
}

// MARK: Indexing
extension SVKConversationDescription {
    /**
     Returns the indexPath wich is placed before indexPath
     
     - parameter indexPath: The starting indexPath
     - returns: Returns the previous indexPath or nil
     */
    func indexPath(before indexPath: IndexPath) -> IndexPath? {
        guard isBounded(indexPath: indexPath) || indexPath == endIndex else { return nil }
        if indexPath.row - 1 >= 0 {
            return indexPath.offsetedBy(-1, 0)
        }
        var indexPath = indexPath.offsetedBy(0, -1)
        guard indexPath.section >= 0 else { return nil }
        indexPath.row = sections[indexPath.section].elements.count - 1
        guard isBounded(indexPath: indexPath) else { return nil }
        return indexPath
    }
    
    /**
     Returns the indexPath wich is placed after indexPath
     
     - parameter indexPath: The starting indexPath
     - returns: Returns the next indexPath or nil
     */
    func indexPath(after indexPath: IndexPath) -> IndexPath? {
        guard isBounded(indexPath: indexPath) else { return nil }
        let section = sections[indexPath.section]
        if indexPath.row + 1 < section.elements.count {
            return indexPath.offsetedBy(1, 0)
        }
        let indexPath = indexPath.offsetedBy(-indexPath.row, 1)
        guard isBounded(indexPath: indexPath) else { return nil }
        return indexPath
    }
}

/**
 An IteratorProtocol to iterate into SVKDataDescription
 
 The iterator is constraints to SVKBubbleDescription
 */
protocol SVKBubbleDescriptionIterator: IteratorProtocol where Element == SVKBubbleDescription {
    var index: IndexPath { get set }
}

extension SVKConversationDescription: SVKBubbleDescriptionIterator {
    
    mutating func next() -> SVKBubbleDescription? {
        var element: SVKBubbleDescription? = nil
        if index.section < sections.count && index.row < sections[index.section].elements.count {
            element = self[index]
            index.row += 1
        } else if index.section + 1 < sections.count {
            index.section += 1
            index.row = 0
            element = self[index]
        }
        return element
    }
    
    func makeIterator() -> SVKConversationDescription {
        return self
    }
}

/**
 Defines SVKDataDescription as a MutableCollection
 */
extension SVKConversationDescription: MutableCollection {
    
    var startIndex : IndexPath {
        return IndexPath(row: 0, section: 0)
    }
    var endIndex : IndexPath {
        if (sections.count == 0) {
            return IndexPath(row:0, section: 0)
        }
        return IndexPath(row: sections[sections.count - 1].elements.count, section: sections.count - 1)
    }
    
    func index(after i: IndexPath) -> IndexPath {
        if (i.row + 1 < sections[i.section].elements.count ) {
            return IndexPath(row: i.row + 1, section: i.section)
        } else if i.section + 1 < sections.count {
            return IndexPath(row: 0, section: i.section + 1)
        }
        return endIndex
    }
    
    /**
     Returns the element wich is placed at indexPath
     
     - parameter indexPath: The indexPath of the element that should be retreive
     - returns: Returns the element at indexPath or nil
     */
    subscript(position: IndexPath) -> SVKBubbleDescription {
        get {
            return sections[position.section][position.row]
        }
        set(newElement) {
            sections[position.section][position.row] = newElement
        }
    }
    
    /**
     Returns a sequence of pairs (n, x), where n represents a consecutive IndexPath starting at row(0)/section(0)
     and x represents an element of the sequence.
     - returns: A sequence of pairs enumerating the sequence.
     */
    func enumerated() -> Zip2Sequence<[IndexPath], [SVKBubbleDescription]> {
        var indexPaths = [IndexPath]()
        var values = [SVKBubbleDescription]()
        for (s, section) in sections.enumerated() {
            for (r, element) in section.elements.enumerated() {
                indexPaths.append(IndexPath(row: r, section: s))
                values.append(element)
            }
        }
        return zip(indexPaths, values)
    }
    
}

//MARK: RangeReplaceableCollection for sections
extension SVKConversationDescription {
    
    mutating func append<T>(_ newElement: T) where T: SVKSectionDescription {
        sections.append(newElement)
    }
    
    mutating func insert<T>(_ newElement: T, at i: Int) where T: SVKSectionDescription {
        sections.insert(newElement, at: i)
    }

    mutating func removeSection(at position: Int) {
        sections.remove(at: position)
    }
    mutating func removeAllSections() {
        sections.removeAll()
    }
    
    mutating func removeLastSection() {
        sections.removeLast()
    }

    mutating func removeLastSection(k: Int) {
        sections.removeLast(k)
    }
    
    var lastSection: SVKSectionDescription? {
        return sections.last
    }
    /**
     Remove elements specified be their indexPath
     
     - parameter indexPaths: The indexPaths of the elements to remove
     */
    mutating func remove(at indexPaths: [IndexPath]) {
        indexPaths.sorted { return $0.section == $1.section ? $0.row > $1.row : $0.section > $1.section}
            .forEach { (indexPath) in
                let section = self[indexPath.section]
                section.elements.remove(at: indexPath.row) }
    }
}

/**
 A section of SVKDataDescription
 
 A section contains elements. Each element is a SVKBubbleDescription
 */
class SVKSectionDescription {
    
    /// The section title in edit mode
    var title: String = ""
    
    /// The timestamp
    var timestamp: Date
    
    /// The elements that te section contains
    var elements: [SVKBubbleDescription] = []
    
    /// True if the section is selected
    var isSelected = false
    
    init(timestamp: String) {
        self.title = timestamp
        self.timestamp = SVKTools.date(from: timestamp) ?? Date()
    }
    /**
     Returns the element at index index
     
     - parameter position: The index of the element to get
     - returns: Returns the element at index index or nil if index is out of bounds
     */
    subscript(position: Int) -> SVKBubbleDescription {
        get {
            return elements[position]
        }
        set(newElement) {
            elements[position] = newElement
        }
    }
    
    /**
     Determines whenever the element at index is the last of the section
     - returns: true if it's the last element false otherwise
     */
    func isLastElement(at index: Int) -> Bool {
        return (elements.count - 1) == index
    }
    
    /// The last element of the section
    var lastElement: SVKBubbleDescription? {
        return elements.last
    }
    
    /// Returns true if the section is empty
    var isEmpty: Bool {
        return elements.isEmpty
    }
}

extension IndexPath {
    /**
     Returns a new IndexPath offseted by row and section
     - parameter dr: The offset to apply to row
     - parameter ds: The offset to apply to section
    */
    func offsetedBy(_ dr: Int, _ ds: Int) -> IndexPath {
        return IndexPath(row: row + dr, section: section + ds)
    }
}

extension SVKSectionDescription {
    /**
     Returns true if the section should contains the SVKBubbleDescription
     - parameter bubbleDescription: SVKBubbleDescription
     - returns: true if the bubble description timestamp's day is the same than the section timestamp's day, false otherwise
     */
    func shouldContains(bubbleDescription: SVKBubbleDescription) -> Bool {
        let date = SVKTools.date(from: bubbleDescription.timestamp)
        return timestamp.inSameDayAs(date)
    }
}

