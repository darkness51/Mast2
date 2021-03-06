//
//  GSImageViewerController.swift
//  GSImageViewerControllerExample
//
//  Created by Gesen on 15/12/22.
//  Copyright © 2015年 Gesen. All rights reserved.
//

import UIKit
import ActiveLabel

public struct GSImageInfo {
    
    public enum ImageMode : Int {
        case aspectFit  = 1
        case aspectFill = 2
    }
    
    public let image     : UIImage
    public let imageMode : ImageMode
    public var imageHD   : URL?
    public var imageText : String? = ""
    public var imageText2 : Int? = 0
    public var imageText3 : Int? = 0
    public var imageText4 : String? = ""
    
    public var contentMode : UIView.ContentMode {
        return UIView.ContentMode(rawValue: imageMode.rawValue)!
    }
    
    public init(image: UIImage, imageMode: ImageMode) {
        self.image     = image
        self.imageMode = imageMode
    }
    
    public init(image: UIImage, imageMode: ImageMode, imageHD: URL?, imageText: String? = "", imageText2: Int? = 0, imageText3: Int? = 0, imageText4: String? = "") {
        self.init(image: image, imageMode: imageMode)
        self.imageHD = imageHD
        self.imageText = imageText
        self.imageText2 = imageText2
        self.imageText3 = imageText3
        self.imageText4 = imageText4
    }
    
    func calculate(rect: CGRect, origin: CGPoint? = nil, imageMode: ImageMode? = nil) -> CGRect {
        switch imageMode ?? self.imageMode {
            
        case .aspectFit:
            return rect
            
        case .aspectFill:
            let r = max(rect.size.width / image.size.width, rect.size.height / image.size.height)
            let w = image.size.width * r
            let h = image.size.height * r
            
            return CGRect(
                x      : origin?.x ?? rect.origin.x - (w - rect.width) / 2,
                y      : origin?.y ?? rect.origin.y - (h - rect.height) / 2,
                width  : w,
                height : h
            )
        }
    }
    
    func calculateMaximumZoomScale(_ size: CGSize) -> CGFloat {
        return max(2, max(
            image.size.width  / size.width,
            image.size.height / size.height
        ))
    }
    
}

open class GSTransitionInfo {
    
    open var duration: TimeInterval = 0.25
    open var canSwipe: Bool         = true
    
    public init(fromView: UIView) {
        self.fromView = fromView
    }
    
    public init(fromRect: CGRect) {
        self.convertedRect = fromRect
    }
    
    weak var fromView: UIView?
    
    fileprivate var fromRect: CGRect!
    fileprivate var convertedRect: CGRect!
    
}

open class GSImageViewerController: UIViewController {
    
    public let imageView  = UIImageView()
    public let scrollView = UIScrollView()

    public let detailView = UIButton()
    public let detailText = ActiveLabel()
    public let detailView2 = UIButton()
    
    public let imageInfo: GSImageInfo
    
    open var transitionInfo: GSTransitionInfo?
    
    open var dismissCompletion: (() -> Void)?
    
    open var backgroundColor: UIColor = .black {
        didSet {
            view.backgroundColor = backgroundColor
        }
    }
    
