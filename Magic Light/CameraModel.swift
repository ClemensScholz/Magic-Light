//
//  CameraView.swift
//  Magic Light
//
//  Created by Clemens on 17.01.21.
//

import SwiftUI
import AVFoundation
import Vision

class CameraModel: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    
    @Published var preview : AVCaptureVideoPreviewLayer!
    @Published var flashState = false
    
    private var homeManager: HomeManager
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var session = AVCaptureSession()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var requests = [VNRequest]()
    
    private var _handDetection: HandGestureObserver!
    private var handDetection: HandGestureObserver! {
        get {
            if let model = _handDetection { return model }
            _handDetection = {
                do {
                    let configuration = MLModelConfiguration()
                    return try HandGestureObserver(configuration: configuration)
                } catch {
                    fatalError("Couldn't load HandDetection model due to: \(error)")
                }
            }()
            return _handDetection
        }
    }
    
    init(homeManager: HomeManager) {
        self.homeManager = homeManager
        super.init()
        setupAVCapture()
        setupVision()
    }

    func setupVision() {
        do {
            let model = try VNCoreMLModel(for: handDetection.model)
            let classificationRequest = VNCoreMLRequest(model: model, completionHandler: { [weak self] classificationRequest, error in
                self?.processClassifications(for: classificationRequest, error: error)
            })
            
            classificationRequest.imageCropAndScaleOption = .centerCrop
            
            // classificationRequest.usesCPUOnly = true
            
            self.requests = [classificationRequest]
        } catch {
            fatalError("Failed to load ML model: \(error)")
        }
    }
    
    func processClassifications(for request: VNRequest, error: Error?) {
        
        guard let results = request.results else {
            print("ERROR: Request does not have results")
            return
        }
        
        let observations = results as! [VNRecognizedObjectObservation]
        
        if (!observations.isEmpty) {
            for observation in observations {
                guard let topLable = observation.labels.first else {
                    print("ERROR: Object observation has no labels")
                    continue
                }
                
                if (topLable.identifier == "Open") {
                    homeManager.lightbulb?.togglePower(state: true)
                } else if (topLable.identifier == "Fist") {
                    homeManager.lightbulb?.togglePower(state: false)
                } else if (topLable.identifier == "Horizontal" || topLable.identifier == "Vertical") {
                    classifyMovement(for: observation, identifier: topLable.identifier)
                }
                
                let message = String(format: "OBSERVED: \(topLable.identifier) with %.2f", observation.confidence * 100) + "% confidence"
                print(message)
            }
        }
    }
    
    func classifyMovement(for observation: VNRecognizedObjectObservation, identifier: String) {
        let boundingBox = observation.boundingBox
        
        if (identifier == "Vertical") {
            homeManager.lightbulb?.setHue(value: Int(boundingBox.midX * 360))
        } else if (identifier == "Horizontal") {
            homeManager.lightbulb?.setBrightness(value: Int(boundingBox.midY * 100))
        }
        
        print("DEBUG: MidX = \(boundingBox.midX), MidY = \(boundingBox.midY)")
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        print("DEBUG: Frame captured")
        
        if (homeManager.reachable) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            
            let exifOrientation = exifOrientationFromDeviceOrientation()
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
            do {
                try imageRequestHandler.perform(self.requests)
            } catch {
                print(error)
            }
        } else {
            print("DEBUG: Home manager not reachable")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("DEBUG: Frame dropped")
    }
    
    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("ERROR: Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        
        guard session.canAddInput(deviceInput) else {
            print("ERROR: Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        
        session.addInput(deviceInput)
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("ERROR: Could not add video data output scto the session")
            session.commitConfiguration()
            return
        }
        
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.isEnabled = true

        session.commitConfiguration()
        preview = AVCaptureVideoPreviewLayer(session: session)
        startCaptureSession()
    }
    
    func startCaptureSession() {
        session.startRunning()
    }
    
    func toggleFlash() {
        print("DEBUG: Toggeling Flash")
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if flashState == false {
                    device.torchMode = .on
                    flashState = true
                } else {
                    device.torchMode = .off
                    flashState = false
                }
                
                device.unlockForConfiguration()
            } catch {
                print("ERROR: Torch could not be used")
            }
        } else {
            print("ERROR: Torch is not available")
        }
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
