//
//  MonsterFactory.swift
//  NightmareMonster
//
//  Created by Bénédicte Knudson on 9/22/25.
//

import SceneKit
//import UIKit

enum MonsterFactory {
    static func fromShadow(scene: SCNScene) -> SCNNode {
        // TODO: replace with real shadow extraction
        let monster = SCNNode(geometry: SCNSphere(radius: 1.0))
        monster.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
        monster.name = "monster"
        return monster
    }
}
