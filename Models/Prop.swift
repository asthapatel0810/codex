//
//  Prop.swift
//  NightmareMonster
//
//  Created by Bénédicte Knudson on 9/14/25.
//

import SwiftUI

enum Prop: String, Codable, Hashable, CaseIterable, Identifiable {
    case coatOnChair, boxStack, lamp, hanger, backpack, customImage
    var id: String { rawValue }
}
