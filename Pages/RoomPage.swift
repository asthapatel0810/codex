import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import Vision

// MARK: - model
struct PlacedItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var position: CGPoint
}

// MARK: - state
struct RoomPage: View {
    @State private var placedProps: [PlacedItem] = []
    @State private var placedLights: [PlacedItem] = []
    @State private var sceneView = RoomSceneView(placedProps: .constant([]), placedLights: .constant([]))
    @State private var showCustomizePage = false
    @State private var generatedMonster: SCNNode? = nil
    @State private var capturedSilhouette: UIImage?? = nil
    @State private var snapshotImage: UIImage?
    
    private let propNames = ["acoustic_guitar", "baseball_glove", "bonsai", "chair", "chameleon", "dog", "pancakes", "piggybank", "seahorse", "soccer_ball", "sweater", "xbox_controller"]
    private let lightNames = ["flashlight"]
 
    // MARK: - room page
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // left bank
                itemBank(title: "items", items: propNames)
                
                // room canvas
                ZStack {
                    RoomSceneView(placedProps: $placedProps,
                                  placedLights: $placedLights)
                }
                .frame(height: 400)
                
                // right bank
                itemBank(title: "Lights", items: lightNames)
            }
            .padding()
            
            // generate monster button
            Button("generate monster") {
                captureShadowAndGenerateMonster()
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        // show customizepage as a modal sheet
        .sheet(isPresented: $showCustomizePage) {
            if let monster = generatedMonster {
                
                CustomizePage(monsterNode: monster)
            }
        }
    }
    
    // MARK: - capture and generate
    private func captureShadowAndGenerateMonster() {
        // 1. snapshot wall
        guard let silhouetteImage = sceneView.snapshotSilhouette() else {
            print("failed to capture silhouette")
            return
        }
        
        // 2. create monster node, present customize page
        if let monsterNode = RoomSceneView.shared.createMonsterNode(from: silhouetteImage) {
            generatedMonster = monsterNode
            showCustomizePage = true
        } else {
            print("failed to generate monster node from silhouette")
        }
        
    }
    
    // MARK: - bank view
    private func itemBank(title: String, items: [String]) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        // Tap to add at center
                            .onTapGesture {
                                if title == "items" {
                                    placedProps.append(PlacedItem(name: name, position: CGPoint(x: 200, y: 200)))
                                } else {
                                    placedLights.append(PlacedItem(name: name, position: CGPoint(x: 200, y: 200)))
                                }
                            }
                        // Drag to add → handled by onDrop in room
                            .onDrag {
                                NSItemProvider(object: name as NSString)
                        }
                }
            }
            .padding(.horizontal)
            
            
            }
            .frame(width: 50, height: 300) // 5ish items at a time
        }
        .padding(.vertical)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
    
    
    // MARK: - placed item view
    private func draggablePlacedItem(item: PlacedItem, in geo: GeometryProxy, list: Binding<[PlacedItem]>) -> some View {
        Image(item.name)
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .position(item.position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if let index = list.wrappedValue.firstIndex(of: item) {
                            list.wrappedValue[index].position = value.location
                        }
                    }
                    .onEnded { value in
                        if let index = list.wrappedValue.firstIndex(of: item) {
                            // Remove if outside the room
                            if !geo.frame(in: .local).contains(value.location) {
                                list.wrappedValue.remove(at: index)
                            }
                        }
                    }
            )
    }
    
}


#Preview {
    RoomPage()
}
