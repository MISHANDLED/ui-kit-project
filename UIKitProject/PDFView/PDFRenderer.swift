//
//  PDFRenderer.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 27/12/25.
//

import WebKit
import UIKit

protocol PDFRendererViewDataSource: BaseViewModel {
    var htmlString: String? { get }
    var onHTMLLoaded: ((String) -> Void)? { get set }
    var onRenderCompleted: ((Result<URL, Error>) -> Void)? { get set }
    func render()
}

final class PDFRendererViewModel: PDFRendererViewDataSource {
    var onHTMLLoaded: ((String) -> Void)?
    var onRenderCompleted: ((Result<URL, Error>) -> Void)?
    private(set) var htmlString: String?
    
    func viewDidLoad() {
        render()
    }
    
    func render() {
        guard let fileURL = Bundle.main.url(forResource: "dummy", withExtension: "html") else {
            print("Unable to load file")
            return
        }
        
        do {
            let fileData = try String(contentsOf: fileURL, encoding: .utf8)
            htmlString = fileData
            onHTMLLoaded?(fileData)
            
            PDFGenerator.generatePDF(from: fileData) { [weak self] result in
                self?.onRenderCompleted?(result)
            }
        } catch {
            print("Unable to read file")
        }
    }
}

final class PDFRendererView<VM: PDFRendererViewDataSource>: UIView {
    let webPreview: WKWebView = WKWebView()
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(webPreview)
        
        webPreview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webPreview.leadingAnchor.constraint(equalTo: leadingAnchor),
            webPreview.topAnchor.constraint(equalTo: topAnchor),
            webPreview.trailingAnchor.constraint(equalTo: trailingAnchor),
            webPreview.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension PDFRendererView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {
        if let htmlString = viewModel.htmlString {
            webPreview.loadHTMLString(htmlString, baseURL: nil)
        }
    }
}

@MainActor
func makePDFRenderer() -> UIViewController {
    let contentView = PDFRendererView<PDFRendererViewModel>()
    let viewModel = PDFRendererViewModel()
    
    viewModel.onHTMLLoaded = { [weak contentView] htmlString in
        contentView?.webPreview.loadHTMLString(htmlString, baseURL: nil)
    }
    viewModel.onRenderCompleted = { result in
        switch result {
        case .success(let url):
            print("URL point: \(url)")
        case .failure(let error):
            print("error: \(error.localizedDescription)")
        }
    }
    
    return BaseViewController(contentView: contentView, viewModel: viewModel)
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
