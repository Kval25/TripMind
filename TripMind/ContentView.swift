//
//  ContentView.swift
//  TripMind
//
//  Created by REAL  on 24/03/26.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TripViewModel()
    @State private var showCreateTrip = false

    var body: some View {
        NavigationStack{
            Group{
                if viewModel.trips.isEmpty{
                    emptyState
                }else{
                    tripList
                }
            }.navigationTitle("TripPlan ✈️")
                .toolbar{
                    ToolbarItem(placement: .primaryAction){
                        Button{
                            showCreateTrip = true
                        }label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }.fullScreenCover(isPresented: $showCreateTrip){
                        CreateTripView(viewModel: viewModel)
                }
        }
    }
    //MARK: - Empty State
    private var emptyState: some View{
        VStack{
            Text("🗺️")
                .font(.system(size: 64))
            Text("No trips yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap + to plan your first adventure")
                .foregroundColor(.secondary)
            Button("Plan a Trip"){
                showCreateTrip = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top,8)
            
        }
    }
    //MARK: - Trip List
    private var tripList: some View{
        List(viewModel.trips){ trip in
            VStack(alignment: .leading, spacing: 6){
                HStack{
                    Text(trip.name)
                        .font(.headline)
                    Spacer()
                    Text(trip.tripType.rawValue)
                        .font(.caption)
                        .padding(.horizontal,8)
                        .padding(.vertical,4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                Text("📍 \(trip.destination)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("🗓 \(trip.startDate.formatted(date: .abbreviated, time: .omitted)) → \(trip.endDate.formatted(date: .abbreviated, time: .omitted))").font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical,4)
        }
    }
}

#Preview {
    ContentView()
}
