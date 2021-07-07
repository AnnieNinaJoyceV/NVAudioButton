//
//  NVCommeners.swift
//  NVAudioButton
//
//  Created by Joyce on 14/05/21.
//

import UIKit

struct NVCommoners {
	static
	func createRingLayer(withCenter center: CGPoint, radius: CGFloat, lineWidth aLineWidth: CGFloat, color: UIColor?, lineWidth: CGFloat) -> CAShapeLayer? {
		let smoothedPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -CGFloat.pi/2, endAngle: CGFloat.pi + CGFloat.pi/2, clockwise: true)
		let shapeLayer = CAShapeLayer()
		shapeLayer.contentsScale = UIScreen.main.scale
		shapeLayer.frame = CGRect(x: center.x - radius - lineWidth / 2,
								  y: center.y - radius - lineWidth / 2,
								  width: radius * 2 + lineWidth,
								  height: radius * 2 + lineWidth)
		shapeLayer.fillColor = UIColor.clear.cgColor
		shapeLayer.strokeColor = color?.cgColor
		shapeLayer.lineWidth = aLineWidth
		shapeLayer.lineJoin = .round
		shapeLayer.path = smoothedPath.cgPath
		
		return shapeLayer
	}
	
	static
	func createRoundRectLayer(with rect: CGRect, cornerRadius: CGFloat, lineWidth aLineWidth: CGFloat, color: UIColor?) -> CAShapeLayer? {
		let smoothedPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
		let shapeLayer = CAShapeLayer()
		shapeLayer.contentsScale = UIScreen.main.scale
		shapeLayer.frame = CGRect(x: rect.origin.x - aLineWidth / 2, y: rect.origin.y - aLineWidth / 2, width: rect.size.width + aLineWidth, height: rect.size.height + aLineWidth)
		shapeLayer.fillColor = UIColor.clear.cgColor
		shapeLayer.strokeColor = color?.cgColor
		shapeLayer.lineWidth = aLineWidth
		shapeLayer.lineJoin = .round
		shapeLayer.path = smoothedPath.cgPath
		
		return shapeLayer
	}
	
	static
	func createCircleLayerInclude(_ rect: CGRect, cornerRadius: CGFloat, lineWidth aLineWidth: CGFloat, color: UIColor?) -> CAShapeLayer? {
		
		let smallRadius = (min(rect.size.width, rect.size.height) - aLineWidth) / 2
		let powWidth2 = pow( (rect.size.width + aLineWidth) / 2, 2)
		let powHeight2 = pow( (rect.size.height + aLineWidth) / 2, 2)
		let largeRadius: CGFloat = sqrt(powWidth2 + powHeight2)
		let radius: CGFloat = (smallRadius + largeRadius) / 2
		let tempLineWidth: CGFloat = largeRadius - smallRadius
		
		let smoothedPath = UIBezierPath(arcCenter: CGPoint(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y + rect.size.height / 2), radius: radius, startAngle: -CGFloat.pi / 2, endAngle: .pi + CGFloat.pi / 2, clockwise: true)
		let shapeLayer = CAShapeLayer()
		shapeLayer.contentsScale = UIScreen.main.scale
		shapeLayer.frame = CGRect(x: rect.origin.x - aLineWidth / 2, y: rect.origin.y - aLineWidth / 2, width: rect.size.width + aLineWidth, height: rect.size.height + aLineWidth)
		
		shapeLayer.fillColor = UIColor.clear.cgColor
		shapeLayer.strokeColor = color?.cgColor
		shapeLayer.lineWidth = tempLineWidth
		shapeLayer.lineJoin = .round
		shapeLayer.path = smoothedPath.cgPath
		
		return shapeLayer
	}
}
