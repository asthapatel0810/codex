//
//  Capture.swift
//  NightmareMonster
//
//  Created by Bénédicte Knudson on 9/15/25.
//
import Foundation

/* struct Capture: Identifiable, Codable, Hashable {
    let id = UUID()
    //let createdAt: Date
    let compositePNGPath: String
    
    /* init(id: UUID = UUID(), createdAt: Date = .now, compositePNGPath: String) {
        self.id = id
        self.createdAt = createdAt
        self.compositePNGPath = compositePNGPath
    } */
    
    var image: UIImage? {
        UIImage(contentsOfFile: compositePNGPath)
    }
} */

