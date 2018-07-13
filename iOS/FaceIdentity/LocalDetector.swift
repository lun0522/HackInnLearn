//
//  LocalDetector.swift
//  FaceIdentity
//
//  Created by Pujun Lun on 7/12/18.
//  Copyright © 2018 Pujun Lun. All rights reserved.
//

import Foundation
import Vision

class LocalDetector {
    
    static let sharedInstance = LocalDetector()
    static let kDetectionTimeIntervalThreshold = 1.0
    static let kTrackingConfidenceThreshold = 2.0
    
    enum DetectionResult {
        case notFound
        case foundByDetection(CGRect)
        case foundByTracking(CGRect)
    }
    
    let faceDetection = VNDetectFaceRectanglesRequest()
    var lastObservation: VNDetectedObjectObservation?
    let faceDetectionRequest = VNSequenceRequestHandler()
    var faceTrackingRequest = VNSequenceRequestHandler()
    var resultHandler: ((DetectionResult) -> Void)?
    var timestamp = Date().timeIntervalSince1970
    var tracking = false
    
    /// empty body
    /// used to initialize the singleton beforehand
    public func initialize() { }
    
    public func detectFace(in image: CIImage,
                           resultHandler: @escaping (DetectionResult) -> Void) {
        self.resultHandler = resultHandler
        defer {
            self.resultHandler = nil
        }
        let currentTime = Date().timeIntervalSince1970
        tracking = tracking && (currentTime - timestamp < LocalDetector.kDetectionTimeIntervalThreshold)
        if tracking {
            trackFace(inImage: image)
        } else {
            detectFace(inImage: image)
        }
    }
    
    func log(_ message: String) {
        print("[LocalDetector] " + message)
    }
    
    func detectFace(inImage image: CIImage) {
        guard let handler = self.resultHandler else {
            log("Failed in detection: no result handler")
            return
        }
        
        do {
            try faceDetectionRequest.perform([faceDetection], on: image)
        } catch {
            log(error.localizedDescription)
            handler(.notFound)
            return
        }
        
        guard let results = faceDetection.results as? [VNFaceObservation] else {
            log("Failed in detection: wrong type")
            handler(.notFound)
            return
        }
        
        guard results.count > 0 else {
            handler(.notFound)
            return
        }
        
        lastObservation = results.max {
            $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height
        }
        tracking = true
        timestamp = Date().timeIntervalSince1970
        // https://stackoverflow.com/a/46355234/7873124
        // Re-instantiate the request handler after the first frame used for tracking changes,
        // to avoid that Vision throws "Exceeded maximum allowed number of Trackers" error
        faceTrackingRequest = VNSequenceRequestHandler()
        handler(.foundByDetection(lastObservation!.boundingBox))
    }
    
    func trackFace(inImage image: CIImage) {
        guard let handler = self.resultHandler else {
            log("Failed in tracking: no result handler")
            return
        }
        
        guard let lastObservation = self.lastObservation else {
            log("Failed in tracking: no last observation")
            handler(.notFound)
            return
        }
        
        // The default tracking level of VNTrackObjectRequest is .fast,
        // which results that the confidence is either 0.0 or 1.0.
        // For more precise results, it should be set to .accurate,
        // so that the confidence floats between 0.0 and 1.0
        let faceTracking = VNTrackObjectRequest(
            detectedObjectObservation: lastObservation,
            completionHandler: {
                [unowned self] (request, error) in
                guard error == nil else {
                    self.log(error!.localizedDescription)
                    handler(.notFound)
                    return
                }
                guard let results = request.results, results.count > 0 else {
                    handler(.notFound)
                    return
                }
                guard let observation = results[0] as? VNDetectedObjectObservation else {
                    self.log("Failed in tracking: wrong type")
                    handler(.notFound)
                    return
                }
                self.lastObservation = observation
                handler(.foundByDetection(observation.boundingBox))
                if Double(observation.confidence) < LocalDetector.kTrackingConfidenceThreshold {
                    self.tracking = false
                    self.detectFace(inImage: image)
                } else {
                    handler(.foundByDetection(observation.boundingBox))
                }
        })
        faceTracking.trackingLevel = .accurate
        
        do {
            try faceTrackingRequest.perform([faceTracking], on: image)
        } catch {
            log(error.localizedDescription)
            handler(.notFound)
            return
        }
    }
    
}
