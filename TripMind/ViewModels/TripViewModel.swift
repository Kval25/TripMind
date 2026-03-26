//
//  TripViewModel.swift
//  TripMind
//
//  Created by REAL  on 24/03/26.
//

import Foundation
import Combine
import SwiftUI
import CoreData

class TripViewModel: ObservableObject {

    @Published var trips: [Trip] = []
    @Published var newTrip = Trip()
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var newItemName: String = ""
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext){
        self.context = context
        fetchTrips()
    }
    
    
    var tripDuration: Int {
        Calendar.current.dateComponents([.day], from: newTrip.startDate, to: newTrip.endDate).day ?? 0
    }
    
    //MARK: - Fetch all trips from CoreData
    func fetchTrips(){
        let request = NSFetchRequest<TripEntity>(entityName: "TripEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "startDate", ascending: true)
        ]
        do{
            let entities = try context.fetch(request)
            trips = entities.map{ entity in
                let itemEntities = (entity.packingItems as? Set<PackingItem>) ?? []
                Trip(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "",
                    destination: entity.destination ?? "",
                    startDate: entity.startDate ?? Date(),
                    endDate: entity.endDate ?? Date(),
                    tripType: TripType(rawValue: entity.tripType ?? "") ?? .city
                )
            }
        }catch{
            print("fetch error: \(error)")
        }
    }
    
    //MARK: - Save trips to coreData
    
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
        
        // Save to core data
        let entity = TripEntity(context: context)
        entity.id = newTrip.id
        entity.name = newTrip.name
        entity.destination = newTrip.destination
        entity.startDate = newTrip.startDate
        entity.endDate = newTrip.endDate
        entity.tripType = newTrip.tripType.rawValue
        
        PersistenceController.shared.save()
        fetchTrips()
        newTrip = Trip()
        return true
        
        
        
    }
    //MARK: - Delete trip from CoreData
    func deleteTrip(at offsets: IndexSet){
        let request = NSFetchRequest<TripEntity>(entityName: "TripEntity")
        do{
            let entities = try context.fetch(request)
            for index in offsets {
                let tripToDelete = trips[index]
                if let entity = entities.first(where: { $0.id == tripToDelete.id}){
                    context.delete(entity)
                }
            }
            PersistenceController.shared.save()
            fetchTrips()
        }
        catch{
            print("Delete error: \(error)")
        }
        
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

    
}
