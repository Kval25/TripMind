import SwiftUI

struct PackingListView: View {
    
    @ObservedObject var viewModel : TripViewModel
    
    var tripIndex: Int
    
    var trip: Trip{
        viewModel.trips[tripIndex]
    }
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 0){
                
                //progress header
                progressHeader
                
                //Packing List
                List{
                    // Items section
                    Section{
                        ForEach(viewModel.trips[tripIndex].packingList){ item in
                            PackingItemRow(item: item){
                                viewModel.toggleItem(item, in: &viewModel.trips[tripIndex])
                            }
                        }.onDelete{ offsets in
                            viewModel.deleteItem(at: offsets, from: &viewModel.trips[tripIndex])}
                     }
                    header:{
                        Text("Items (\(trip.packingList.filter { $0.isPacked}.count)/\(trip.packingList.count) packed)")
                            .font(.subheadline)
                    }
                    // Add custom item section
                    Section{
                        addItemRow
                    }header:{
                        Text("Add Custom Item")
                            .font(.subheadline)
                    }
                    
                }
                
            }.navigationTitle("\(trip.name) 🧳")
                .navigationBarTitleDisplayMode(.inline)
            
        }
    }
    
    
    
    //MARK: - Progress Header
    private var progressHeader: some View{
        VStack(spacing: 12){
            GeometryReader { geometry in
                ZStack(alignment: .leading){
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(colors: [.blue,.cyan], startPoint: .leading, endPoint: .trailing)
                        )
                                           //It creates a dynamic progress bar width
                                           // Width changes based on how much packing is done
                                           .frame(width: geometry.size.width * viewModel.packingProgress(for: trip),height: 12)
                                            .animation(.spring(), value: viewModel.packingProgress(for: trip))
                }
            }
            .frame(height: 12)
            // Progress text
            HStack{
                Text(progressMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(viewModel.packingProgress(for: trip) * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    //MARK: - Progress Message
    private var progressMessage: String{
        let progress = viewModel.packingProgress(for: trip)
        switch progress {
        case 0:
            return "Let's start packing! 💪"
            
        case 0..<0.5:
            return "Good start, keep going! 🚀"
        case 0.5..<1.0:
            return "Almost there! 🎯"
        default:
            return "All packed, let's go! ✈️"
        }
    }
    //MARK: - Add Item Row
    private var addItemRow: some View{
        HStack{
            TextField("e.g. Travel pillow",text: $viewModel.newItemName)
            
            Button {
                viewModel.addCustomItem(to: &viewModel.trips[tripIndex])
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
        }
    }
    
    // MARK: - Packing ITem Row
    struct PackingItemRow: View {
        let item: PackingItem
        let onToggle: () -> Void
        var body: some View {
            HStack{
                //Checkbox
                Button(action: onToggle){
                    Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(item.isPacked ? .blue : .gray)
                        .animation(.spring(response: 0.3),value: item.isPacked)
                }
                .buttonStyle(.plain)
                
                //Item name
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isPacked,color: .secondary)
                    .foregroundColor(item.isPacked ? .secondary : .primary)
                    .animation(.easeInOut,value: item.isPacked)
                
                Spacer()
            }
            .padding(.vertical, 4)
            
        }
    }
    
    
}


#Preview {
    let viewModel = TripViewModel()
    
    viewModel.trips = [
        Trip(
            name: "Goa Trip",
            destination: "Goa, India",
            tripType: .beach
        )
    ]
    
    return PackingListView(viewModel: viewModel, tripIndex: 0)
}
