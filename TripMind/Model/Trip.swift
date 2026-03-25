
import Foundation

enum TripType: String, CaseIterable, Identifiable {
    case beach = "🏖 Beach"
    case business = "💼 Business"
    case trek = "🏔 Trek"
    case city = "🏙 City"
    
    var id: String {self.rawValue}
    
        // Smart Packing suggestions per trip type
    var suggestedItems: [PackingItem] {
        switch self {
        case .beach:
            return [
                PackingItem(name: "Sunscreen"),
                PackingItem(name: "Swimsuit"),
                PackingItem(name: "Flip flops"),
                PackingItem(name: "Beach towel"),
                PackingItem(name: "Sunglasses"),
                PackingItem(name: "Water bottle"),
                PackingItem(name: "Hat"),
                PackingItem(name: "Snorkeling gear")
                
            ]
        case .business:
            return[
                PackingItem(name: "Laptop"),
                PackingItem(name: "Charger"),
                PackingItem(name: "Business cards"),
                PackingItem(name: "Formal clothes"),
                PackingItem(name: "Notebook"),
                PackingItem(name: "Pen"),
                PackingItem(name: "Formal shoes"),
                PackingItem(name: "Portfolio bag")
            ]
        case .city:
            return[
                PackingItem(name: "Hiking boots"),
                PackingItem(name: "Backpack"),
                PackingItem(name: "First aid kit"),
                PackingItem(name: "Torch / Headlamp"),
                PackingItem(name: "Rain jacket"),
                PackingItem(name: "Energy bars"),
                PackingItem(name: "Water bottle"),
                PackingItem(name: "Trekking poles")
            ]
        case .trek:
            return[
                PackingItem(name: "Camera"),
                PackingItem(name: "Metro card"),
                PackingItem(name: "Comfortable shoes"),
                PackingItem(name: "Power bank"),
                PackingItem(name: "Umbrella"),
                PackingItem(name: "City map / Guide"),
                PackingItem(name: "Casual clothes"),
                PackingItem(name: "Earphones")
            ]
        }
        
    }
    
}
// Packing Item Model
struct PackingItem: Identifiable{
    let id: UUID
    var name: String
    var isPacked: Bool
    
    init(id: UUID = UUID(), name: String, isPacked: Bool = false) {
        self.id = id
        self.name = name
        self.isPacked = isPacked
    }
}
struct Trip: Identifiable{
    let id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var tripType: TripType
    var packingList: [PackingItem]
    init(
        id: UUID = UUID(),
        name: String = "",
        destination: String = "",
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        tripType: TripType = .city
    ){
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.tripType = tripType
        self.packingList = tripType.suggestedItems
    }
}
