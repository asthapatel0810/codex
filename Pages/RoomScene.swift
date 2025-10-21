//
//  RoomScene.swift
//  NightmareMonster
//
//  Created by Bénédicte Knudson on 9/16/25.
//

import SwiftUI
import SceneKit
import CoreImage
import UIKit
import Vision

struct RoomSceneView: UIViewRepresentable {
    @Binding var placedProps: [PlacedItem]
    @Binding var placedLights: [PlacedItem]
    
    private let scene = RoomSceneController.sharedScene
    
    static var shared = RoomSceneView(placedProps: .constant([]), placedLights: .constant([])) // FOR TESTING
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.showsStatistics = true
        scnView.backgroundColor = .black

        // add tap recognizer
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)
        
        // add flashlight pan
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(pan)

        setupRoom(in: scene)
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        syncProps(in: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - synch props
    private func syncProps(in scnView: SCNView) {
        guard let root = scnView.scene?.rootNode else { return }
        
        // remove old props
        root.childNodes.filter { $0.name?.hasPrefix("prop_") == true } .forEach {
            $0.removeFromParentNode() }
        
        // add each prop
        for item in placedProps {
            if let node = loadProp(named: item.name) {
                node.position = SCNVector3(
                    Float((item.position.x - 200) / 20),
                    0,
                    Float((item.position.y - 200) / 20))
                
                node.name = "prop_\(item.id)"
                root.addChildNode(node)
            }
        }
    }

    // MARK: - load a prop node
    private func loadProp(named name: String) -> SCNNode? {
        // look for usdz file
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz"),
              let propScene = try? SCNScene(url: url, options: nil) else {
            print("ERROR Could not load \(name).usdz")
            return nil
        }
        
        let node = SCNNode()
        for child in propScene.rootNode.childNodes {
            node.addChildNode(child.clone())
        }
        
        // normalize size
        let (minBound, maxBound) = node.boundingBox
        let size = SCNVector3(
            x: maxBound.x - minBound.x,
            y: maxBound.y - minBound.y,
            z: maxBound.z - minBound.z)
        
        let maxDimension = max(size.x, max(size.y, size.z))
        
        guard maxDimension > 0.0 else {
            print("zero size bounding box, return without scaling")
            return node
        }
        
        let desiredSize: Float = 3 // 1m in scene units
        let scale = desiredSize / maxDimension
        node.scale = SCNVector3(x: scale, y: scale, z: scale)
        
        return node
    }
    
    
    // MARK: - direct placement
    func placeProp(named name: String, at position: SCNVector3 = SCNVector3(0,0,-2)) {
        guard let propNode = loadProp(named: name),
              let root = scene.rootNode as SCNNode? else { return }
        
        propNode.position = position
        propNode.name = "prop_\(UUID().uuidString)"
        root.addChildNode(propNode)
    }
    
    
    // MARK: - scene setup
    private func setupRoom(in scene: SCNScene) {
        //let scene = SCNScene()

        // camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        cameraNode.eulerAngles = SCNVector3(-0.1, 0, 0)
        scene.rootNode.addChildNode(cameraNode)

        // floor
        let floor = SCNFloor()
        floor.reflectivity = 0.0
        let floorNode = SCNNode(geometry: floor)
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
        scene.rootNode.addChildNode(floorNode)


        // flashlight (movable spotlight)
        let flashlightNode = SCNNode()
        let light = SCNLight()
        light.type = .spot
        light.castsShadow = true
        light.spotInnerAngle = 20
        light.spotOuterAngle = 60
        light.intensity = 2000
        flashlightNode.light = light
        flashlightNode.position = SCNVector3(0, 5, 10)
        flashlightNode.name = "flashlight"
        scene.rootNode.addChildNode(flashlightNode)

        // back wall
        let wall = SCNNode(geometry: SCNBox(width: 20, height: 12, length: 1, chamferRadius: 0))
        wall.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        wall.geometry?.firstMaterial?.lightingModel = .physicallyBased
        wall.castsShadow = false // receive but not cast
        wall.position = SCNVector3(0, 0.5, -6)
        wall.name = "room_wall"
        scene.rootNode.addChildNode(wall)
        
        // left wall
        let wallLeft = SCNNode(geometry: SCNBox(width: 10, height: 12, length: 1, chamferRadius: 0))
        wallLeft.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        wallLeft.geometry?.firstMaterial?.lightingModel = .physicallyBased
        wallLeft.castsShadow = false // receive but not cast
        wallLeft.position = SCNVector3(-8, 0.5, -1)
        wallLeft.eulerAngles = SCNVector3(0, Double.pi / 2, 0)
        wallLeft.name = "room_wallLeft"
        scene.rootNode.addChildNode(wallLeft)
        
        // right wall
        let wallRight = SCNNode(geometry: SCNBox(width: 10, height: 12, length: 1, chamferRadius: 0))
        wallRight.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        wallRight.geometry?.firstMaterial?.lightingModel = .physicallyBased
        wallRight.castsShadow = false // receive but not cast
        wallRight.position = SCNVector3(8, 0.5, -1)
        wallRight.eulerAngles = SCNVector3(0, Double.pi / 2, 0)
        wallRight.name = "room_wallRight"
        scene.rootNode.addChildNode(wallRight)
        
        // bed (box placeholder)
        let bed = SCNNode(geometry: SCNBox(width: 4, height: 1, length: 2, chamferRadius: 0))
        bed.geometry?.firstMaterial?.diffuse.contents = UIColor.brown
        bed.castsShadow = true // cast
        bed.position = SCNVector3(-4, 1, 0)
        bed.eulerAngles = SCNVector3(0, Double.pi / 2, 0)
        bed.name = "room_bed"
        scene.rootNode.addChildNode(bed)

        // door (flat box)
        let door = SCNNode(geometry: SCNBox(width: 2, height: 4, length: 0.1, chamferRadius: 0))
        door.geometry?.firstMaterial?.diffuse.contents = UIColor.systemTeal
        door.castsShadow = true // cast
        door.position = SCNVector3(7.5, 2, 0)
        door.eulerAngles = SCNVector3(0, Double.pi / 2, 0)
        door.name = "room_door"
        scene.rootNode.addChildNode(door)
        
        // ambient light
        let ambient = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 200
        ambient.light = ambientLight
        scene.rootNode.addChildNode(ambient)

        // hallway light (hidden at first)
        let hallwayLight = SCNNode()
        let hLight = SCNLight()
        hLight.type = .omni
        hLight.intensity = 0
        hLight.castsShadow = false
        hallwayLight.light = hLight
        hallwayLight.position = SCNVector3(4, 0.2, 1)
        hallwayLight.name = "room_hallwayLight"
        scene.rootNode.addChildNode(hallwayLight)

        // window (flat plane)
        let window = SCNNode(geometry: SCNPlane(width: 3, height: 2))
        window.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
        window.position = SCNVector3(-7.25, 3, -1)
        window.eulerAngles = SCNVector3(0, Double.pi / 2, 0)
        window.name = "room_window"
        scene.rootNode.addChildNode(window)

        // shade (animated on tap)
        let shade = SCNNode(geometry: SCNPlane(width: 3, height: 2))
        shade.geometry?.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.7)
        shade.position = SCNVector3(-7, 3, -1)
        shade.eulerAngles = SCNVector3(0, Double.pi / 2, 0)
        shade.isHidden = true
        shade.name = "room_shade"
        scene.rootNode.addChildNode(shade)
    }

    // MARK: - coordinator for gestures
    class Coordinator: NSObject {
        private var draggedNode: SCNNode?
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            
            // what did we tap on?
            let hits = scnView.hitTest(location, options: [:])
            guard let tappedNode = hits.first?.node else { return }
            
            if tappedNode.name == "door" || tappedNode.name == "window" {
                // toggle light
                if let hallwayLight = scnView.scene?.rootNode.childNode(withName: "hallwayLight", recursively: false),
                    let light = hallwayLight.light {
                        light.intensity = (light.intensity == 0 ) ? 1500 : 0
                }
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            
            switch gesture.state {
            case .began:
                // try to pick up prop, anything with room_ is not movable
                let hits = scnView.hitTest(location, options: [:])
                draggedNode = hits.first(where: { $0.node.name?.hasPrefix("room_") == false})?.node
                
            case .changed:
                guard let node = draggedNode else {
                    // if not dragging prop, move flashlight
                    moveFlashlight(with: gesture, in: scnView)
                    return
                }
                // project touch onto floor
                if let result = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.closest.rawValue])
                    .first {
                    node.position = result.worldCoordinates
                }
                
            case .ended, .cancelled:
                draggedNode = nil
                
            default: break
                
            }
        }
         
        private func moveFlashlight(with gesture: UIPanGestureRecognizer, in scnView: SCNView) {
            let translation = gesture.translation(in: scnView)
            if let flashlight = scnView.scene?.rootNode.childNode(withName: "flashlight", recursively: false) {
                flashlight.position.x += Float(translation.x) * 0.01
                flashlight.position.y += Float(-translation.y) * 0.01
                gesture.setTranslation(.zero, in: scnView)
            }
        }
    }
    
    // MARK: - shadow -> monster pipeline
    /* private func generateMonster(from scene: SCNScene) -> SCNNode? {
        // set up offscreen renderer
        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = scene
        
        // position camera straight at back wall
        let cam = SCNCamera()
        let camNode = SCNNode()
        camNode.camera = cam
        camNode.position = SCNVector3(0, 5, 10) //same as main cam, facing wall
        camNode.eulerAngles = SCNVector3(0, 0, 0)
        renderer.pointOfView = camNode
        
        // snapshot of back wall with shadows
        let image = renderer.snapshot(atTime: 0,
                                      with: CGSize(width: 512, height: 512),
                                      antialiasingMode: .none)
        guard let ciImage = CIImage(image: image) else { return nil }
       
        // threshold filter to get silhouette
        let monochrome = ciImage.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0, kCIInputContrastKey: 4.0])
        
        // note: CoreImage doesn't have built in threshold filter
        // implement with CIColorMatrix or Metal
        // placeholder:
        let silhouette = monochrome
        
        // convert silhouette to CGPath (pseudo code)
        // probably use Vision's VNDetectContoursRequest
        // or bitmap -> path tracer
        // placeholder: circle shape
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 2, height: 2))
        
        // extrude into 3d shape
        let shape = SCNShape(path: path, extrusionDepth: 1)
        shape.firstMaterial?.diffuse.contents = UIColor.red
        let monsterNode = SCNNode(geometry: shape)
        monsterNode.position = SCNVector3(0, 1, -5)
        
        return monsterNode
    } */

}