    open lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
    }()
    
    // MARK: Initialization
    
    public init(imageInfo: GSImageInfo) {
        self.imageInfo = imageInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    public convenience init(imageInfo: GSImageInfo, transitionInfo: GSTransitionInfo) {
        self.init(imageInfo: imageInfo)
        self.transitionInfo = transitionInfo
        
        if let fromView = transitionInfo.fromView, let referenceView = fromView.superview {
            transitionInfo.fromRect = referenceView.convert(fromView.frame, to: nil)
            
            if fromView.contentMode != imageInfo.contentMode {
                transitionInfo.convertedRect = imageInfo.calculate(
                    rect: transitionInfo.fromRect!,
                    imageMode: GSImageInfo.ImageMode(rawValue: fromView.contentMode.rawValue)
                )
            } else {
                transitionInfo.convertedRect = transitionInfo.fromRect
            }
        }
        
        if transitionInfo.convertedRect != nil {
            self.transitioningDelegate = self
            self.modalPresentationStyle = .overFullScreen
        }
    }
    
    public convenience init(image: UIImage, imageMode: UIView.ContentMode, imageHD: URL?, fromView: UIView?, imageText: String? = "", imageText2: Int? = 0, imageText3: Int? = 0, imageText4: String? = "") {
        let imageInfo = GSImageInfo(image: image, imageMode: GSImageInfo.ImageMode(rawValue: imageMode.rawValue)!, imageHD: imageHD, imageText: imageText, imageText2: imageText2, imageText3: imageText3, imageText4: imageText4)
        
        if let fromView = fromView {
            self.init(imageInfo: imageInfo, transitionInfo: GSTransitionInfo(fromView: fromView))
        } else {
            self.init(imageInfo: imageInfo)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Override
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScrollView()
        setupImageView()
        setupGesture()
        setupImageHD()
        
        edgesForExtendedLayout = UIRectEdge()
        automaticallyAdjustsScrollViewInsets = false
        
        UIApplication.shared.setStatusBarHidden(true, with: .fade)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.setStatusBarHidden(false, with: .fade)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        imageView.frame = imageInfo.calculate(rect: view.bounds, origin: .zero)
        
        scrollView.frame = view.bounds
        scrollView.contentSize = imageView.bounds.size
        scrollView.maximumZoomScale = imageInfo.calculateMaximumZoomScale(scrollView.bounds.size)
    }
    
    // MARK: Setups
    
    fileprivate func setupView() {
        view.backgroundColor = backgroundColor
    }
    
    fileprivate func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
    }
    
    @objc func viewTootTapped() {
        dismiss(animated: true, completion: {
            GlobalStruct.thePassedID = self.imageInfo.imageText4 ?? ""
            if GlobalStruct.currentTab == 1 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail1"), object: nil)
            }
            if GlobalStruct.currentTab == 2 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail2"), object: nil)
            }
            if GlobalStruct.currentTab == 3 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail3"), object: nil)
            }
            if GlobalStruct.currentTab == 4 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail4"), object: nil)
            }
            if GlobalStruct.currentTab == 5 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail5"), object: nil)
            }
            if GlobalStruct.currentTab == 999 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail6"), object: nil)
            }
            if GlobalStruct.currentTab == 998 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail7"), object: nil)
            }
            if GlobalStruct.currentTab == 997 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail8"), object: nil)
            }
            if GlobalStruct.currentTab == 996 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "openTootDetail9"), object: nil)
            }
        })
    }
    
    fileprivate func setupImageView() {
        imageView.image = imageInfo.image
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        
        detailView.layer.cornerRadius = 10
        if #available(iOS 13.0, *) {
            detailView.backgroundColor = UIColor(named: "darkGray")!
            detailView.layer.cornerCurve = .continuous
        }
        detailView.addTarget(self, action: #selector(self.viewTootTapped), for: .touchUpInside)
        self.view.addSubview(detailView)
        
        if #available(iOS 11.0, *) {
            detailText.frame = CGRect(x: 30, y: self.view.bounds.height - 60 - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0), width: self.view.bounds.width - 60, height: 50)
        }
        detailText.textAlignment = .left
        detailText.text = imageInfo.imageText
        detailText.textColor = UIColor.white
        detailText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        detailText.isUserInteractionEnabled = false
        detailText.numberOfLines = 8
        detailText.sizeToFit()
        if #available(iOS 13.0, *) {
            detailText.frame.origin.y = self.view.bounds.height - detailText.frame.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 5
        }
        detailText.enabledTypes = [.mention, .hashtag, .url]
        detailText.mentionColor = GlobalStruct.baseTint
        detailText.hashtagColor = GlobalStruct.baseTint
        detailText.URLColor = GlobalStruct.baseTint
        self.view.addSubview(detailText)
        
        detailView.frame = detailText.frame
        detailView.frame.size.width = self.view.bounds.width - 40
        detailView.frame.size.height = detailText.bounds.height + 16
        detailView.frame.origin.y = detailText.frame.origin.y - 8
        detailView.frame.origin.x = detailText.frame.origin.x - 10
        
        detailView2.layer.cornerRadius = 10
        if #available(iOS 13.0, *) {
            detailView2.backgroundColor = UIColor(named: "darkerGray")!
            detailView2.layer.cornerCurve = .continuous
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value: self.imageInfo.imageText2 ?? 0))
        let numberFormatter2 = NumberFormatter()
        numberFormatter2.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber2 = numberFormatter2.string(from: NSNumber(value: self.imageInfo.imageText3 ?? 0))
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 4, weight: .bold)
        let normalFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 2)
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "heart", withConfiguration: symbolConfig)?.withTintColor(UIColor.white.withAlphaComponent(0.35), renderingMode: .alwaysOriginal)
        let attachment2 = NSTextAttachment()
        attachment2.image = UIImage(systemName: "arrow.2.circlepath", withConfiguration: symbolConfig)?.withTintColor(UIColor.white.withAlphaComponent(0.35), renderingMode: .alwaysOriginal)
        let attStringNewLine = NSMutableAttributedString(string: "\(formattedNumber ?? "0")", attributes: [NSAttributedString.Key.font : normalFont, NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(1)])
        let attStringNewLine2 = NSMutableAttributedString(string: "\(formattedNumber2 ?? "0")", attributes: [NSAttributedString.Key.font : normalFont, NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(1)])
        let attString = NSAttributedString(attachment: attachment)
        let attString2 = NSAttributedString(attachment: attachment2)
        let fullString = NSMutableAttributedString(string: "")
        let spaceString0 = NSMutableAttributedString(string: " ")
        let spaceString = NSMutableAttributedString(string: "  ")
        fullString.append(attString)
        fullString.append(spaceString0)
        fullString.append(attStringNewLine)
        fullString.append(spaceString)
        fullString.append(attString2)
        fullString.append(spaceString0)
        fullString.append(attStringNewLine2)
        detailView2.setAttributedTitle(fullString, for: .normal)
        detailView2.contentHorizontalAlignment = .left
        detailView2.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        detailView2.sizeToFit()
        detailView2.frame.origin.y = detailView.frame.origin.y - detailView2.bounds.height - 10
        detailView2.frame.origin.x = detailView.frame.origin.x
        self.view.addSubview(detailView2)
        
        detailView.layer.shadowColor = UIColor(named: "alwaysBlack")!.cgColor
        detailView.layer.shadowOffset = CGSize(width: 0, height: 12)
        detailView.layer.shadowRadius = 12
        detailView.layer.shadowOpacity = 0.18
        
        detailView2.layer.shadowColor = UIColor(named: "alwaysBlack")!.cgColor
        detailView2.layer.shadowOffset = CGSize(width: 0, height: 12)
        detailView2.layer.shadowRadius = 12
        detailView2.layer.shadowOpacity = 0.18
        
        UIView.animate(withDuration: transitionInfo?.duration ?? 2, animations: {
            if self.imageInfo.imageText == "" {
                self.detailView.alpha = 0
                self.detailView2.alpha = 0
                self.detailText.alpha = 0
            } else {
                self.detailView.alpha = 1
                self.detailView2.alpha = 1
                self.detailText.alpha = 1
            }
        }, completion: { _ in
            
        })
    }
    
    fileprivate func setupGesture() {
        let single = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        let double = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        double.numberOfTapsRequired = 2
        single.require(toFail: double)
        scrollView.addGestureRecognizer(single)
        scrollView.addGestureRecognizer(double)
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.7
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        scrollView.addGestureRecognizer(lpgr)
        
        if transitionInfo?.canSwipe == true {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
            pan.delegate = self
            scrollView.addGestureRecognizer(pan)
        }
    }
    
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizer.State.began {
            UIView.animate(withDuration: 0.2,
                           animations: {
                            self.detailView.alpha = 0
                            self.detailView2.alpha = 0
                            self.detailText.alpha = 0
            },
                           completion: { _ in
                            
            }
            )

            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let op1 = UIAlertAction(title: "Share".localized, style: .default , handler:{ (UIAlertAction) in
                let imToShare = [self.imageView.image ?? UIImage()]
                let activityViewController = UIActivityViewController(activityItems: imToShare,  applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.imageView
                activityViewController.popoverPresentationController?.sourceRect = self.imageView.bounds
                self.present(activityViewController, animated: true, completion: nil)
                self.bringBackViews()
            })
            op1.setValue(UIImage(systemName: "square.and.arrow.up")!, forKey: "image")
            op1.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            alert.addAction(op1)
            let op2 = UIAlertAction(title: "Save".localized, style: .default , handler:{ (UIAlertAction) in
                UIImageWriteToSavedPhotosAlbum(self.imageView.image ?? UIImage(), nil, nil, nil)
                self.bringBackViews()
            })
            op2.setValue(UIImage(systemName: "square.and.arrow.down")!, forKey: "image")
            op2.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            alert.addAction(op2)
            alert.addAction(UIAlertAction(title: "Dismiss".localized, style: .cancel , handler:{ (UIAlertAction) in
                self.bringBackViews()
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self.imageView
                presenter.sourceRect = self.imageView.bounds
            }
            self.present(alert, animated: true, completion: nil)
        } else if gestureReconizer.state == UIGestureRecognizer.State.ended {
            
        } else {
            //When lognpress is finish
        }
    }
    
    func bringBackViews() {
        UIView.animate(withDuration: 0.2,
                       animations: {
                        self.detailView.alpha = 1
                        self.detailView2.alpha = 1
                        self.detailText.alpha = 1
        },
                       completion: { _ in
                        
        }
        )
    }
    
    fileprivate func setupImageHD() {
        guard let imageHD = imageInfo.imageHD else { return }
            
        let request = URLRequest(url: imageHD, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            guard let data = data else { return }
            guard let image = UIImage(data: data) else { return }
            self.imageView.image = image
            self.view.layoutIfNeeded()
        })
        task.resume()
    }
    
    // MARK: Gesture
    
    @objc fileprivate func singleTap() {
//        if navigationController == nil || (presentingViewController != nil && navigationController!.viewControllers.count <= 1) {
//            dismiss(animated: true, completion: dismissCompletion)
//        }
        
        if self.detailView.alpha == 1 {
            UIView.animate(withDuration: 0.14,
                           animations: {
                            self.detailView.alpha = 0
                            self.detailView2.alpha = 0
                            self.detailText.alpha = 0
            },
                           completion: { _ in
            })
        } else {
            UIView.animate(withDuration: 0.14,
                           animations: {
                            self.detailView.alpha = 1
                            self.detailView2.alpha = 1
                            self.detailText.alpha = 1
            },
                           completion: { _ in
            })
        }
        
    }
    
    @objc fileprivate func doubleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: scrollView)
        
        if scrollView.zoomScale == 1.0 {
            scrollView.zoom(to: CGRect(x: point.x-40, y: point.y-40, width: 80, height: 80), animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    fileprivate var panViewOrigin : CGPoint?
    fileprivate var panViewAlpha  : CGFloat = 1
    
    @objc fileprivate func pan(_ gesture: UIPanGestureRecognizer) {
        
        func getProgress() -> CGFloat {
            let origin = panViewOrigin!
            let changeX = abs(scrollView.center.x - origin.x)
            let changeY = abs(scrollView.center.y - origin.y)
            let progressX = changeX / view.bounds.width
            let progressY = changeY / view.bounds.height
            return max(progressX, progressY)
        }
        
        func getChanged() -> CGPoint {
            let origin = scrollView.center
            let change = gesture.translation(in: view)
            return CGPoint(x: origin.x + change.x, y: origin.y + change.y)
        }
        
        func getVelocity() -> CGFloat {
            let vel = gesture.velocity(in: scrollView)
            return sqrt(vel.x*vel.x + vel.y*vel.y)
        }
        
        switch gesture.state {

        case .began:
            
            panViewOrigin = scrollView.center
            
            UIView.animate(withDuration: 0.2,
                           animations: {
                            self.detailView.alpha = 0
                            self.detailView2.alpha = 0
                            self.detailText.alpha = 0
            },
                           completion: { _ in
                            
            }
            )
            
        case .changed:
            
            scrollView.center = getChanged()
            panViewAlpha = 1 - getProgress()
            view.backgroundColor = backgroundColor.withAlphaComponent(panViewAlpha)
            gesture.setTranslation(CGPoint.zero, in: nil)
        
        case .ended:
            
            if getProgress() > 0.25 || getVelocity() > 1000 {
                dismiss(animated: true, completion: dismissCompletion)
            } else {
                fallthrough
            }
            
        default:
            
            UIView.animate(withDuration: 0.25,
                animations: {
                    self.scrollView.center = self.panViewOrigin!
                    self.view.backgroundColor = self.backgroundColor

                    self.detailView.alpha = 1
                    self.detailView2.alpha = 1
                    self.detailText.alpha = 1
                },
                completion: { _ in
                    self.panViewOrigin = nil
                    self.panViewAlpha  = 1.0
                }
            )
            
        }
    }
    
}

extension GSImageViewerController: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.frame = imageInfo.calculate(rect: CGRect(origin: .zero, size: scrollView.contentSize), origin: .zero)
    }
    
}

