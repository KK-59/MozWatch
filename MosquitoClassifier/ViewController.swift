//
//  ViewController.swift
//  MosquitoClassifier
//
//  Created by Kaavya K on 1/1/24.
//

import CoreML
import UIKit

import SwiftUI

struct PopupScreen: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            Text("Not all mosquitoes carry diseases the disease as they need to be exposed to it (through biting someone with dengue). Often, in urban areas, mosquitoes are common but those that carry disease are not.\n\nThis app differentiates between the Aedes, Anopheles, and Culex mosquitoes using a machine learning model. Therefore, results may not be completely accurate.")
                .font(.system(size:20))
                .padding()
            
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(Color(uiColor: UIColor(red: 122/255, green: 55/255, blue: 255/255, alpha: 1.0))) // background color of close button
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")?.withRenderingMode(.alwaysTemplate) // Render as template
        imageView.tintColor = UIColor(red: 122/255, green: 55/255, blue: 255/255, alpha: 1.0) // Set tint color
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Select image"
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 27)
        return label
    }()
    
    private let speciesLabel: UILabel = {
        let speciesLabel = UILabel()
        speciesLabel.textAlignment = .center
        speciesLabel.text = ""
        speciesLabel.numberOfLines = 0
        return speciesLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(label)
        view.addSubview(imageView)
        view.addSubview(speciesLabel)
        
        let buttonPopup = UIButton(type: .system)
                buttonPopup.setTitle("?", for: .normal)
                buttonPopup.backgroundColor = UIColor(red: 122/255, green: 55/255, blue: 255/255, alpha: 1.0)
                buttonPopup.setTitleColor(.white, for: .normal)
                buttonPopup.layer.cornerRadius = 20
                buttonPopup.addTarget(self, action: #selector(showPopup), for: .touchUpInside)
                view.addSubview(buttonPopup)

                // Set button layout with constraints
                buttonPopup.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    buttonPopup.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    buttonPopup.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
                    buttonPopup.widthAnchor.constraint(equalToConstant: 40),
                    buttonPopup.heightAnchor.constraint(equalToConstant: 40)
                ])
                
                // Configure the image view tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        tap.numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tap)
        
    }
    
    @objc func showPopup() {
           // Presenting the SwiftUI popup screen
           let popupVC = UIHostingController(rootView: PopupScreen())
           popupVC.modalPresentationStyle = .overFullScreen // Makes it look like a popup
           present(popupVC, animated: true, completion: nil)
       }
    
    @objc func didTapImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {
                action in
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {
              action in
              picker.sourceType = .photoLibrary
              self.present(picker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = CGRect(x: 20, y: view.safeAreaInsets.top, width: view.frame.size.width-40, height: view.frame.size.width-40)
        
        label.frame = CGRect(
                    x: 20,
                    y: view.safeAreaInsets.top+(view.frame.size.width-40)+5,
                    width: view.frame.size.width-40,
                    height: 100
                )
        
        speciesLabel.frame = CGRect(
                x: 20,
                y: view.safeAreaInsets.top+(view.frame.size.width-40)+20,
                width: view.frame.size.width-40,
                height: 300
                )
    }
    
    private func analyzeImage(image: UIImage?) {
        guard let buffer = image?.resize(size: CGSize(width: 299, height: 299))?
                .getCVPixelBuffer() else {
            return
        }
        
        do {
            // Pass the image to the ML model
            let config = MLModelConfiguration()
            let model = try MosquitoClassifier3(configuration: config)
            let input = MosquitoClassifier3Input(image: buffer)
            let output = try model.prediction(input: input)
            // output has an attribute named 'classLabel' that outputs the label (specified in the training phase) of the highest probability genus determined by the model
            if (output.classLabel == "anopheles") {
                label.text = "This is an Anopheles mosquito";
                speciesLabel.text = "This group of mosquitoes include species that can transmit dengue, yellow fever, chikungunya, and Zika. They breed in clean, stagnant water, and are common in and around homes. If Aedes mosquitoes are seen in your home, breeding places observed are flower pots and discarded containers. These mosquitoes usually feed during the day, preferring to bite around the ankles or elbows.";
            } else if (output.classLabel == "aedes") {
                label.text = "This is an Aedes mosquito";
                speciesLabel.text = "This group of mosquitoes include species that can transmit malaria. They generally breed in clean bodies of water such as slow-flowing, cool mountain streams, rock pools, freshwater ponds, and the like. They are more common in rural areas and usually bite in the night.";
            } else if (output.classLabel == "culex") {
                label.text = "This is a Culex mosquito";
                speciesLabel.text = "This group of mosquitoes include species that can transmit Filariasis, West Nile fever, St. Louis encephalitis, and Japanese encephalitis. The mosquito generally breeds in water high concentration of organic debris or even excrement. Usually, these mosquitoes bite at night.";
            } else if (output.classLabel == "non-mosquito") {
                label.text = "This is not a mosquito";
                speciesLabel.text = "If this is false, please take a closer or less blurry image."; }
            
        } catch {
            print(error.localizedDescription)
        }
        
    }

    //Image Picker
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //cancelled
        picker.dismiss(animated: true,completion: nil)
    }
    
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//                return
//        }
//
//        imageView.image = image
//        analyzeImage(image: image)
//    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            // You now have the selected or captured image (pickedImage).
            // You can use it as needed within your app.
            imageView.image = image
            
            analyzeImage(image: image)
        }
        dismiss(animated: true, completion: nil)
    }
    
    
}

