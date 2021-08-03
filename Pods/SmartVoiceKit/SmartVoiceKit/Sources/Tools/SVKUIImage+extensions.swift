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

extension UIImage {
    
    class func animationImagesWithSource(_ source: CGImageSource) -> [UIImage] {
        
        var images = [UIImage]()
        
        for i in 0..<CGImageSourceGetCount(source) {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        return images
    }
    
    class func animationImages(named name: String, bundle: Bundle = Bundle.main, withExtension ext: String) -> [UIImage]? {
        guard let bundleURL = bundle.url(forResource: name, withExtension: ext) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: bundleURL) else {
            return nil
        }
        
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        return UIImage.animationImagesWithSource(source)
    }
    
    func withColor(_ color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()
        
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)
        
        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        
        let size = self.size
        let aspectRatio =  size.width/size.height
        
        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 {                            // Landscape image
                width = dimension
                height = dimension / aspectRatio
            } else {                                        // Portrait image
                height = dimension
                width = dimension * aspectRatio
            }
            
        default:
            fatalError("UIImage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }
        
        let renderFormat = UIGraphicsImageRendererFormat.default()
        renderFormat.opaque = opaque
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
        newImage = renderer.image {
            (context) in
            self.dynamicAsset?.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        
        return newImage
    }

    var dynamicAsset: UIImage? {
        if #available(iOS 13.0, *) {
            return self.imageAsset?.image(with: .current)
        } else {
            return self
        }
    }
}

extension UIImageView {
    
func setImage(with url: URL, placeholder: UIImage? = nil, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {

        var options: KingfisherOptionsInfo? = nil
        let imageURL = convert(url: url)
        
        if let token = SVKAPIClient.shared.token(matching: imageURL) {
            let modifier = AnyModifier { request in
                var r = request
                r.setValue(" Bearer \(token)", forHTTPHeaderField: "Authorization")
                r.setValue(SVKUserIdentificationManager.shared.uniqueID, forHTTPHeaderField: "X-Touchpoint-Id")
                return r
            }
            options = [.requestModifier(modifier)]
        }

        kf.indicatorType = .activity
        kf.setImage(with: imageURL, placeholder: placeholder, options: options, progressBlock: nil) { [weak self] (result) in
            if case .failure(let error as NSError) = result,
            [1002, 2001, 2002].contains(error.code) {
                // 1002 "Invalid url"
                // 2001 "Invalid url response"
                // 2002 "Invalid HTTP status code"
                //so we should re-try with .light image

                if let isInDarkMode = self?.isInDarkMode, isInDarkMode {
                    let retryUrl = self?.convert(url: url, for: true)
                    self?.kf.setImage(with: retryUrl, placeholder: placeholder, options: options, completionHandler: completionHandler)
                } else {
                    completionHandler?(result)
                }
            } else {
                completionHandler?(result)
            }
        }
    }

    private var isInDarkMode: Bool {
        if #available(iOS 13.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return true
            case .light, .unspecified:
                return false
            @unknown default:
                fatalError("this case for userinterfaceStyle was unknow in iOS13, please update the code")
            }
        } else {
            return false // for iOS < 13
        }
    }

    /**
     Converts given url into translated url stored on the CDN.
     The method applies current user interface (**.dark, .light** ) style to the convertion.
     - Parameters:
     - url: The *URL* to modify.
     - retry: The *Bool* value set by default to **false**. Used in the callback when an error occurred.
     If the image was not found on CDN for the previous  iteration, we'll try to generate another URL.
     Usually it's the case for the dark mode image.
     The list of dark mode images are incomplete.
     - Returns: A new url.
     */
    
    private func convert(url: URL, for retry: Bool = false) -> URL {
        let items = URLQueryItem(name: "size",
                                 value: "\(Int(self.bounds.width * UIScreen.main.scale))")
        if retry {
            // if image was not found for composed url for given mode
            // we should retry with .light image for dark mode
            return url.translateByAppending(queryItems: [items])
        }
        return isInDarkMode ? url.darkened.translateByAppending(queryItems: [items]) : url.translateByAppending(queryItems: [items])
    }
}


// Fix white color for swippe image
// https://stackoverflow.com/questions/46398910/ios11-uicontextualaction-place-the-image-color-text
class SVKImageWithoutRender: UIImage {
    override func withRenderingMode(_ renderingMode: UIImage.RenderingMode) -> UIImage {
        return self
    }
}