extension GSImageViewerController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return GSImageViewerTransition(imageInfo: imageInfo, transitionInfo: transitionInfo!, transitionMode: .present)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return GSImageViewerTransition(imageInfo: imageInfo, transitionInfo: transitionInfo!, transitionMode: .dismiss)
    }
    
}

class GSImageViewerTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let imageInfo      : GSImageInfo
    let transitionInfo : GSTransitionInfo
    var transitionMode : TransitionMode
    
    enum TransitionMode {
        case present
        case dismiss
    }
    
    init(imageInfo: GSImageInfo, transitionInfo: GSTransitionInfo, transitionMode: TransitionMode) {
        self.imageInfo = imageInfo
        self.transitionInfo = transitionInfo
        self.transitionMode = transitionMode
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionInfo.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        let tempBackground = UIView()
            tempBackground.backgroundColor = UIColor.black
        
        let tempMask = UIView()
            tempMask.backgroundColor = .black
            tempMask.layer.cornerRadius = transitionInfo.fromView?.layer.cornerRadius ?? 0
            tempMask.layer.masksToBounds = transitionInfo.fromView?.layer.masksToBounds ?? false
        
        let tempImage = UIImageView(image: imageInfo.image)
            tempImage.contentMode = imageInfo.contentMode
            tempImage.mask = tempMask
        
        containerView.addSubview(tempBackground)
        containerView.addSubview(tempImage)
        
        if transitionMode == .present {
            let imageViewer = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as! GSImageViewerController
                imageViewer.view.layoutIfNeeded()
            
            tempBackground.alpha = 0
            tempBackground.frame = imageViewer.view.bounds
            tempImage.frame = transitionInfo.convertedRect
            tempMask.frame = tempImage.convert(transitionInfo.fromRect, from: nil)
            
            transitionInfo.fromView?.alpha = 0
            
            UIView.animate(withDuration: transitionInfo.duration, animations: {
                tempBackground.alpha  = 1
                tempImage.frame = imageViewer.imageView.frame
                tempMask.frame = tempImage.bounds
            }, completion: { _ in
                tempBackground.removeFromSuperview()
                tempImage.removeFromSuperview()
                containerView.addSubview(imageViewer.view)
                transitionContext.completeTransition(true)
            })
        }
        
        else if transitionMode == .dismiss {
            let imageViewer = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as! GSImageViewerController
                imageViewer.view.removeFromSuperview()
            
            tempBackground.alpha = imageViewer.panViewAlpha
            tempBackground.frame = imageViewer.view.bounds
            
            if imageViewer.scrollView.zoomScale == 1 && imageInfo.imageMode == .aspectFit {
                tempImage.frame = imageViewer.scrollView.frame
            } else {
                tempImage.frame = CGRect(x: imageViewer.scrollView.contentOffset.x * -1, y: imageViewer.scrollView.contentOffset.y * -1, width: imageViewer.scrollView.contentSize.width, height: imageViewer.scrollView.contentSize.height)
            }
            
            tempMask.frame = tempImage.bounds
            
            UIView.animate(withDuration: transitionInfo.duration, animations: {
                tempBackground.alpha = 0
                tempImage.frame = self.transitionInfo.convertedRect
                tempMask.frame = tempImage.convert(self.transitionInfo.fromRect, from: nil)
            }, completion: { _ in
                tempBackground.removeFromSuperview()
                tempImage.removeFromSuperview()
                imageViewer.view.removeFromSuperview()
                self.transitionInfo.fromView?.alpha = 1
                transitionContext.completeTransition(true)
            })
        }
    }
}

extension GSImageViewerController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            if scrollView.zoomScale != 1.0 {
                return false
            }
            if imageInfo.imageMode == .aspectFill && (scrollView.contentOffset.x > 0 || pan.translation(in: view).x <= 0) {
                return false
            }
        }
        return true
    }
    
}
