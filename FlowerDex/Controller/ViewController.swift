//
//  ViewController.swift
//  FlowerDex
//
//  Created by Ob yda on 6/12/24.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikiURL = "https://en.wikipedia.org/w/api.php"
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label: UILabel!
    let imagePicker = UIImagePickerController()
    var pickedImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }
    
    func detect(flowerImage: CIImage) {
            
        let config = MLModelConfiguration()
        // Load the ML model through its generated class
        guard let model = try? VNCoreMLModel(for: FlowerClassifier(configuration: config).model) else {
                fatalError("can't load ML model")
            }
            
            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation],
                    let topResult = results.first
                    else {
                        fatalError("unexpected result type from VNCoreMLRequest")
                }
                    DispatchQueue.main.async {
                        self.navigationItem.title = topResult.identifier.capitalized
                        self.navigationController?.navigationBar.barTintColor = UIColor.green
                        self.navigationController?.navigationBar.isTranslucent = false
                        self.requestInfo(flowerName: topResult.identifier)
                    }
                
            }
            
            let handler = VNImageRequestHandler(ciImage: flowerImage)
            
            do {
                try handler.perform([request])
            }
            catch {
                print(error)
            }
        }
        
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikiURL, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                print("Go to wiki")
                print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription  = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL), completed: { image, error,  cache, url in
                    if let currentImage = self.imageView.image {
                        DispatchQueue.main.async {
                            self.label.text = flowerDescription
                        }
                    } else {
                        self.imageView.image = self.pickedImage
                        self.label.text = "Could not get information on flower from Wikipedia."
                    }
            })
        }
    }
}
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
        if let image = info[.editedImage] as? UIImage {
                
                pickedImage = image
                imagePicker.dismiss(animated: true, completion: nil)
                guard let ciImage = CIImage(image: image) else {
                    fatalError("couldn't convert uiimage to CIImage")
                }
                detect(flowerImage: ciImage)
            }
        }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
}