class RoomSceneController {
    static let sharedScene = SCNScene()
}

extension RoomSceneView {
    // captures snapshot of current scene for silhouette use
    func snapshotSilhouette() -> UIImage? {
        // use same shared scene
        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = self.scene
        
        guard let flashlight = scene.rootNode.childNode(withName: "flashlight", recursively: true), let wall = scene.rootNode.childNode(withName: "room_wall", recursively: true) else {
            print("missing flashlight or wall in scene")
            return nil
        }
        
        // position camera at wall
        let camNode = SCNNode()
        let cam = SCNCamera()
        cam.usesOrthographicProjection = false
        cam.zNear = 0.1
        cam.zFar = 100
        camNode.camera = cam
        camNode.position = SCNVector3(0, 5, 10)
        camNode.eulerAngles = SCNVector3(0, 0, 0)
        renderer.pointOfView = camNode
        
        // ensure shadows are computed
        flashlight.light?.castsShadow = true
        flashlight.light?.shadowMode = .deferred
        flashlight.light?.shadowColor = UIColor.black.withAlphaComponent(0.9)
        
        // render snap at full res
        let image = renderer.snapshot(atTime: 0, with: CGSize(width: 2048, height: 2048), antialiasingMode: .none)
        
        if image.size.width == 0 {
            print("returned empty image")
        }
        
        return image

    }
    
