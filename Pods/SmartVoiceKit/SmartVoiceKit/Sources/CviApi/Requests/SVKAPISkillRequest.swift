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

public struct SVKAPISkillCatalogRequest: SVKAPIRequestProtocol {

    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKSkillsCatalog
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET

    // The logger use this identity
    typealias Identity = SVKAPISkillCatalogRequest

    var absoluteQueryString: String {
        return SVKAPIClient.baseURL + "/cvi/skill-catalog/api/v1/skill"
    }

    public init() {}

    /**
     Fetch the Skill catalog and return the skill skins
     - parameter completionHandler: A completion handler called with the result. The result is a dictionary of type [SkillIdentifier:SVKConversationHistory]
     */
    public func fetchSkillSkins(completionHandler: @escaping (SVKSkillSkins?) -> Void) {
        perform { result in
            switch result {
            case .success(_, let result as SVKSkillsCatalog):
                let dictionary: SVKSkillSkins = result.skillCatalog.reduce(into: [:], { dictionary, skillCatalog in
                    dictionary[skillCatalog.skillId] = skillCatalog
                })
                completionHandler(dictionary)
            default:
                SVKLogger.warn("Fail to retreive user skills")
                completionHandler(nil)
            }
        }
    }
}

public struct SVKAPISkillCategoryRequest: SVKAPIRequestProtocol {

    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKSkillCategories
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET

    // The logger use this identity
    typealias Identity = SVKAPISkillCategoryRequest

    var absoluteQueryString: String {
        return SVKAPIClient.baseURL + "/cvi/skill-catalog/api/v1/category"
    }

    public init() {}
}

public struct SVKAPIUserSkillRequest: SVKAPIRequestProtocol {

    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKUserSkills
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET

    // The logger use this identity
    typealias Identity = SVKAPIUserSkillRequest

    var absoluteQueryString: String {
        return SVKAPIClient.baseURL + "/cvi/skillregistry/api/v1/skill/user"
    }

    public init() {}
}
