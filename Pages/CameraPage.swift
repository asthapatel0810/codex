//
//  CameraPage.swift
//  NightmareMonster
//
//  Created by Astha  Patel on 9/5/25.
//

import SwiftUI
import AVFoundation
import Photos
import UIKit

// MARK: - CameraView
struct CameraView: UIViewRepresentable {
    @Binding var useFrontCamera: Bool
    @Binding var coordinatorRef: Coordinator?
    var onPhotoCapture: (UIImage) -> Void

    class CameraPreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let sessionQueue = DispatchQueue(label: "camera.session.queue")
    var currentCameraPosition: AVCaptureDevice.Position = .front
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        DispatchQueue.main.async {
            self.coordinatorRef = coordinator
        }
        return coordinator
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        //coordinatorRef = context.coordinator
        let view = CameraPreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        //context.coordinator.parent = self
        context.coordinator.previewView = view
        
        sessionQueue.async {
            setupCamera(for: view)
        }
    
        return view
    }
    

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        /* sessionQueue.async {
            self.switchCamera(for: uiView)
        } */
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView
        weak var previewView: CameraPreviewView?

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func capturePhoto() {
            let settings = AVCapturePhotoSettings()
            parent.photoOutput.capturePhoto(with: settings, delegate: self)
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.parent.onPhotoCapture(image)
            }
        }
    }

   // MARK: - set up camera
    private func setupCamera(for view: CameraPreviewView) {
        session.beginConfiguration()
        session.sessionPreset = .photo
        session.inputs.forEach { session.removeInput($0) }

        let position: AVCaptureDevice.Position = useFrontCamera ? .front : .back
        //currentCameraPosition = position
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: useFrontCamera ? .front : .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        view.videoPreviewLayer.session = session
        session.commitConfiguration()
        session.startRunning()
    }
}


// MARK: - CameraPage
struct CameraPage: View {
    @EnvironmentObject var store: Store
    @State private var useFrontCamera = true
    @State private var monsterImage = UIImage(named: "monster") // Replace with asset name
    @State private var capturedPhoto: UIImage?
    @State private var cameraCoordinator: CameraView.Coordinator?
    @State private var showShareSheet = false
    @State private var selectedImage: UIImage?
    // private var currentCameraPosition: AVCaptureDevice.Position = .front

    var body: some View {
        ZStack {
            // Camera feed
            CameraView(useFrontCamera: $useFrontCamera,
                       coordinatorRef: $cameraCoordinator,
                       onPhotoCapture: { photo in combine(photo: photo) } )
                .ignoresSafeArea()

            // Monster overlay
            if let monster = monsterImage {
                Image(uiImage: monster)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
                    .opacity(0.8)
            }

            VStack {
                Spacer()
                
                //photo strip
                if !store.captures.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.captures, id: \.self) { capture in
                                if let image = capture.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .onTapGesture {
                                            selectedImage = image
                                            showShareSheet = true
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 90)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 10)
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        cameraCoordinator?.capturePhoto()
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .clipShape(.circle)
                }
                .padding()
            }
        }
        .onAppear {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    print("camera permission denied.")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let selectedImage = selectedImage {
                ShareSheet(activityItems: [selectedImage])
            }
        }
    }

    // MARK: - Combine captured photo + monster overlay into one image
    func combine(photo: UIImage) {
        guard let monster = monsterImage else {
            store.addCapture(image: photo)
            return
        }

        let size = photo.size
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        photo.draw(in: CGRect(origin: .zero, size: size))
        monster.draw(in: CGRect(x: (size.width - 250)/2, y: (size.height - 250)/2, width: 250, height: 250), blendMode: .normal, alpha: 0.8)
        let combined = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let combined = combined {
            store.addCapture(image: combined)
            savePhoto(combined)
        }
    }
    
    // MARK: - save to camera roll
    func savePhoto(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                print("photo library access denied.")
            }
        }
    }
}

// MARK: - share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
}
