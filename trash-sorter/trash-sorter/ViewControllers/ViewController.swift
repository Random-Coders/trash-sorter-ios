//
//  ViewController.swift
//  trash-sorter
//
//  Created by Cappillen on 3/9/19.
//  Copyright © 2019 Cappillen. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import Clarifai

class ViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var buttonBackground: UIView!
    @IBOutlet weak var captureButton: UIButton!
    
    // MARK: - Properties
    
    // Global class variables
    
    // Instance of the CameraController - going to help us take picture
    let cameraController = CameraController()
    // Image view to display the image the camera took
    let imageView = UIImageView()
    // add the api here
    let app = ClarifaiApp(apiKey: ConstantsAPI.clarifaiapi.key)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /* This method is called after the view controller
         has loaded its view hierarchy into memory. */
        // Do any additional setup after loading the view.
        
        //        IAPHelper.shared.getProducts()
        
        print("Take photo")
        
        // Start up the camera
        cameraController.prepare {(error) in
            // Print the error if given one
            if let error = error {
                print(error)
            }
            // Display the camera feed on the preiview view
            try? self.cameraController.displayPreview(on: self.previewView)
        }
        
        // Set up UI elements
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /* This method is called before the view controller's
         view is about to be added to a view hierarchy */
        
        // Show the camera view on screen
        self.cameraController.previewLayer?.isHidden = false
        // Activate the camera button
        self.captureButton.isUserInteractionEnabled = true
        
    }
    
    func setupLayout() {
        // Get colors
        let lightblue = UIColor(rgb: 0x0093DD)
        let cyan = UIColor(rgb: 0x0AD2A8)
        
        // Round off the button
        captureButton.layer.zPosition = 10
        //        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        captureButton.layer.borderColor = UIColor.clear.cgColor
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
        
        // Add gradients to the background of the button
        buttonBackground.applyGradient(colours: [lightblue, cyan])
        buttonBackground.layer.cornerRadius = min(buttonBackground.frame.width, buttonBackground.frame.height) / 2
        buttonBackground.layer.masksToBounds = true
        buttonBackground.transform = CGAffineTransform.init(scaleX: 1.4, y: 1.4)
    }
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        let cameraMediaType = AVMediaType.video
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        // Manage the different types of status
        switch cameraAuthorizationStatus {
        case .denied:
            // We don't have access
            // Use the warning controller to dispaly a message saying they need to allow access for the camera
            //            let blankImage = self.previewView.asImage()
            print("No access")
            return
        case .authorized:
            break
        case .restricted:
            break
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                if granted {
                    print("Granted access to \(cameraMediaType)")
                } else {
                    print("Denied access to \(cameraMediaType)")
                }
            }
        }
        
        // Camera controller takes a picture
        cameraController.captureImage { (image, error) in
            // get image
            guard let image = image else {
                print(error ?? "Image capture error")
                return
            }
            
            // change ui view
            self.captureButton.isUserInteractionEnabled = false
            self.cameraController.previewLayer?.isHidden = true
            self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.clipsToBounds = true
            self.imageView.frame = self.previewView.frame
            self.imageView.image = image
            self.previewView.insertSubview(self.imageView, at: 0)
            
            // do something
            let data = image.pngData()!
            
            let headers = ["Authorization": "...",
                           "X-Storage-Id": "..."]
            
            let parameters = ["fileItems[0].replacing": "true",
                              "fileItems[0].path": "/path/something"]
            
            Alamofire.upload(multipartFormData: { form in
                
                form.append(data,
                            withName: "fileItems[0]",
                            fileName: "file1.png",
                            mimeType: "image/png")
                
                parameters.forEach({
                    form.append($0.value.data(using: .utf8)!, withName: $0.key)
                })
                
            }, to: "https://menlo--rafaelcenzano.repl.co/upload", method: .post, headers: headers) { result in
                
                //switch result { ... }
                
            }
            // do something with clarifai
            if let app = self.app {
                app.getModelByName("food-items-v1.0", completion: { (model, error) in
                    let clarifaiImage = ClarifaiImage(image: image)!
                    model?.predict(on: [clarifaiImage], completion: { (outputs, error) in
                        print("%@", error ?? "no error")
                        guard let outputs = outputs else { return }
                        if let output = outputs.first {
                            let concepts = output.concepts
                            print(concepts)
                        }
                    })
                })
            }
        }
    }
    
}
