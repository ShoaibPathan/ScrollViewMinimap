//
//  Copyright © 2020 Dominic Elayda.
//  Licensed under The MIT License.
//

import UIKit

class MinimapViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var minimap: ScrollViewMinimap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScrollView()
        setupImageView()
        setupMinimap()
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 8.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
    }
    
    private func setupImageView() {
        guard let image = UIImage(named: "Building") else { return }
        let aspectRatio = image.size.width / image.size.height
        imageView.image = image
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspectRatio).isActive = true
    }

    private func setupMinimap() {
        minimap.scrollView = scrollView
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.minimap.setNeedsDisplay()
        }
    }
}

// MARK: - UIScrollViewDelegate

extension MinimapViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        minimap.setNeedsUpdateConstraints()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        minimap.setNeedsUpdateConstraints()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
}

// MARK: - Live Preview

import SwiftUI

@available(iOS 13, *)
struct MinimapViewControllerRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> MinimapViewController {
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MinimapViewController")
    }
    
    func updateUIViewController(_ uiViewController: MinimapViewController, context: Context) { }
    
}

@available(iOS 13, *)
struct ViewController_Preview: PreviewProvider {

    static var devices = ["iPhone 12 Pro"]

    static var previews: some View {
        ForEach(devices, id: \.self) { deviceName in
            MinimapViewControllerRepresentable()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
    }
}
