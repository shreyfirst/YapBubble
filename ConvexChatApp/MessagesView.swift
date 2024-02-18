//
//  MessagesView.swift
//  ConvexChatApp
//
//  Created by Mathieu Tricoire on 2023-05-03.
//

import Convex
import SwiftUI
import CoreLocation
import CoreLocationUI

struct MessagesView: View {
    @Environment(\.convexClient) private var client
    @EnvironmentObject var locationManager: LocationManager
    private let timerInterval: TimeInterval = 1.0
    @State private var username = "HardcodedUsername"
    
    
    @State private var showingLocationModal = false
    @State private var currentLocation: CLLocation?
    
    
    @State private var lat: Double = 0.0
    @State private var long: Double = 0.0
    @ConvexQuery(\.getMessagesLive, args: ["lat": Value(floatLiteral: 0.0), "long": Value(floatLiteral: 0.0)]) private var messages
    
    private let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    func sendMessage(_ body: String) {
        Task {
            
            try? await client?.mutation(path: "myFunctions:sendMessage", args: ["display_name": Value(stringLiteral: username), "message": Value(stringLiteral: body), "lat": Value(floatLiteral: lat), "long": Value(floatLiteral: long)])
        }
    }
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if case let .array(messages) = messages {
//                    Button("Show Current Location") {
//                                    currentLocation = locationManager.locations?.last
//                                    showingLocationModal = true
//                                }
//                                .sheet(isPresented: $showingLocationModal) {
//                                    if let location = currentLocation {
//                                        // Displaying location details in a modal
//                                        Text("Current Location:\nLatitude: \(location.coordinate.latitude)\nLongitude: \(location.coordinate.longitude)")
//                                            .padding()
//                                    } else {
//                                        Text("No location data available")
//                                    }
//                                }
//                    LocationButton {
//                        locationManager.requestLocation()
//                        print(locationManager.locations)
//                    }
                    List {
                        ForEach(messages.reversed(), id: \.[dynamicMember: "_id"]) { message in
                            VStack(alignment: .leading) {
                                Text("**\(message.display_name?.description ?? "")**: \(message.message?.description ?? "")")
                                if case let .some(.float(creationTime)) = message._creationTime {
                                    Text(Date(timeIntervalSince1970: creationTime / 1000).description)
                                        .font(.caption)
                                        .foregroundColor(Color.gray)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .animation(.easeIn, value: messages)
                } else {
                    VStack {
                        Spacer()
                        Text("~ no messages ~")
                        Spacer()
                    }
                }
                
                CustomTextField { message in
                    sendMessage(message)
                }
                .background(.ultraThickMaterial)
            }
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                locationManager.requestLocation()
            }
            .onChange(of: locationManager.locations) { newLocations in
                if let location = newLocations?.last {
                    updateSubscription(with: location)
                }
            }
        }
    }
    func updateSubscription(with location: CLLocation) {
        let lat = location.coordinate.latitude
        let long = location.coordinate.longitude
        
        // Cancel previous subscription if necessary or manage subscriptions appropriately here
        
        Task {
            do {
                try await client?.subscribe(path: "myFunctions:getMessagesLive", args: ["lat": Value(floatLiteral: lat), "long": Value(floatLiteral: long)], resultHandler: { value in
                    print("Received value: \(value)")
                })
            } catch {
                print("Subscription failed with error: \(error)")
            }
        }
    }
}
struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}

// From: https://medium.com/@ckinetandrii/i-have-created-an-auto-resizing-textfield-using-swiftui-5839bb075a64
struct CustomTextField: View {
    @State var message: String = ""
    var action: (String) async -> Void
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 8) {
                withAnimation(.easeInOut) {
                    TextField("", text: $message, axis: .vertical)
                        .placeholder(when: message.isEmpty) {
                            Text("Message...")
                                .foregroundColor(.secondary)
                        }
                        .lineLimit(...7)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.background)
            .cornerRadius(10)
            
            Button {
                Task {
                    await action(message)
                    message = ""
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.largeTitle)
            }
            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines) == "")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 55)
        .animation(.easeInOut(duration: 0.3), value: message)
    }
}

extension View {
    func placeholder(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> some View
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    @MainActor
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}

