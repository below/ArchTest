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

import UIKit
import Kingfisher

private let SVKScreenSize = UIScreen.main.bounds.size
private let SVKScreenRatio = SVKScreenSize.width / 375

/**
 A enum representing the media layout
 */
public enum SVKMediaLayout: String {
    case horizontal
    case vertical
    case square
    
    init(string: String?) {
        if let string = string,
            let layout = SVKMediaLayout(rawValue: string) {
            self = layout
        }
        self = . square
    }
    
    init(ratio: CGFloat) {
        if ratio >= 1.50 {
            self = .horizontal
        } else if ratio <= 0.9 {
            self = .vertical
        } else {
            self = .square
        }
    }
    
    var size: CGSize {
        switch self {
        case .horizontal:
            return CGSize(width: CGFloat(270 * SVKScreenRatio), height: CGFloat(152 * SVKScreenRatio))
        case .vertical:
            return CGSize(width: CGFloat(211 * SVKScreenRatio), height: CGFloat(376 * SVKScreenRatio))
        case .square:
            return CGSize(width: CGFloat(270 * SVKScreenRatio), height: CGFloat(211 * SVKScreenRatio))
        }
    }
}

open class SVKAssistantImageTableViewCell: SVKTableViewCell, SVKTableViewCellProtocol {

    @IBOutlet public var bubble: SVKImageBubble!
    @IBOutlet public var activityIndicator: UIActivityIndicatorView!
    
    /// the retreive image network task
    private var retreiveImageTask: DownloadTask?
    
    public func concreteBubble<T>() -> T? where T: SVKBubble {
        return bubble as? T
    }
    
    /**
     An enum to implement the state design pattern
     */
    private enum State {
        case initial
        case error(NSError?, URL?)
        case loading(URL,SVKMediaLayout)
        case loaded(UIImage)
    }
    
    /// The currently downloded image URL
    private var downloadURL: URL?

    open override func awakeFromNib() {
        super.awakeFromNib()
        self.bubble.foregroundColor = UIColor.defaultUserColor
        self.isTimestampHidden = true
        bubble.contentInset = .zero
        bubble.imageViewContentMode = .scaleAspectFill

        state = .initial
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        state = .initial
    }
    
    func setBubbleStyle(_ style: SVKBubbleStyle) {
        bubble.style = style
        
        switch style {
        case .bottom(.left):
            topSpaceConstant = 5
        case .middle(.left):
            topSpaceConstant = 5
            avatar.image = nil
        default: break
        }
    }
    /*
     Sets the image layout
     
     The function apply width and height constraints to the bubble
     */
    private func setImageLayout(_ layout: SVKMediaLayout) {
        bubble.constraints.filter{ $0.identifier != "keep" }.forEach { $0.isActive = false }
        NSLayoutConstraint.activate([bubble.widthAnchor.constraint(equalToConstant: layout.size.width),
                                     bubble.heightAnchor.constraint(equalToConstant: layout.size.height)])
        bubble.layoutSubviews()
        self.layoutIfNeeded()
        contentView.layoutIfNeeded()
    }
    
    /**
     The dynamic state applied to the cell
     This embrace the state design pattern
    */
    private var state: State = . initial {
        didSet {
            switch state {
            case .initial:
                setBubbleStyle(.default(.left))
                setImageLayout(.horizontal)
                activityIndicator.stopAnimating()
                retreiveImageTask?.cancel()
                
            case .loaded(let image):
                activityIndicator.stopAnimating()
                bubble.image = image
                bubble.imageViewContentMode = .scaleAspectFill
                
            case .loading(let imageURL, let layout):
                activityIndicator.startAnimating()
                setImageLayout(layout)
                bubble.image = SVKTools.imageWithName("imagePlaceHolder")
                bubble.imageViewContentMode = .center
                retrieveImage(at: imageURL)

            case .error(let error, let url):
                activityIndicator.stopAnimating()
                SVKLogger.warn("Error retrieving image at: \(String(describing: url)):\(String(describing: error))")
            }
        }
    }
    
    /**
     Retreive the image data at URL
     
     The function first check if the image is in the cache.
     If the image is not present in cache, the function gets the image at the specified URL
     - parametrer url: The URL where the image is stored
    */
    private func retrieveImage(at url: URL) {
        retreiveImageTask?.cancel()

        self.downloadURL = url
        ImageCache.default.retrieveImageInDiskCache(forKey: url.absoluteString, options: [.preloadAllAnimationData]) { (result) in
            if case .success(let image) = result, let unwrappedImage = image {
                self.state = .loaded(unwrappedImage)
            } else {
                self.retreiveImageTask = KingfisherManager.shared.retrieveImage(with: url,
                                                                           options: [.keepCurrentImageWhileLoading, .preloadAllAnimationData],
                                                                           progressBlock: nil) {
                    (result) in
                    
                    switch result {
                    case .success(let imageResult):
                        if self.downloadURL == imageResult.source.url {
                            self.state = .loaded(imageResult.image)
                        }
                    case .failure(let error as NSError):
                        self.state = .error(error, self.downloadURL)
                    }
                }
            }
        }
    }

    
    /**
     Cancel the current download task.
     
     Calling this function may increase system performance,
     save battery life and network consumption
     */
    public func cancelDownloadTask() {
        // the intial state will cancel the download task
        state = .initial
    }
    
    override func fill<T>(with content: T) {
        guard case State.initial = self.state else {
            return
        }
        super.fill(with: content)
        
        guard let bubbleDescription = content as? SVKAssistantBubbleDescription,
            let text = bubbleDescription.text,
            let url = URL(string: text) else {
                return
        }
        super.layoutAvatar(for: bubbleDescription)

        setBubbleStyle(bubbleDescription.bubbleStyle)
        isTimestampHidden = bubbleDescription.isTimestampHidden
        state = .loading(url, bubbleDescription.mediaLayout)
    }
}
