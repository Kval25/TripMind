

import SwiftUI

struct CreateTripView: View {
    
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(spacing: 24){
                    
                    headerSection
                    
                    VStack(spacing: 16){
                        tripNameField
                        destination
                        dateSection
                        tripTypeSection
            
                    }.padding(.horizontal)
                
                    // Save Button
                    saveButton
                        .padding(.horizontal)
                        .padding(.bottom,32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .cancellationAction){
                    Button("Cancel"){ dismiss()}
                }
            }.alert("Oops!", isPresented: $viewModel.showError){
                Button("OK",role: .cancel){}
            }message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    
    //MARK: -Header
    private var headerSection: some View {
        ZStack{
            LinearGradient(colors: [.blue,.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 200)
                .ignoresSafeArea(edges: .top)
            VStack(spacing: 8){
                Text("✈️")
                    .font(.system(size: 52))
                Text("Where to next?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        
        
    }
    
    //MARK: - Trip Name
    private var tripNameField: some View {
        VStack(alignment: .leading,spacing: 8){
            Label("Trip Name", systemImage: "tag.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            TextField("e.g. Goa Trip 2025", text: $viewModel.newTrip.name)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4,y: 2)
            
        }
    }
    
    //MARK: - Destination
    private var destination: some View{
        VStack(alignment: .leading,spacing: 8){
            Label("Destination", systemImage: "mappin.circle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            TextField("e.g. Goa,India", text: $viewModel.newTrip.destination)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4,y:2)
        }
    }
    
    //MARK: - Dates
    private var dateSection: some View{
        VStack(alignment: .leading,spacing: 8){
            
            Label("Travel Dates",systemImage: "calendar")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 0){
                
                DatePicker("Start Date", selection: $viewModel.newTrip.startDate, displayedComponents: .date).padding()
                Divider().padding(.horizontal)
                
                DatePicker("End Date", selection: $viewModel.newTrip.endDate, displayedComponents: .date).padding()
                
            }.background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4,y:2)
            
            //Duration badge
            if viewModel.tripDuration > 0 {
                HStack{
                    Text("🗓 \(viewModel.tripDuration) days trip")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal,12)
                        .padding(.vertical,6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                }
            }
        }
        
    }
    
    
    //MARK: - Trip Type
    private var tripTypeSection: some View{
        VStack(alignment: .leading, spacing: 8){
            Label("Trip Type",systemImage: "car.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2),spacing: 12){
                ForEach(TripType.allCases){ type in
                    TripTypeCard(type: type, isSelected: viewModel.newTrip.tripType == type){
                        withAnimation(.spring(response: 0.3)){
                            viewModel.newTrip.tripType = type
                            viewModel.updatePackingList()
                        }
                    }
                    
                    
                }
            }
            
        }
    }
    
    //MARK: - Trip Type Card
    struct TripTypeCard: View {
        let type: TripType
        let isSelected: Bool
        let action: () -> Void
        var body: some View {
            Button(action: action){
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemBackground))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear,lineWidth: 2)).shadow(color: .black.opacity(isSelected ? 0 : 0.05), radius: 4, y: 2)
                
            }
        }
    }
    
    //MARK: - Save Button
    private var saveButton: some View{
        Button {
            if viewModel.saveTrip(){
                dismiss()
            }
            
        }label: {
            HStack{
                Image(systemName: "checkmark.circle.fill")
                Text("Save Trip")
                    .fontWeight(.semibold)
            }.frame(maxWidth: .infinity)
             .padding()
             .background(
                LinearGradient(colors: [.blue,.cyan], startPoint: .leading, endPoint: .trailing)
             )
             .foregroundColor(.white)
             .cornerRadius(16)
             .shadow(color: .blue.opacity(0.5),radius: 8, y: 4)
            
        }
        
    }
}


#Preview {
    CreateTripView(viewModel: TripViewModel(context: PersistenceController.shared.context))
}
