//
//  ConvexChatAppApp.swift
//  ConvexChatApp
//
//  Created by Mathieu Tricoire on 2023-04-03.
//

import Convex
import SwiftUI

 let path = Bundle.main.path(forResource: "Secret", ofType: "plist")!
 let secret = NSDictionary(contentsOfFile: path)!
 let CONVEX_URL = secret["CONVEX_URL"] as! String

extension ConvexQueries {
    var getMessagesLive: ConvexQueryDescription {
        ConvexQueryDescription(path: "myFunctions:getMessagesLive")
    }
}

@main
@MainActor
struct ConvexChatAppApp: App {
    private var client = Client(deploymentUrl: CONVEX_URL)
    @StateObject var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            MessagesView()
                .convexClient(client)
                .environmentObject(locationManager)
                .task {
                    await client.connect()
                }
                .onAppear() {
                    locationManager.manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "sdfd")

                }

        }
    }
}
