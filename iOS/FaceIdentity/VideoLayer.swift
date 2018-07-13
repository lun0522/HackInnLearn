//
//  VideoLayer.swift
//  FaceIdentity
//
//  Created by Pujun Lun on 7/12/18.
//  Copyright © 2018 Pujun Lun. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoCaptureDelegate {
    
    func didCaptureFrame(_ frame: CIImage)
    
}

class VideoLayer: AVCaptureVideoPreviewLayer, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var currentCameraPosition = AVCaptureDevice.Position.unspecified
    var capturerDelegate: VideoCaptureDelegate!
    var capturerSession: AVCaptureSession!
    
    public static func log(_ message: String) {
        print("[VideoLayer] " + message)
    }
    
    public static func newLayer(withCamera position: AVCaptureDevice.Position,
                                delegate: VideoCaptureDelegate) throws -> VideoLayer? {
        let session = AVCaptureSession()
        let layer = VideoLayer(session: session)
        layer.capturerDelegate = delegate
        layer.capturerSession = session
        layer.currentCameraPosition = position
        layer.videoGravity = .resizeAspectFill
        
        session.beginConfiguration()
        
        if let errorReason = layer.addCamera(oriented: position) {
            log(errorReason)
            return nil
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        let connection = videoOutput.connection(with: .video)
        connection?.videoOrientation = .portrait
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(layer, queue: DispatchQueue(label: "videooutput.queue"))
        guard session.canAddOutput(videoOutput) else {
            log("cannot add output")
            return nil
        }
        session.addOutput(videoOutput)
        
        session.commitConfiguration()
        
        return layer
    }
    
    public func start() {
        capturerSession.startRunning()
    }
    
    public func stop() {
        capturerSession.stopRunning()
    }
    
    public func switchCamera() throws {
        capturerSession.beginConfiguration()
        
        switch currentCameraPosition {
        case .front:
            currentCameraPosition = .back
        case .back, .unspecified:
            currentCameraPosition = .front
        }
        
        capturerSession.removeInput(capturerSession.inputs[0])
        
        if let errorReason = addCamera(oriented: currentCameraPosition) {
            VideoLayer.log(errorReason)
            return
        }
        
        capturerSession.commitConfiguration()
    }
    
    func addCamera(oriented orientation: AVCaptureDevice.Position) -> String? {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: orientation) else {
                                                    return "Cannot initialize camera"
        }
        do {
            let deviceInput = try AVCaptureDeviceInput(device: camera)
            guard capturerSession.canAddInput(deviceInput) else {
                return "Cannot add input"
            }
            capturerSession.addInput(deviceInput)
        } catch {
            return error.localizedDescription
        }
        return nil
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            var frame = CIImage(cvImageBuffer: pixelBuffer)
            frame = frame.oriented(forExifOrientation: Int32(CGImagePropertyOrientation.leftMirrored.rawValue))
            capturerDelegate.didCaptureFrame(frame)
        }
    }
    
}
