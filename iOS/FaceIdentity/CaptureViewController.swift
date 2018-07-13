//
//  CaptureViewController.swift
//  FaceIdentity
//
//  Created by Pujun Lun on 7/13/18.
//  Copyright © 2018 Pujun Lun. All rights reserved.
//

import UIKit

class CaptureViewController: UIViewController, VideoCaptureDelegate {

    var videoLayer: VideoLayer!
    let shapeLayer = CAShapeLayer()
    var faceBoundingBox: CGRect?
    var viewBoundsSize: CGSize!
    var imageView = UIImageView()
    var bigTimer: Timer!
    var smallTimer: Timer!
    var countDown = 0
    let noFaceImage = UIImage(contentsOfFile: Bundle.main.path(forResource: "face", ofType: "png")!)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocalDetector.sharedInstance.initialize()
        do {
            try videoLayer = VideoLayer.newLayer(withCamera: .front, delegate: self)
        } catch {
            showError("Cannot initialize video layer: " + error.localizedDescription)
            return
        }
        
        shapeLayer.lineWidth = 5.0
        shapeLayer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1))
        view.layer.insertSublayer(shapeLayer, at: 0)
        view.layer.insertSublayer(videoLayer, at: 0)
        
        imageView = UIImageView.init(frame: CGRect.init(x: 20.0, y: 560.0, width: 150.0, height: 150.0))
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        
        viewBoundsSize = view.bounds.size
        
        bigTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(timeBig), userInfo: nil, repeats: true)
        bigTimer.fire()
    }
    
    override func viewDidLayoutSubviews() {
        videoLayer.frame = view.frame
        shapeLayer.frame = view.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        videoLayer.start()
    }
    
    func showError(_ description: String) {
        let alert = UIAlertController(title: "Error", message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func timeBig() {
        countDown = 10
        smallTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeSmall), userInfo: nil, repeats: true)
    }
    
    @objc func timeSmall() {
        if self.faceBoundingBox != nil {
            let imageData = UIImageJPEGRepresentation(imageView.image!, 1.0)?.base64EncodedString()
            ServerUtils.sendData(Data(),
                                 headerFields: ["Type": "Test",
                                                "Image": imageData!]) { returnedData in
                                                    if let data = returnedData {
                                                        if let returnedStr = String.init(data: data, encoding: .utf8) {
                                                            if returnedStr != "True" {
                                                                self.showError(returnedStr)
                                                            }
                                                        }
                                                    }
            }
        }
        
        countDown -= 1
        if countDown == 0 {
            smallTimer.invalidate()
            smallTimer = nil
        }
    }
    
    func didCaptureFrame(_ frame: CIImage) {
        LocalDetector.sharedInstance.detectFace(
            in: frame,
            resultHandler: {
                [unowned self] (detectionResult) in
                switch detectionResult {
                case .notFound:
                    self.didNotFindFace()
                case let .foundByDetection(faceBoundingBox):
                    self.didFindFace(inImage: frame, withRect: faceBoundingBox)
                case let .foundByTracking(faceBoundingBox):
                    self.didFindFace(inImage: frame, withRect: faceBoundingBox)
                }
        })
    }
    
    func scale(_ rect: CGRect, to size: CGSize) -> CGRect {
        return CGRect(x: rect.origin.x * size.width,
                      y: rect.origin.y * size.height,
                      width: rect.size.width * size.width,
                      height: rect.size.height * size.height)
    }
    
    func didNotFindFace() {
        DispatchQueue.main.async {
            self.faceBoundingBox = nil
            self.imageView.image = self.noFaceImage
            self.shapeLayer.sublayers = nil
        }
    }
    
    func didFindFace(inImage image: CIImage, withRect rect: CGRect) {
        self.faceBoundingBox = rect
        
        let ciImage = image.cropped(to: scale(rect, to: image.extent.size))
        
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            showError("Cannot create cgImage")
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        
        DispatchQueue.main.async {
            self.imageView.image = uiImage
            let rectLayer = CAShapeLayer()
            rectLayer.fillColor = UIColor.clear.cgColor
            rectLayer.strokeColor = UIColor.red.cgColor
            rectLayer.path = UIBezierPath(rect: self.scale(rect, to: self.viewBoundsSize)).cgPath
            self.shapeLayer.sublayers = nil
            self.shapeLayer.addSublayer(rectLayer)
        }
    }

}
