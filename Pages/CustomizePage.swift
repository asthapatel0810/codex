//
//  CustomizePage.swift
//  NightmareMonster
//
//  Created by Astha  Patel on 9/5/25.
//

import SwiftUI
import SceneKit

struct CustomizablePart: Identifiable {
    let id = UUID()
    let imageName: String
}

struct CustomizePage: View {
    // MARK: - inputs
    let monsterNode: SCNNode // passed from roompage
    // let silhouetteImage: UIImage 
    
    // MARK: - state
    @State private var selectedEyes: String?
    @State private var selectedMouth: String?
    @State private var selectedHorn: String?
    @State private var selectedSkin: String?
    
    @State private var eyesPosition: CGSize = .zero
    @State private var mouthPosition: CGSize = .zero
    @State private var hornPosition: CGSize = .zero
    
    @State private var inflation: CGFloat = 1.0
    @State private var openCategory: String?
    
    @EnvironmentObject var store: Store
    @State private var scnView = SCNView()
    
    @State private var scene = SCNScene()
    
    // MARK: - options
    let monsterBase = "monsterBase"
    let eyesOptions = [CustomizablePart(imageName: "eyes1"),
                       CustomizablePart(imageName: "eyes2"),
                       CustomizablePart(imageName: "eyes3"),
                       CustomizablePart(imageName: "eyes4"),
                       CustomizablePart(imageName: "eyes5"),
                       CustomizablePart(imageName: "eyes6"),
                       CustomizablePart(imageName: "eyes7"),
                       CustomizablePart(imageName: "eyes8"),
                       CustomizablePart(imageName: "eyes9")]
    let mouthOptions = [CustomizablePart(imageName: "mouth1"),
                        CustomizablePart(imageName: "mouth2"),
                        CustomizablePart(imageName: "mouth3"),
                        CustomizablePart(imageName: "mouth4"),
                        CustomizablePart(imageName: "mouth5"),
                        CustomizablePart(imageName: "mouth6"),
                        CustomizablePart(imageName: "mouth7"),
                        CustomizablePart(imageName: "mouth8"),
                        CustomizablePart(imageName: "mouth9"),
                        CustomizablePart(imageName: "mouth10"),
                        CustomizablePart(imageName: "mouth11"),
                        CustomizablePart(imageName: "mouth12"),
                        CustomizablePart(imageName: "mouth13"),
                        CustomizablePart(imageName: "mouth14"),
                        CustomizablePart(imageName: "mouth15")]
    let hornOptions = [CustomizablePart(imageName: "horn1"),
                       CustomizablePart(imageName: "horn2"),
                       CustomizablePart(imageName: "horn3"),
                       CustomizablePart(imageName: "horn4"),
                       CustomizablePart(imageName: "horn5"),
                       CustomizablePart(imageName: "horn6"),
                       CustomizablePart(imageName: "horn7"),
                       CustomizablePart(imageName: "horn8"),
                       CustomizablePart(imageName: "horn9")]
    let skinOptions = [CustomizablePart(imageName: "skin1"),
                       CustomizablePart(imageName: "skin2"),
                       CustomizablePart(imageName: "skin3")]
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Customize your Monster")
                    .font(.title2)
                
                Spacer()
                