    // MARK: - create monster
    func createMonsterNode(from silhouette: UIImage) -> SCNNode? {
        guard let ciImage = CIImage(image: silhouette) else { return nil }
        
        // 1. convert image to high contrast
        let mono = ciImage
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 4.0
            ])
        
        // 2. detect outer contour
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.0
        request.detectsDarkOnLight = true
        
        let handler = VNImageRequestHandler(ciImage: mono, options: [:])
        try? handler.perform([(request)])
        
        guard let observation = request.results?.first as? VNContoursObservation else {
            return nil
        }
        
        // 3. convert vision contours to a UIBezierPath
        let path = UIBezierPath()
        for i in 0..<observation.contourCount {
            if let contour = try? observation.contour(at: i) {
                let pointsPointer = contour.__normalizedPoints
                let count = contour.pointCount // num points
                
                guard count > 0 else { continue }
                
                // move to first point
                let firstPoint = pointsPointer[0]
                path.move(to: CGPoint(x: CGFloat(firstPoint.x * 200),
                                      y: CGFloat(firstPoint.y * 200)))
    
                // add lines to the rest
                for j in 1..<count {
                    let p = pointsPointer[j]
                    path.addLine(to: CGPoint(x: CGFloat(p.x * 200),
                                             y: CGFloat(p.y * 200)))
                }
                path.close()
            }
        }
        
        // 4. extrude silhouette into 3d shape
        let shape = SCNShape(path: path, extrusionDepth: 1.0)
        shape.firstMaterial?.diffuse.contents = UIColor.red
        shape.firstMaterial?.lightingModel = .physicallyBased
        
        let node = SCNNode(geometry: shape)
        node.position = SCNVector3(0, 1, -5)
        
        // scale and center?
        // node.scale = SCNVector3(0.05, 0.05, 0.05)
        
        return node
    }
}

