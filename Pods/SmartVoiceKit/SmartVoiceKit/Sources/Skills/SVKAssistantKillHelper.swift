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

struct SVKAssistantSkillHelper {
    fileprivate static func makeSkill(with kit: SVKSkillKit) -> SVKAssistantSkill? {
        switch kit.type {
        case .deezer:
            return SVKDeezerSkill(kit: kit)
        case .audioPlayer:
            return SVKMusicPlayerSkill(kit: kit)
        case .system:
            return SVKSystemSkill(kit: kit)
        default:
            return SVKGenericSkill(kit: kit)
        }
    }
    
    fileprivate static func makeSkill(with card: SVKCard) -> SVKAssistantSkill? {
        switch card.type {
        case .deezerUser, .deezerAlbum, .deezerArtist, .deezerTrack, .deezerPlaylist:
            return SVKDeezerSkill(card: card)
        case .generic:
            switch card.data?.layout {
            case .some(.mediaPlayer):
                return SVKGenericAudioPlayerSkill(card: card)
            default:
             return SVKGenericSkill(card: card)
            }
        default:
            return SVKGenericSkill(card: card)
        }
    }

    static func makeSkill(with kit: SVKSkillKit? = nil, card: SVKCard? = nil) -> SVKAssistantSkill? {
        if let kit = kit {
            return makeSkill(with: kit)
        } else if let card = card {
            return makeSkill(with: card)
        }
        return nil
    }
}
