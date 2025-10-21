//
//  Store.swift
//  NightmareMonster
//
//  Created by Bénédicte Knudson on 9/14/25.
//

import SwiftUI

class Store: ObservableObject {
    @Published var captures: [Capture] = [] {
        didSet { saveCaptures() }
    }
    
    private let capturesFile = "captures.json"
    
    init() {
        loadCaptures()
    }
    
    // MARK: - paths
    private func capturesURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(capturesFile)
    }
    
    // MARK: - save / load
    private func saveCaptures() {
        do {
            let data = try JSONEncoder().encode(captures)
            try data.write(to: capturesURL())
        } catch {
            print("failed to save captures: \(error)")
        }
    }
    
    private func loadCaptures() {
        do {
            let data = try Data(contentsOf: capturesURL())
            captures = try JSONDecoder().decode([Capture].self, from: data)
        } catch {
            captures = []
        }
    }
    
    // MARK: - add capture
    func addCapture(image: UIImage) {
        guard let data = image.pngData() else { return }
        
        let filename = UUID().uuidString + ".png"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(filename)
        
        do {
            try data.write(to: path)
            let capture = Capture(compositePNGPath: path.path)
            captures.insert(capture, at: 0)
        } catch {
            print("failed to save image: \(error)")
        }
    }
}

struct Capture: Identifiable, Codable, Hashable {
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
}

