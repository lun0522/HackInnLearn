//
//  CaptureViewController.swift
//  FaceIdentity
//
//  Created by Pujun Lun on 7/13/18.
//  Copyright © 2018 Pujun Lun. All rights reserved.
//

import UIKit

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

class CaptureViewController: UIViewController, VideoCaptureDelegate {

    var videoLayer: VideoLayer!
    let shapeLayer = CAShapeLayer()
    var faceBoundingBox: CGRect?
    var viewBoundsSize: CGSize!
    var smallTimer: Timer!
    var blackImage: UIImage!
    let blackLayer = UIImageView()
    let noFaceImage = UIImage(contentsOfFile: Bundle.main.path(forResource: "face", ofType: "png")!)!
    var noFaceCount = 0
    var faceImage: UIImage!
    
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
        
        viewBoundsSize = view.bounds.size
        blackImage = UIImage(color: .black, size: viewBoundsSize)
        blackLayer.image = blackImage
        
        smallTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeSmall), userInfo: nil, repeats: true)
    }
    
    override func viewDidLayoutSubviews() {
        videoLayer.frame = view.frame
        shapeLayer.frame = view.frame
        blackLayer.frame = view.frame
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
    
    @objc func timeSmall() {
        if self.faceBoundingBox != nil {
            let imageData = UIImageJPEGRepresentation(faceImage, 1.0)?.base64EncodedString()
            ServerUtils.sendData(Data(),
                                 headerFields: ["Type": "Test",
                                                "Image": imageData!]) { returnedData in
                                                    if let data = returnedData {
                                                        if let returnedStr = String.init(data: data, encoding: .utf8) {
                                                            switch returnedStr {
                                                            case "True":
                                                                DispatchQueue.main.async {
                                                                    if self.blackLayer.superview != nil {
                                                                        self.blackLayer.removeFromSuperview()
                                                                    }
                                                                }
                                                                self.noFaceCount = 0
                                                            case "False":
                                                                DispatchQueue.main.async {
                                                                    self.view.addSubview(self.blackLayer)
                                                                }
                                                                self.noFaceCount = 0
                                                            default:
                                                                self.noFaceCount += 1
                                                                if self.noFaceCount == 3 {
                                                                    DispatchQueue.main.async {
                                                                        self.view.addSubview(self.blackLayer)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
            }
        } else {
            self.noFaceCount += 1
            if self.noFaceCount == 3 {
                DispatchQueue.main.async {
                    self.view.addSubview(self.blackLayer)
                }
            }
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
            self.faceImage = self.noFaceImage
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
            self.faceImage = uiImage
            let rectLayer = CAShapeLayer()
            rectLayer.fillColor = UIColor.clear.cgColor
            rectLayer.strokeColor = UIColor.red.cgColor
            rectLayer.path = UIBezierPath(rect: self.scale(rect, to: self.viewBoundsSize)).cgPath
            self.shapeLayer.sublayers = nil
            self.shapeLayer.addSublayer(rectLayer)
        }
    }

}
