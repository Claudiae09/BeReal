//
//  PostViewController.swift
//  BeReal
//
//  Created by Claudia Espinosa on 10/10/25.
//

import UIKit
import PhotosUI
import Photos
import ImageIO
import CoreLocation



import ParseSwift

class PostViewController: UIViewController {


    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!

    private var pickedImage: UIImage?
    private var pickedImageLocation: String?
    
    private func reverseGeocode(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("❌ Reverse geocode error:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }

            let city = placemark.locality
            let area = placemark.subLocality
            let state = placemark.administrativeArea

            if let area = area, let city = city {
                completion("\(area), \(city)")
            } else if let city = city, let state = state {
                completion("\(city), \(state)")
            } else {
                completion(placemark.name)
            }
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {

        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())

        config.filter = .images

        config.preferredAssetRepresentationMode = .current

        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)

        picker.delegate = self

        present(picker, animated: true)


    }

    @IBAction func onShareTapped(_ sender: Any) {

        view.endEditing(true)

        guard let image = pickedImage,
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }

        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        var post = Post()

        post.imageFile = imageFile
        post.caption = captionTextField.text
        post.user = User.current
        
        post.location = pickedImageLocation
        print("📍 post.location about to save:", post.location ?? "nil")

        post.save { [weak self] result in
                   switch result {
                   case .success(let post):
                       print("✅ Post Saved! \(post)")


                       if var currentUser = User.current {

                           currentUser.lastPostedDate = Date()


                           currentUser.save { [weak self] userResult in
                               switch userResult {
                               case .success(let user):
                                   print("✅ User Saved! \(user)")

                                   DispatchQueue.main.async {
                                       self?.navigationController?.popViewController(animated: true)
                                   }

                               case .failure(let error):

                                   DispatchQueue.main.async {
                                       self?.showAlert(description: error.localizedDescription)
                                   }
                               }
                           }
                       } else {

                           DispatchQueue.main.async {
                               self?.navigationController?.popViewController(animated: true)
                           }
                       }

                   case .failure(let error):

                       DispatchQueue.main.async {
                           self?.showAlert(description: error.localizedDescription)
                       }
                   }
               }
           }

    @IBAction func onViewTapped(_ sender: Any) {
        view.endEditing(true)
    }

     @IBAction func onTakePhotoTapped(_ sender: UIBarButtonItem) {

         guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
             print("❌📷 Camera not available")
             return
         }

         let imagePicker = UIImagePickerController()

         imagePicker.sourceType = .camera

         imagePicker.allowsEditing = true

         imagePicker.delegate = self

         present(imagePicker, animated: true)
     }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    
}

extension PostViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {


        picker.dismiss(animated: true)

        pickedImageLocation = nil

        if let assetId = results.first?.assetIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)

            if let asset = fetchResult.firstObject, let loc = asset.location {
                let coord = loc.coordinate
                reverseGeocode(latitude: coord.latitude, longitude: coord.longitude) { [weak self] place in
                    self?.pickedImageLocation = place
                    print("📍 Final location name:", place ?? "nil")
                }

                print("📍 PHPicker location:", pickedImageLocation ?? "nil")
            } else {
                print("📍 PHPicker: no location on asset")
            }
        } else {
            print("📍 PHPicker: no assetId")
        }

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in

            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(description: error.localizedDescription)
                }
                return
            }

            guard let image = object as? UIImage else {
                DispatchQueue.main.async {
                    self?.showAlert()
                }
                return
            }

            DispatchQueue.main.async {
                self?.previewImageView.image = image
                self?.pickedImage = image
            }
        }
    }
}

    


extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("❌📷 Unable to get image")
            return
        }
        pickedImageLocation = nil

        if let metadata = info[.mediaMetadata] as? [String: Any],
           let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
           let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
           let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
           let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {

            var latitude = lat
            var longitude = lon

            if latRef == "S" {
                latitude = -latitude
            }
            if lonRef == "W" {
                longitude = -longitude
            }

            reverseGeocode(latitude: latitude, longitude: longitude) { [weak self] place in
                self?.pickedImageLocation = place
                print("📍 Final location name:", place ?? "nil")
            }

            print("📍 Camera location:", pickedImageLocation ?? "nil")


        }
        previewImageView.image = image
        pickedImage = image
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}



