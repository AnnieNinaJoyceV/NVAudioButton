//
//  NVProgressLayers.swift
//  NVAudioButton
//
//  Created by Joyce on 14/05/21.
//

import Foundation
import UIKit

enum NVProgressLayersShape {
	case circle
	case rectangle
}

protocol NVProgressLayersDelegate: NSObject {
	func currentProgress() -> CGFloat
	func currentCornerRadius(_ radius: CGFloat)
}

final class NVProgressLayers: NSObject {
	var progress: CGFloat = 0.0 {
		didSet {
			self.progressLayer?.strokeEnd = (progress * 100).rounded() / 100
		}
	}
	weak var delegate: NVProgressLayersDelegate?
	
	public var backColor: UIColor? = .red {
		didSet {
			drawLayers()
		}
	}
	public var progressColor: UIColor? = .orange {
		didSet {
			drawLayers()
		}
	}
	
	private var displayLink: CADisplayLink?
	private var progressLayer: CAShapeLayer?
	private var backgroundLayer: CAShapeLayer?
	private var loadingLayer: CAShapeLayer?
	
	public var view: UIView? = nil {
		didSet {
			drawLayers()
		}
	}
	
	public var progressShape: NVProgressLayersShape = .rectangle {
		didSet {
			drawLayers()
		}
	}
	
	public var lineWidth: CGFloat = 2.0 {
		didSet {
			drawLayers()
		}
	}
	
	private
	func drawLayers() {
		
		backgroundLayer?.removeFromSuperlayer()
		progressLayer?.removeFromSuperlayer()
		loadingLayer?.removeFromSuperlayer()
		
		guard let view = view else { return }
		switch progressShape {
			case .circle:
				let radi = shapeForCircle(view: view)
				let cRadi = radi + lineWidth / 2
				delegate?.currentCornerRadius(cRadi)
				break
			case .rectangle:
				let radi = shapeForRectangle(view: view)
				delegate?.currentCornerRadius(radi)
				break
		}
		
		guard
			let backgroundLayer = backgroundLayer,
			let progressLayer = progressLayer,
			let loadingLayer = loadingLayer
		else {
			return
		}
		view.layer.addSublayer(backgroundLayer)
		progressLayer.strokeEnd = 0
		view.layer.addSublayer(progressLayer)
		loadingLayer.strokeEnd = 1
		loadingLayer.isHidden = true
		view.layer.addSublayer(loadingLayer)
		
		addStrokeAnimation()
	}
	
	private
	func shapeForCircle(view: UIView) -> CGFloat {
		let center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
		let radius: CGFloat = (view.bounds.width - lineWidth) / 2

		backgroundLayer = NVCommoners.createRingLayer(withCenter: center, radius: radius, lineWidth: lineWidth, color: backColor, lineWidth: lineWidth)
		progressLayer = NVCommoners.createRingLayer(withCenter: center, radius: radius, lineWidth: lineWidth, color: progressColor, lineWidth: lineWidth)
		loadingLayer = NVCommoners.createRingLayer(withCenter: center, radius: radius, lineWidth: lineWidth, color: progressColor, lineWidth: lineWidth)
		return radius
	}
	
	private
	func shapeForRectangle(view: UIView) -> CGFloat {
		
		let tempWidth: CGFloat = view.frame.width - lineWidth
		let tempHeight: CGFloat = view.frame.height - lineWidth
		var tempCornerRadius: CGFloat = min(tempWidth, tempHeight) / 6
		if (lineWidth * 2 < tempCornerRadius) {
			tempCornerRadius = lineWidth * 2
		}
		let rect: CGRect = CGRect(x: lineWidth / 2, y: lineWidth / 2, width: tempWidth, height: tempHeight)
				
		backgroundLayer = NVCommoners.createRoundRectLayer(with: rect, cornerRadius: tempCornerRadius, lineWidth: lineWidth, color: backColor)
		progressLayer = NVCommoners.createRoundRectLayer(with: rect, cornerRadius: tempCornerRadius, lineWidth: lineWidth, color: progressColor)
		loadingLayer = NVCommoners.createCircleLayerInclude(rect, cornerRadius: tempCornerRadius, lineWidth: lineWidth, color: progressColor)
		backgroundLayer?.mask = NVCommoners.createRoundRectLayer(with: rect, cornerRadius: tempCornerRadius, lineWidth: lineWidth, color: .clear)
		
		return tempCornerRadius
	}
	
	private
	func addStrokeAnimation() {
		let animation = CABasicAnimation(keyPath: "strokeEnd")
		animation.fromValue = 0.0
		animation.toValue = 1.0
		animation.duration = 2.0
		animation.fillMode = .forwards
		animation.isRemovedOnCompletion = false
		animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
		loadingLayer?.add(animation, forKey: nil)
	}
	
	func stopLoading() {
		guard let loadingLayer = loadingLayer,
			  !loadingLayer.isHidden
		else { return }
		loadingLayer.isHidden = true
	}
	
	@objc
	func updateProgress() {
		//update progress value
		if let prog = delegate?.currentProgress() {
			progress = prog
		}
	}
	
	func play() {
		stopLoading()
		progressLayer?.isHidden = false
		
		if displayLink == nil {
			displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
			displayLink?.preferredFramesPerSecond = 60
			displayLink?.add(to: .current, forMode: .common)
		} else {
			displayLink?.isPaused = false
		}
	}
	
	func pause() {
		stopLoading()
		displayLink?.isPaused = true
	}
	
	func stop() {
		stopLoading()
		displayLink?.invalidate()
		displayLink = nil
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
			self.progress = 0.0
			self.progressLayer?.isHidden = true
		}
	}
}
