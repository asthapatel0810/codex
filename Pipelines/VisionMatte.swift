//
//  VisionMatte.swift
//  NightmareMonster
//
//  Created by Bénédicte Knudson on 9/14/25.
//

import SwiftUI
import Vision

class VisionMatte {
    private let request = VNGeneratePersonSegmentationRequest()
    private let sequence = VNSequenceRequestHandler()
    
    func matte(for image: CGImage) -> CGImage? {
        do {
            try sequence.perform([request], on: image)
            guard let obs = request.results?.first as? VNPixelBufferObservation else { return nil }
            let pb = obs.pixelBuffer
            let ciImage = CIImage(cvPixelBuffer: pb)
            let ciCtx = CIContext()
            return ciCtx.createCGImage(ciImage, from: ciImage.extent)
        } catch {
            return nil
        }
    }
}
