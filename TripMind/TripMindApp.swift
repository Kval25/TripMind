//
//  TripMindApp.swift
//  TripMind
//
//  Created by REAL  on 24/03/26.
//

import SwiftUI

@main
struct TripMindApp: App {
    let persistence = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.managedObjectContext,persistence.context
                )
        }
    }
}