extension SCNView {
    func captureShadowSilhouette(wallNodeName: String = "room_wall", flashlightName: String = "flashlight") -> UIImage? {
        guard
            let scene = self.scene,
            let wall = scene.rootNode.childNode(withName: wallNodeName, recursively: true),
            let flashlight = scene.rootNode.childNode(withName: flashlightName, recursively: true)
        else {
            print("missing wall or flashlight for shadow capture")
            return nil
        }
        
        // hide all textures, colors
        scene.rootNode.enumerateChildNodes { node, _ in
            if let material = node.geometry?.firstMaterial {
                material.lightingModel = .constant
                material.diffuse.contents = UIColor.white
                material.specular.contents = UIColor.black
                material.emission.contents = UIColor.black
            }
        }
        
        // configure flashlight for sharper shadows
        flashlight.light?.castsShadow = true
        flashlight.light?.shadowMode = .deferred
        flashlight.light?.shadowColor = UIColor.black
        flashlight.light?.shadowRadius = 0.1
        flashlight.light?.shadowBias = 0.0
        
        // temp make background black to isolate mask
        self.scene?.background.contents = UIColor.white
        
        // render view
        let snapshot = self.snapshot()
        
        // postprocess: all non shadow areas -> white, shadow to black
        if let cgImage = snapshot.cgImage,
           let context = CGContext(
                data: nil,
                width: cgImage.width,
                height: cgImage.height,
                bitsPerComponent: 8,
                bytesPerRow: cgImage.width * 4,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
           ) {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
            if let maskImage = context.makeImage() {
                return UIImage(cgImage: maskImage)
            }
        }
        
        return snapshot
    }
}

/* struct Room3DPage_Previews: PreviewProvider {
    static var previews: some View {
        RoomSceneView()
    }
} */
