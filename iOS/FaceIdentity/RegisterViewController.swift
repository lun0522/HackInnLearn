//
//  RegisterViewController.swift
//  FaceIdentity
//
//  Created by Pujun Lun on 7/13/18.
//  Copyright © 2018 Pujun Lun. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController, VideoCaptureDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    var videoLayer: VideoLayer!
    var faceBoundingBox: CGRect?
    let noFaceImage = UIImage(contentsOfFile: Bundle.main.path(forResource: "face", ofType: "png")!)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocalDetector.sharedInstance.initialize()
        imageView.contentMode = .scaleToFill
        imageView.image = noFaceImage
        captureButton.setTitle("Capture face", for: .normal)
        captureButton.addTarget(self, action: #selector(capture), for: .touchDown)
        enableCaptureButton()
    }
    
    func showError(_ description: String) {
        let alert = UIAlertController(title: "Error", message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func capture(sender: UIButton) {
        switch self.captureButton.title(for: .normal) {
        case "Capture face":
            do {
                try videoLayer = VideoLayer.newLayer(withCamera: .front, delegate: self)
            } catch {
                showError("Cannot initialize video layer: " + error.localizedDescription)
                return
            }
            videoLayer.start()
            captureButton.setTitle("That's me!", for: .normal)
            disableCaptureButton()
        case "That's me!":
            uploadImage(imageView.image!)
            videoLayer.stop()
            performSegue(withIdentifier: "mitext", sender: self)
        default:
            print("Unrecognized title")
        }
    }
    
    func enableCaptureButton() {
        DispatchQueue.main.async {
            self.captureButton.setTitleColor(.red, for: .normal)
            self.captureButton.isUserInteractionEnabled = true
        }
    }
    
    func disableCaptureButton() {
        DispatchQueue.main.async {
            self.captureButton.setTitleColor(.gray, for: .normal)
            self.captureButton.isUserInteractionEnabled = false
            self.imageView.image = self.noFaceImage
        }
    }
    
    func didCaptureFrame(_ frame: CIImage) {
        LocalDetector.sharedInstance.detectFace(
            in: frame,
            resultHandler: {
                [unowned self] (detectionResult) in
                switch detectionResult {
                case .notFound:
                    self.faceBoundingBox = nil
                    self.disableCaptureButton()
                case let .foundByDetection(faceBoundingBox):
                    self.didFindFace(inImage: frame, withRect: faceBoundingBox)
                    self.enableCaptureButton()
                case let .foundByTracking(faceBoundingBox):
                    self.didFindFace(inImage: frame, withRect: faceBoundingBox)
                    self.enableCaptureButton()
                }
        })
    }
    
    func didFindFace(inImage image: CIImage, withRect rect: CGRect) {
        let ciImage = image.cropped(to: scale(rect, to: image.extent.size))
        
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            showError("Cannot create cgImage")
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        
        DispatchQueue.main.async {
            self.imageView.image = uiImage
        }
    }
    
    func scale(_ rect: CGRect, to size: CGSize) -> CGRect {
        return CGRect(x: rect.origin.x * size.width,
                      y: rect.origin.y * size.height,
                      width: rect.size.width * size.width,
                      height: rect.size.height * size.height)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat, newHeight: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func uploadImage(_ image: UIImage) {
        let imageData = UIImageJPEGRepresentation(image, 1.0)?.base64EncodedString()
        ServerUtils.sendData(Data(),
                             headerFields: ["Type": "Baseline",
                                            "Image": imageData!]) { returnedData in
                                                if let data = returnedData {
                                                    if let returnedStr = String.init(data: data, encoding: .utf8) {
                                                        print(returnedStr)
                                                    }
                                                }
        }
    }

}
