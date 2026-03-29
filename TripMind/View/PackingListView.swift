import SwiftUI

struct PackingListView: View {
    
    @ObservedObject var viewModel : TripViewModel
    
    var tripIndex: Int
    @State private var showAISheet = false
    @State private var aiPrompt = ""
    @State private var isLoadingAI = false
    @State private var aiError = ""
    
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
                .toolbar {
                    ToolbarItem(placement: .primaryAction){
                        Button {
                            showAISheet = true
                            
                        } label: {
                            HStack(spacing: 4){
                                Image(systemName: "sparkles")
                                Text("AI")
                            }
                            .foregroundColor(.purple)
                        }
                    }
                }.sheet(isPresented: $showAISheet){
                    aiSheet
                }
            
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
    
    //MARK: - AI Sheet
    private var aiSheet: some View{
        NavigationStack{
            VStack(spacing: 20){
                //Header
                VStack(spacing: 8){
                    Text("🤖")
                        .font(.system(size: 52))
                    Text("AI Packing Assistant")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Describe your trip and AI will suggest what to pack")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                }.padding(.top,20)
                
                //Text input
                VStack(alignment: .leading, spacing: 8){
                    Label("Describe your trip", systemImage: "text.bubble.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, y:2)
                        
                        if aiPrompt.isEmpty {
                            Text("e.g. Going to Manali in December for a 5 day trek...")
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(16)
                        }
                        TextEditor(text: $aiPrompt)
                            .frame(minHeight: 100)
                            .padding(12)
                            .scrollContentBackground(.hidden)
                    }
                    .frame(minHeight: 120)
                }
                .padding(.horizontal)
                
                //Suggest button
                Button{
                    Task{ await fetchAISuggestions()}
                }label: {
                    HStack{
                        if isLoadingAI {
                            ProgressView().tint(.white)
                            Text("Thinking...").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: aiPrompt.isEmpty ? [.gray] : [.purple,.blue], startPoint: .leading, endPoint: .trailing)
                    ).foregroundColor(.white)
                        .cornerRadius(16)
                }.disabled(aiPrompt.isEmpty || isLoadingAI)
                    .padding(.horizontal)
                
                if !aiError.isEmpty {
                    Text(aiError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                Spacer()
                
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AI Suggestions ✨")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction){
                    Button("Cancel"){ showAISheet = false}
                }
            }
        }
    }
    
    //MARK: - Fetch AI Suggestions
    private func fetchAISuggestions() async {
        isLoadingAI = true
        aiError = ""
        
        do{
            let items = try await AIPackingService.shared.suggestPackingItems(for: aiPrompt)
            await MainActor.run {
                for itemName in items {
                    let existingNames = viewModel.trips[tripIndex].packingList
                        .map { $0.name.lowercased() }

                    for itemName in items {
                        // Only add if not already in the list
                        if !existingNames.contains(itemName.lowercased()) {
                            let newItem = PackingItem(name: itemName)
                            viewModel.trips[tripIndex].packingList.append(newItem)
                        }
                    }
                }
                viewModel.savePackingItems(for: tripIndex)
                isLoadingAI = false
                showAISheet = false
            }
        }catch {
            await MainActor.run {
                aiError = "Something went wrong. Check your API key or internet"
                isLoadingAI = false
            }
        }
        
    }
}



#Preview {
    let context = PersistenceController.shared.context
    let vm = TripViewModel(context: context)

    // Add dummy trip so preview doesn't crash
    vm.trips = [
        Trip(
            name: "Goa Trip",
            destination: "Goa"
        )
    ]

    return PackingListView(
        viewModel: vm,
        tripIndex: 0
    )
}

