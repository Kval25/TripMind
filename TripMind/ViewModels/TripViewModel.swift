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
                // fetch packing items for each trip
                let itemEntities = (entity.packingItems as? Set<PackingItemEntity>) ?? []
                
                print("🧳 Loaded \(itemEntities.count) items for trip: \(entity.name ?? "")")
                
                let packingItems = itemEntities.map { itemEntity in
                    PackingItem (
                        id: itemEntity.id ?? UUID(),
                        name: itemEntity.name ?? "",
                        isPacked: itemEntity.isPacked
                    )
                    
                }.sorted{$0.name < $1.name}
                
               return Trip(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "",
                    destination: entity.destination ?? "",
                    startDate: entity.startDate ?? Date(),
                    endDate: entity.endDate ?? Date(),
                    tripType: TripType(rawValue: entity.tripType ?? "") ?? .city,
                    packingItems:  packingItems.isEmpty ? TripType(rawValue: entity.tripType ?? "")?.suggestedItems ?? [] : packingItems
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
        
        // Save trip entity
        let tripEntity = TripEntity(context: context)
        tripEntity.id = newTrip.id
        tripEntity.name = newTrip.name
        tripEntity.destination = newTrip.destination
        tripEntity.startDate = newTrip.startDate
        tripEntity.endDate = newTrip.endDate
        tripEntity.tripType = newTrip.tripType.rawValue
        
        // Save packing items
        for item in newTrip.packingList {
            let itemEntity = PackingItemEntity(context: context)
            itemEntity.id = item.id
            itemEntity.name = item.name
            itemEntity.isPacked = item.isPacked
            itemEntity.trip = tripEntity
        }
        
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
    
    // MARK: - Toggle item packed/unpacked (we click->get index->update status) and save to Coredata
    func toggleItem(_ item: PackingItem, in trip: inout Trip){
        
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id}) else {return}
        // Update in memory
        if let itemindex =  trips[tripIndex].packingList.firstIndex(where: { $0.id == item.id }){
            trips[tripIndex].packingList[itemindex].isPacked.toggle()
            trip = trips[tripIndex]
            
        }
        let itemRequest = NSFetchRequest<PackingItemEntity>(entityName: "PackingItemEntity")
        itemRequest.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        do{
            let results = try context.fetch(itemRequest)
            results.first?.isPacked.toggle()
            PersistenceController.shared.save()
        }catch{
            print("Toggle error: \(error)")
        }
        
    }
    
    
    //MARK: - Add custom item to packing list and save to CoreData
    func addCustomItem(to trip: inout Trip){
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newItem = PackingItem(name: trimmed)
        
        //Update in memory
        guard  let tripIndex = trips.firstIndex(where: { $0.id == trip.id}) else {return }
        trips[tripIndex].packingList.append(newItem)
        trip = trips[tripIndex]
        
        // Save to CoreData
        let tripRequest = NSFetchRequest<TripEntity>(entityName: "TripEntity")
        tripRequest.predicate = NSPredicate(format: "id == %@", trip.id as CVarArg)
        do{
            let tripEntities = try context.fetch(tripRequest)
            if let tripEntity = tripEntities.first{
                let itemEntity = PackingItemEntity(context: context)
                itemEntity.id = newItem.id
                itemEntity.name = newItem.name
                itemEntity.isPacked = false
                itemEntity.trip = tripEntity
                PersistenceController.shared.save()
            }
        }catch{
            print("Add item error : \(error)")
        }
        newItemName  = ""
        }
    
    //MARK: - Delete packing item
    func deleteItem(at offsets: IndexSet, from trip: inout Trip){
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id})else {return}
        
        for index in offsets {
            let itemToDelete = trips[tripIndex].packingList[index]
            
            //Delete from CoreData
            let request = NSFetchRequest<PackingItemEntity>(entityName: "PackingItemEntity")
            request.predicate = NSPredicate(format: "id == %@", itemToDelete.id as CVarArg)
            do{
                let results = try context.fetch(request)
                results.forEach{ context.delete($0)}
                PersistenceController.shared.save()
            }catch{
                print("Delete item error: \(error)")
            }
        }
        trips[tripIndex].packingList.remove(atOffsets: offsets)
        trip = trips[tripIndex]
    }
    
    
    
    //Progress of packing
    func packingProgress(for trip: Trip) -> Double {
        guard !trip.packingList.isEmpty else {return 0}
        let packed = trip.packingList.filter({ $0.isPacked }).count
        return Double(packed) / Double(trip.packingList.count)
        
    }

    
}
