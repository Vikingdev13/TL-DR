//
//  ViewController.swift
//  TL;DR
//
//  Created by John Piccione on 3/25/21.
//

/*
See the LICENSE folder for the licensing information.
*/

import UIKit
import Vision
import VisionKit
import Reductio

class ViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var scannedTextView: UITextView!
    @IBOutlet weak var summarizedTextView: UITextView!
    
    // Vision requests to be performed on each page of the scanned document.
    private var requests = [VNRequest]()
    
    // Dispatch Queue to perform Vision requests.
    private let textRecognitionQueue = DispatchQueue(label: "TextRecognitionQueue",
                                                         qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var resultingText = ""
    
    // Setup Vision request so the request can be reused
    private func setupVision() {
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("The observations are of an unexpected type.")
                return
            }
            // Concatenate the text from all the observations.
            let maximumCandidates = 1
            for observation in observations {
                guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                self.resultingText += candidate.string + "\n"
            }
        }
        // Specify the recognition level
        request.recognitionLevel = .accurate
        self.requests = [request]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Dismiss the keyboard by tapping the screen
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        setupVision()
    }
    // MARK: - Actions
    // Instructions for user on how to use app
    @IBAction func infoButton(_ sender: Any) {
        let alertController = UIAlertController(title: "Welcome to TL;DR!\n", message: "TL;DR is a text summarizer that leverages NLP and your camera to scan text and produce a summary of that text.\n\nHere is how to use TL;DR:\n\n1) Press the Yellow button.\n\n2) If a privacy notification pops up, allow access to camera, then point camera at the text you would like to have summarized.\n\n3) Take a picture of the text.\n\n4) Drag the corners and crop the image of the text you want summarized.\n\n5) Press Keep Scan once you are satisfied with the cropped image.\n\n6) Lastly, press save. You will then be taken back to the summary page and your summary will be processed.\n\n7) To learn about the developer and the concept behind the app, click on the About button.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Got it!", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
    @IBAction func scanReceipts(_ sender: UIControl?) {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }
    
}// End of VC

// MARK: VNDocumentCameraViewControllerDelegate
extension ViewController: VNDocumentCameraViewControllerDelegate {
    
    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // Clear any existing text.
        scannedTextView?.text = ""
        // Dismiss the document camera
        controller.dismiss(animated: true)
        
        textRecognitionQueue.async {
            self.resultingText = ""
            for pageIndex in 0 ..< scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                if let cgImage = image.cgImage {
                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    
                    do {
                        try requestHandler.perform(self.requests)
                    } catch {
                        print(error)
                    }
                }
                self.resultingText += "\n\n"
                self.resultingText = self.resultingText.replacingOccurrences(of: "\n", with: " ")
            }
            DispatchQueue.main.async {
                print(self.resultingText)
                self.scannedTextView.text = self.resultingText
                Reductio.summarize(text: self.resultingText, compression: 0.8) {(phrases) in
                    print(phrases)
                    self.summarizedTextView.text = phrases.reduce("") { $0 + $1 }
                }
            }
        }

    }
}
