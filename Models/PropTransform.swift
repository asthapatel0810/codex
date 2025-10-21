//
//  PropTransform.swift
//  NightmareMonster
//
//  Created by Bénédicte Knudson on 9/14/25.
//

import SwiftUI

struct PropTransform: Codable, Hashable, Identifiable {
    var id: Prop
    var position: CGPoint
    var rotationDegrees: Double
    var scale: CGFloat
    var imageName: String? = nil
    var imagePath: String? = nil
    
    var rotation: Angle {
        get {.degrees(rotationDegrees)}
        set { rotationDegrees = newValue.degrees }
    }
    
    var identity: Bool { position == .zero && rotationDegrees == 0 && scale == 1}
}
