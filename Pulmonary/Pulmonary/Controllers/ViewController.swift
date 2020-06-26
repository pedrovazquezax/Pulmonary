//
//  ViewController.swift
//  Pulmonary
//
//  Created by Pedro Antonio Vazquez Rodriguez on 25/06/20.
//  Copyright © 2020 Pedro Antonio Vazquez Rodriguez. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    //clasificacion
        lazy var classificationRequest: VNCoreMLRequest = {
            do {
                let model = try VNCoreMLModel(for: Enfermedades().model)
    
                let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                    self?.processRecognition(for: request, error: error)
                })
                request.imageCropAndScaleOption = .centerCrop
                return request
            } catch {
                fatalError("Failed to load Vision ML model: \(error)")
            }
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func galeryAction(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                   presentPhotoPicker(sourceType: .photoLibrary)
                   return
               }
        self.presentPhotoPicker(sourceType: .photoLibrary)
    }
    
    @IBAction func cameraAction(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                   presentPhotoPicker(sourceType: .photoLibrary)
                   return
               }
        self.presentPhotoPicker(sourceType: .camera)

    }
    
    //update label texto
           func updateRecognitions(for image: UIImage) {
               textLabel.text = "Reconociendo Daño..."
       
               let orientation = CGImagePropertyOrientation(image.imageOrientation)
               guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
       
               DispatchQueue.global(qos: .userInitiated).async {
                   let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
                   do {
                       try handler.perform([self.classificationRequest])
                   } catch {
                       print("Failed to perform classification.\n\(error.localizedDescription)")
                   }
               }
           }
        // proceso de reconocimiento del daño
       func processRecognition(for request: VNRequest, error: Error?) {
           DispatchQueue.main.async {
               guard let results = request.results else {
                   self.textLabel.text = "No hubo recocnocimiento de daño en la  imagen.\n\(error!.localizedDescription)"
                   return
               }
               let classifications = results as! [VNClassificationObservation]
           
               if classifications.isEmpty {
                   self.textLabel.text = "No hubo recocnocimiento de daño en la  imagen."
               } else {
                   // Display top classifications ranked by confidence in the UI.
                   let topClassifications = classifications.prefix(2)
                   let descriptions = topClassifications.map { classification in
                       // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                      return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                   }
                   self.textLabel.text = "El tipo de daño es:\n" + descriptions.joined(separator: "\n")
               }
           }
       }
    
   
    
    
    //muestra el picker view(camara o galeria )
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)

          let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            imageView.image = image
            updateRecognitions(for: image)
        }
    
    
}


// ayuda a mejorar la imagen
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
