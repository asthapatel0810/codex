//
//  Gallery.swift
//  NightmareMonster
//
//  Created by Astha  Patel on 9/5/25.
//

import SwiftUI

struct GalleryPage: View {
    @EnvironmentObject var store: Store
    @State private var navigateToRoom = false

    struct MonsterBubble: Identifiable {
        let id = UUID()
        let image: UIImage
        var position: CGPoint
    }

    @State private var bubbles: [MonsterBubble] = []
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero
    @State private var selectedMonster: UIImage?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                
                ZStack {
                    Color.black.ignoresSafeArea()

                    ForEach(bubbles) { bubble in
                        let x = bubble.position.x + dragOffset.width + lastDragOffset.width + center.x
                        let y = bubble.position.y + dragOffset.height + lastDragOffset.height + center.y
                        let bubbleCenter = CGPoint(x: x, y: y)

                        // Distance to center affects scale
                        let dist = hypot(bubbleCenter.x - center.x, bubbleCenter.y - center.y)
                        let scale = max(0.8, 1.3 - dist / 400)

                        Image(uiImage: bubble.image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 8)
                            .frame(width: 200 * scale, height: 200 * scale)
                            .position(x: x, y: y)
                            .onTapGesture {
                                selectedMonster = bubble.image
                                showDetail = true
                            }
                            .animation(.easeOut(duration: 0.25), value: scale)
                    }
                    
                    VStack {
                        // Top Logo
                        Image("nightmare_monster_white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220)
                            .padding(.top, 50)
                            .shadow(radius: 10)
                            .accessibilityLabel("Nightmare Monster Logo")
                        
                        Spacer()
                        
                        NavigationLink(destination: RoomPage(), isActive: $navigateToRoom) { EmptyView() }
                        
                        Button(action: { navigateToRoom = true }) {
                            Label("add new monster", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.8))
                                        .shadow(radius: 10)
                                )
                        }
                        .padding(.bottom, 40)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                            
                            // haptic feedback when near a bubble
                            let combinedOffset = CGSize(width: lastDragOffset.width + dragOffset.width, height: lastDragOffset.height + dragOffset.height)
                            
                            for bubble in bubbles {
                                let bubblePos = CGPoint(
                                    x: bubble.position.x + combinedOffset.width,
                                    y: bubble.position.y + combinedOffset.height
                                )
                                let dist = hypot(bubblePos.x, bubblePos.y)
                                if dist < 50 {
                                    provideHapticFeedback()
                                    break
                                }
                            }
                        }
                        .onEnded { value in
                            lastDragOffset.width += value.translation.width
                            lastDragOffset.height += value.translation.height
                            dragOffset = .zero
                        }
                )
                .onAppear {
                    generateBubbles()
                }
                .sheet(isPresented: $showDetail) {
                    if let image = selectedMonster {
                        MonsterDetailView(image: image)
                    }
                }
            }
        }
    }

    // Create bubbles from the store's captures
    private func generateBubbles() {
        let captures = store.captures.compactMap { $0.image }
        var newBubbles: [MonsterBubble] = []
        
        // degine concentric circle layout
        let spacing: CGFloat = 180 // distance between rings
        var ringIndex = 0
        var itemsInRing = 6
        
        for (index, image) in captures.enumerated() {
            if index == 0 {
                // first one in center
                newBubbles.append(MonsterBubble(image: image, position: .zero))
            } else {
                // calculate angle and radius for ring position
                let radius = CGFloat(ringIndex + 1) * spacing
                let angle = (2 * .pi / CGFloat(itemsInRing)) * CGFloat(index % itemsInRing)
                let position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                newBubbles.append(MonsterBubble(image: image, position: position))
                
                // once one ring is filled, move onto next
                if (index + 1) % itemsInRing == 0 {
                    ringIndex += 1
                    itemsInRing += 4
                }
            }
        }
        
        bubbles = newBubbles
    }
    
    private func provideHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
    }
}

// MARK: - Monster Detail View
struct MonsterDetailView: View {
    var image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(radius: 15)
                    .padding()

                Spacer()
            }
        }
    }
}

#Preview {
    GalleryPage()
        .environmentObject(Store())
}


/* #Preview {
    GalleryPage()
} */
