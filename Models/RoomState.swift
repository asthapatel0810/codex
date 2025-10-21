//
//  RoomState.swift
//  NightmareMonster
//
//  Created by Bénédicte Knudson on 9/14/25.
//

import SwiftUI

struct RoomState: Codable, Hashable {
    var props: [Prop] = [.coatOnChair, .boxStack, .lamp]
    var propTransforms: [PropTransform] = []
    var light: LightModel = .init(position: .init(x: 70, y:140))
}
