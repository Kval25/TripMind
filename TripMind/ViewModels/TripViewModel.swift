//
//  TripViewModel.swift
//  TripMind
//
//  Created by REAL  on 24/03/26.
//

import Foundation
import Combine
import SwiftUI

class TripViewModel: ObservableObject {
    
    @Published var trips: [Trip] = []
    @Published var newTrip = Trip()
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var newItemName: String = ""
    
    var tripDuration: Int {
        Calendar.current.dateComponents([.day], from: newTrip.startDate, to: newTrip.endDate).day ?? 0
    }
    
    // Called when user changes trip type
    // so packing list update automatically
    func updatePackingList(){
        newTrip.packingList = newTrip.tripType.suggestedItems
    }
    
    //Toggle item packed/unpacked (we click->get index->update status)
    func toggleItem(_ item: PackingItem, in trip: inout Trip){
        if let index = trip.packingList.firstIndex(where: { $0.id == item.id}){
            trip.packingList[index].isPacked.toggle()
        }
    }
    
    // Add custom item to packing list
    func addCustomItem(to trip: inout Trip){
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        trip.packingList.append(PackingItem(name: trimmed))
        newItemName = ""
        }
    
    // Delete item from packing list
    func deleteItem(at offsets: IndexSet, from trip: inout Trip){
        trip.packingList.remove(atOffsets: offsets)
    }
    
    //Progress of packing
    func packingProgress(for trip: Trip) -> Double {
        guard !trip.packingList.isEmpty else {return 0}
        let packed = trip.packingList.filter({ $0.isPacked }).count
        return Double(packed) / Double(trip.packingList.count)
        
    }
   
    func saveTrip() -> Bool {
        // validate trip name.
        guard !newTrip.name.trimmingCharacters(in: .whitespaces).isEmpty else{
            errorMessage = "Please enter the trip name"
            showError = true
            return false
        }
        // validate destination
        guard !newTrip.destination.trimmingCharacters(in: .whitespaces).isEmpty else{
            errorMessage = " Please Enter the destination"
            showError = true
            return false
        }
        // validate dates
        guard newTrip.endDate > newTrip.startDate  else{
            errorMessage = "End Date must be after start date"
            showError = true
            return false
            
        }
        trips.append(newTrip)
        newTrip = Trip()
        return true
    }
    
}
