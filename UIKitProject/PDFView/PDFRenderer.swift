//
//  PDFRenderer.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 27/12/25.
//

import WebKit
import UIKit

final class PDFRenderer: UIViewController {
    let webPreview: WKWebView = WKWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webPreview)
        
        webPreview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webPreview.topAnchor.constraint(equalTo: view.topAnchor),
            webPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        render()
    }
    
    func render() {
        guard let fileURL = Bundle.main.url(forResource: "dummy", withExtension: "html") else {
            print("Unable to load file")
            return
        }
        
        do {
            let fileData = try String(contentsOf: fileURL, encoding: .utf8)
            webPreview.loadHTMLString(fileData, baseURL: nil)
            
            PDFGenerator.generatePDF(from: fileData) { result in
                switch result {
                case .success(let url):
                    print("URL point: \(url)")
                case .failure(let error):
                    print("error: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Unable to read file")
        }
    }
}

final class PDFGenerator {
    static func generatePDF(from htmlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let printFormatter = UIMarkupTextPrintFormatter(markupText: htmlString)
        
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        let a4Size = CGSize(width: 595.2, height: 841.8)
        let printableRect = CGRect(origin: .zero, size: a4Size)
        let paperRect = CGRect(origin: .zero, size: a4Size)
        
        renderer.setValue(paperRect, forKey: "paperRect")
        renderer.setValue(printableRect, forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        
        UIGraphicsEndPDFContext()
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completion(.failure(NSError(domain: "PDFGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])))
            return
        }
        
        let fileName = "document_\(Date().timeIntervalSince1970).pdf"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            completion(.success(fileURL))
        } catch {
            completion(.failure(error))
        }
    }
}
