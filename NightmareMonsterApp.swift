//
//  NightmareMonsterApp.swift
//  NightmareMonster
//
//  Created by Astha  Patel on 9/5/25.
//

import SwiftUI

@main
struct NightmareMonsterApp: App {
    @StateObject private var store = Store()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GalleryPage()
            }
            .environmentObject(store)
        }
    }
}
