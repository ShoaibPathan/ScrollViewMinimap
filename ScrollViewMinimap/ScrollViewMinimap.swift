//
//  Copyright © 2020 Dominic Elayda.
//  Licensed under The MIT License.
//

import UIKit

open class ScrollViewMinimap: UIControl {
    
    public weak var scrollView: UIScrollView? {
        didSet {
            imageView.image = scrollView?.contentViewThumbnailImage()
            setNeedsUpdateConstraints()
        }
    }
    
    // MARK: - Image View
    
    private let imageView = UIImageView()
    
    private lazy var imageViewAspectRatioConstraint: NSLayoutConstraint = {
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
    }()
    
    // MARK: - Highlight View
    
    private let highlightView = UIView()
    
    private lazy var highlightViewTopConstraint: NSLayoutConstraint = {
        highlightView.topAnchor.constraint(equalTo: topAnchor)
    }()
    
    private lazy var highlightViewLeftConstraint: NSLayoutConstraint = {
        highlightView.leftAnchor.constraint(equalTo: leftAnchor)
    }()
    
    private lazy var highlightViewWidthConstraint: NSLayoutConstraint = {
        highlightView.widthAnchor.constraint(equalToConstant: frame.width)
    }()
    
    private lazy var highlightViewHeightConstraint: NSLayoutConstraint = {
        highlightView.heightAnchor.constraint(equalToConstant: frame.height)
    }()
    
    private var highlightViewSize: CGSize {
        CGSize(width: min(frame.width, frame.width / zoomScale * minimumZoomScale),
               height: min(frame.height, frame.height / zoomScale * minimumZoomScale))
    }
    
    private var scrollableArea: CGSize {
        CGSize(width: frame.width - highlightViewSize.width,
               height: frame.height - highlightViewSize.height)
    }
    
    // MARK: - UIView
    
    public override var bounds: CGRect {
        didSet {
            setNeedsUpdateConstraints()
            setNeedsDisplay()
        }
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let scrollView = scrollView else { return }
        imageView.image = scrollView.contentViewThumbnailImage()
    }
    
    public override func updateConstraints() {
        let leftOffset = (contentInset.left + contentOffset.x) / (zoomScale * scrollViewWidthScale) * minimumZoomScale
        let topOffset = (contentInset.top + contentOffset.y) / (zoomScale * scrollViewHeightScale) * minimumZoomScale
        
        if let scrollView = scrollView, imageViewAspectRatioConstraint.multiplier != scrollView.contentSizeAspectRatio {
            imageView.removeConstraint(imageViewAspectRatioConstraint)
            imageViewAspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: scrollView.contentSizeAspectRatio)
            imageViewAspectRatioConstraint.isActive = true
        }
        
        highlightViewLeftConstraint.constant = min(max(0, leftOffset), scrollableArea.width)
        highlightViewTopConstraint.constant = min(max(0, topOffset), scrollableArea.height)
        highlightViewWidthConstraint.constant = highlightViewSize.width
        highlightViewHeightConstraint.constant = highlightViewSize.height

        super.updateConstraints()
    }
    
    // MARK: - Initializers
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupSubviews()
        setupGestureRecognizers()
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageViewAspectRatioConstraint,
        ])
        
        addSubview(highlightView)
        highlightView.layer.borderColor = UIColor.red.cgColor
        highlightView.layer.borderWidth = 2
        
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            highlightViewTopConstraint,
            highlightViewLeftConstraint,
            highlightViewWidthConstraint,
            highlightViewHeightConstraint,
        ])
    }
    
    private func setupGestureRecognizers() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        highlightView.addGestureRecognizer(panGestureRecognizer)
    }
 
    // MARK: - Gesture recognizers

    private var lastKnownContentOffset: CGPoint = CGPoint.zero

    @objc
    private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            lastKnownContentOffset = contentOffset
        }
        
        let translationPoint = gestureRecognizer.translation(in: self)
        let contentViewToMinimapScaleFactor = CGPoint(x: scrollViewWidthScale * (zoomScale / minimumZoomScale),
                                                      y: scrollViewHeightScale * (zoomScale / minimumZoomScale))
        let scaledTranslationPoint = CGPoint(x: translationPoint.x * contentViewToMinimapScaleFactor.x,
                                             y: translationPoint.y * contentViewToMinimapScaleFactor.y)
        
        guard let scrollView = scrollView else { return }
        let maxXContentOffset = max(scrollView.contentInset.left + scrollView.contentSize.width - (highlightViewSize.width * contentViewToMinimapScaleFactor.x), 0)
        let maxYContentOffset = max(scrollView.contentInset.top + scrollView.contentSize.height - (highlightViewSize.height * contentViewToMinimapScaleFactor.y), 0)
        scrollView.contentOffset = CGPoint(x: min(max(-scrollView.contentInset.left, lastKnownContentOffset.x + scaledTranslationPoint.x), maxXContentOffset),
                                           y: min(max(-scrollView.contentInset.top, lastKnownContentOffset.y + scaledTranslationPoint.y), maxYContentOffset))
    }
    
}

private extension ScrollViewMinimap {
    
    var contentInset: UIEdgeInsets {
        guard let scrollView = scrollView else { return UIEdgeInsets.zero }
        return scrollView.contentInset
    }
    
    var contentOffset: CGPoint {
        guard let scrollView = scrollView else { return CGPoint.zero }
        return scrollView.contentOffset
    }
    
    var zoomScale: CGFloat {
        guard let scrollView = scrollView else { return 1 }
        return scrollView.zoomScale
    }
    
    var minimumZoomScale: CGFloat {
        guard let scrollView = scrollView else { return 1 }
        return scrollView.minimumZoomScale
    }
    
    // Minimap width scale relative to managed UIScrollView's width
    var scrollViewWidthScale: CGFloat {
        guard let scrollView = scrollView else { return 1 }
        return scrollView.frame.width / frame.width
    }
    
    // Minimap height scale relative to managed UIScrollView's height
    var scrollViewHeightScale: CGFloat {
        guard let scrollView = scrollView else { return 1 }
        return scrollView.frame.height / frame.height
    }
    
}

private extension UIScrollView {
    
    var contentSizeAspectRatio: CGFloat {
        guard contentSize.height != 0 else { return 1 }
        return contentSize.width / contentSize.height
    }
    
    var trueContentSize: CGSize {
        CGSize(width: contentSize.width / zoomScale,
               height: contentSize.height / zoomScale)
    }
    
    func contentViewThumbnailImage() -> UIImage? {
        let oldZoomScale = zoomScale
        let oldOrigin = bounds.origin
        
        setZoomScale(minimumZoomScale, animated: false)
        bounds.origin = .zero
        
        let boundsAspectRatio = bounds.width / bounds.height
        let contentAspectRatio = contentSizeAspectRatio
        
        var contentSize = bounds.size
        if (boundsAspectRatio < contentAspectRatio) {
            contentSize.height = contentSize.height / contentAspectRatio * boundsAspectRatio
        } else {
            contentSize.width = contentSize.width / boundsAspectRatio * contentAspectRatio
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: contentSize))
        let image = renderer.image { context in
            layer.render(in: context.cgContext)
        }
        
        setZoomScale(oldZoomScale, animated: false)
        bounds.origin = oldOrigin
        
        return image
    }
    
}