                ZStack {
                    // MARK: - monster canvas
                    SceneView(
                        scene: scene,
                        options: [.allowsCameraControl, .autoenablesDefaultLighting]
                    )
                    .frame(height: 300)
                    
                    // MARK: - eyes overlay
                    if let eyes = selectedEyes {
                        Image(eyes)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .offset(eyesPosition)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in eyesPosition = value.translation }
                            )
                    }
                    
                    // MARK: - mouth overlay
                    if let mouth = selectedMouth {
                        Image(mouth)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .offset(mouthPosition)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in mouthPosition = value.translation }
                            )
                    }
                    
                    // MARK: - horn overlay
                    if let horn = selectedHorn {
                        Image(horn)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .offset(hornPosition)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in hornPosition = value.translation }
                            )
                    }
                    
                    // MARK: - skin overlay
                    if let skin = selectedSkin {
                        Image(skin)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                    }
                }
                .frame(height: 320)
                .padding()
                
                // MARK: - inflation slider
                Slider(value: $inflation, in: 1...20, step: 0.1) {
                    Text("extrusion depth")
                }
                .padding()
                .onChange(of: inflation) { _, newValue in
                    inflateMonster(by: newValue)
                }
                .onAppear {
                    if monsterNode.parent == nil {
                        scene.rootNode.addChildNode(monsterNode)
                    }
                    inflateMonster(by: inflation)
                }
                
                Spacer()
                
                // MARK: - category buttons
                HStack {
                    categoryButton("eyes")
                    categoryButton("mouth")
                    categoryButton("horns")
                    // categoryButton("skin")
                }
                
                if let category = openCategory {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(options(for: category)) { part in
                                Image(part.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        select(part: part, for: category)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                    .transition(.move(edge: .bottom))
                }
                
                Spacer()
                
                // MARK: - open camera
                NavigationLink("open camera") {
                    CameraPage()
                }
                .buttonStyle(.borderedProminent)
                
                // MARK: - save monster to gallery
                Button(action: saveMonster) {
                                Label("Save to Gallery", systemImage: "tray.and.arrow.down")
                                    //.padding()
                                    //.background(Color.blue)
                                    //.foregroundColor(.white)
                                    //.cornerRadius(12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .animation(.easeInOut, value: openCategory)
        }
    }

    
    // MARK: - helpers
    private func inflateMonster(by factor: CGFloat) {
        func inflateMonster(for node: SCNNode) {
            if let shape = node.geometry as? SCNShape {
                shape.extrusionDepth = factor
            }
            for child in node.childNodes {
                inflateMonster(for: child)
            }
        }
        
        inflateMonster(for: monsterNode)
    }
    
    private func categoryButton(_ name: String) -> some View {
        Button {
            withAnimation {
                openCategory = (openCategory == name ? nil : name)
            }
        } label: {
            Text(name.capitalized)
                .frame(maxWidth: .infinity)
            
        }
        .buttonStyle(.bordered)
    }
    
    private func options(for category: String) -> [CustomizablePart] {
        switch category {
        case "eyes": return eyesOptions
        case "mouth": return mouthOptions
        case "horns": return hornOptions
        case "skin": return skinOptions
        default: return []
        }
    }
    
    private func select(part: CustomizablePart, for category: String) {
        switch category {
        case "eyes": selectedEyes = part.imageName
        case "mouth": selectedMouth = part.imageName
        case "horns": selectedHorn = part.imageName
        case "skin": selectedSkin = part.imageName
        default: break
        }
    }
    
    private func saveMonster() {
            if let image = scnView.snapshotOfNode(monsterNode) {
                store.addCapture(image: image)
                print("monster saved to gallery!")
            } else {
                print("failed to create image from monster node.")
            }
        }
}

extension SCNView {
    func snapshotOfNode(_ node: SCNNode) -> UIImage? {
        // temporarily isolate node
        let clonedScene = SCNScene()
        let clonedNode = node.clone()
        clonedScene.rootNode.addChildNode(clonedNode)
        
        // new camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        clonedScene.rootNode.addChildNode(cameraNode)
        
        // position the camera
        let (min, max) = clonedNode.boundingBox
        let size = simd_length(simd_float3(max) - simd_float3(min))
        cameraNode.position = SCNVector3(0, 0, Float(size) * 2.5)
        
        // render the image
        let tempView = SCNView(frame: CGRect(x: 0, y: 0, width: 512, height: 512))
        tempView.scene = clonedScene
        tempView.pointOfView = cameraNode
        tempView.backgroundColor = .clear
        
        return tempView.snapshot()
    }
}

/* #Preview {
    CustomizePage()
} */ 
