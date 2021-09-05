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
        setupVision()
    }
    
    // MARK: - Actions
    // Instructions for user on how to use app
    @IBAction func userGuide(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Welcome to TL;DR!\n\n", message: "TL;DR is a text summarizer that leverages NLP and your camera to scan text and produce a summary of that text.\n\nHere is how to use TL;DR:\n\n1) Press the 'Start Here' button.\n\n2) If a privacy notification pops up, allow access to camera, then point camera at the text you would like to have summarized.\n\n3) Press the center circle button to take a picture of the text.\n\n4) Drag the corners and crop the image of the text you want summarized.\n\n5) Press 'Keep Scan' once you are satisfied with the cropped image. **NOTE: You can scan multiple times/pages\n\n6) Lastly, press 'Save'. Please note that this does NOT save to your device. You will then be taken back to the summary page and your summary will be processed.\n\n7) To learn a little about the developer and the concept behind the app, click on the 'About' button.\n\n8) You can use the buttons or swipe to return to previous screen.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Goodbye!", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // About me and the concepts behind the app
    @IBAction func aboutMe(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Thank you for downloading TL;DR!\n\n", message: "When I made this, I was a junior in college, attending Dakota State University, majoring in Computer Science. I made this as a project for my Machine Learning Fundamentals class.\n\n This is a text summarizer app that utilizes the Apple Vision framework to identify text using your camera. The text summarization utilizes the Reductio library by fdzsergio. Reductio uses the TextRank algorithm to provide an extractive summary of the text.\n\n There are 2 types of summaries in Natural Language Processing(NLP): extractive and abstractive. An extractive summary is an NLP concept that means the text being summarized uses sentences from the text to make up the summary. Extractive summaries are still in their infancy and may not give you the best results every time; they aren't perfect. An abstractive summary attempts to create its own sentences from the text. These can be even less accurate than extractive summaries.\n\n Please understand that this will NOT always return a perfect summary. The technology isn't quite there yet, but it does a pretty decent job with what we have currently. Keep this in mind when using the app.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Gotcha!", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    // User scan button
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
