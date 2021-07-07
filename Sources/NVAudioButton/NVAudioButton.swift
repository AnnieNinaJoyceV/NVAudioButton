//
//  NVAudioButton.swift
//  NVAudioButton
//
//  Created by Joyce on 14/05/21.
//

import UIKit
import AVKit

enum NVAudioButtonState {
	case idle
	case loading
	case playing
	case failed
}

public class NVAudioButton: UIButton, NVProgressLayersDelegate, AVAudioPlayerDelegate, NVAudioSessionConfigDelegate {
	
	func currentCornerRadius(_ radius: CGFloat) {
		backgroundCornRadius = radius
	}
	
	func currentProgress() -> CGFloat {
		if let player = player, player.currentTime <= player.duration {
			let process = player.currentTime / player.duration
			return CGFloat(process < -0.1 ? 0.0 : process)
		} else {
			return 0.0
		}
	}
	
	//***************----------------****************//
	
	private let imageCache = NSCache<NSString, UIImage>()
	private var player: AVAudioPlayer?
	private var progressLayers: NVProgressLayers?
	private var playState: NVAudioButtonState?
	private var backgroundCornRadius: CGFloat = 0.0 {
		didSet {
			self.layer.cornerRadius = backgroundCornRadius
			setNeedsDisplay()
		}
	}
	private var eclipseRect = CGRect.zero
	private var stopRect = CGRect.zero
	private var topPoint = CGPoint.zero
	private var rightPoint = CGPoint.zero
	private var bottomPoint = CGPoint.zero
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonSetup()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonSetup()
	}
	
	deinit {
		if player != nil {
			player?.stop()
			player = nil
		}
		NVAudioSessionConfig.instanceVar?.unregisterAudioSessionNotification(for: self)
	}
	
	public var artWork: UIImage? {
		didSet {
			setNeedsDisplay()
		}
	}
	
	public var artworkURL: URL? {
		didSet {
			loadImageUsingCache(withUrl: artworkURL)
		}
	}
	
	public var lineWidth: CGFloat = 2.0 {
		didSet {
			self.progressLayers?.lineWidth = lineWidth
			setNeedsDisplay()
		}
	}
	
	public var shape: NVProgressLayersShape = .rectangle {
		didSet {
			self.progressLayers?.progressShape = shape
			setNeedsDisplay()
		}
	}
	
	public var progressColor: UIColor = .systemGray {
		didSet {
			self.progressLayers?.progressColor = progressColor
			setNeedsDisplay()
		}
	}
	
	public var controlsBackgroundColor: UIColor = .white {
		didSet {
			setNeedsDisplay()
		}
	}
	
	public var controlsColor: UIColor = .systemGray {
		didSet {
			setNeedsDisplay()
		}
	}
	
	public var controlRatio: CGFloat = 1.0 {
		didSet {
			updateFrame()
		}
	}
	
	public var audioUrl: URL? {
		didSet {
			playState = .loading
			if let player = player {
				if player.isPlaying {
					stop()
				}
				self.player = nil
			}
			guard let audioURL = audioUrl else { return }
			do {
				do {
					player = try AVAudioPlayer(contentsOf: audioURL)
				} catch {
					let data = try Data(contentsOf: audioURL)
					player = try AVAudioPlayer(data: data)
				}
				player?.numberOfLoops = 0
				player?.volume = 1.0
				player?.delegate = self
				player?.prepareToPlay()
				playState = .idle
			}
			catch {
				print(error.localizedDescription)
				playState = .failed
			}
		}
	}
	
	private
	func updateFrame() {
		
		let const618: CGFloat = 309 / 500
		let const866: CGFloat = 433 / 500
		let const667: CGFloat = 333.5 / 500
		
		let diameter: CGFloat = min(frame.size.height, frame.size.width) * const618 * controlRatio
		eclipseRect = CGRect(x: (frame.size.width - diameter) / 2,
							 y: (frame.size.height - diameter) / 2,
							 width: diameter,
							 height: diameter)
		
		let side: CGFloat = diameter * const618
		let leftX: CGFloat = eclipseRect.origin.x + (diameter - const866 * side) * const667
		let topY: CGFloat = eclipseRect.origin.y + (diameter - side) / 2
		let bottomY: CGFloat = eclipseRect.origin.y + (diameter + side) / 2
		let rightX: CGFloat = leftX + const866 * side
		let middleY: CGFloat = eclipseRect.origin.y + diameter / 2
		topPoint = CGPoint(x: leftX, y: topY)
		rightPoint = CGPoint(x: rightX, y: middleY)
		bottomPoint = CGPoint(x: leftX, y: bottomY)
		
		stopRect = CGRect(x: eclipseRect.origin.x + diameter / 4,
						  y: eclipseRect.origin.y + diameter / 4,
						  width: diameter / 2,
						  height: diameter / 2)
		
		if self.progressLayers?.view == nil, frame != .zero {
			self.progressLayers?.view = self
		}
		
		setNeedsDisplay()
	}
	
	private
	func commonSetup() {
		self.backgroundColor = .clear
		self.clipsToBounds = true
		
		self.playState = .idle
		self.addTarget(self, action: #selector(buttonTouched), for: .touchUpInside)
		//
		self.progressLayers = NVProgressLayers()
		self.progressLayers?.delegate = self
		self.progressLayers?.progressShape = shape
		self.progressLayers?.lineWidth = lineWidth
		self.progressLayers?.backColor = backgroundColor
		self.progressLayers?.progressColor = progressColor
		//configure audio session, register notification for handleRouteChange.
		NVAudioSessionConfig.instanceVar?.registerAudioSessionNotification(for: self)
	}
	
	private
	func loadImageUsingCache(withUrl url : URL?) {
		guard let url = url else { return }
		self.artWork = nil
		
		// check cached image
		if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString)  {
			self.artWork = cachedImage
			return
		}
		
		let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
		addSubview(activityIndicator)
		activityIndicator.startAnimating()
		activityIndicator.center = self.center
		
		// if not, download image from url
		URLSession.shared.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
			guard let self = self, error == nil, let data = data else {
				return
			}
			DispatchQueue.main.async {
				if let image = UIImage(data: data) {
					self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
					self.artWork = image
					activityIndicator.removeFromSuperview()
				}
			}
			
		}).resume()
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		if stopRect == .zero {
			updateFrame()
		}
	}
	
	public override func draw(_ rect: CGRect) {
		super.draw(rect)
		guard let ctx = UIGraphicsGetCurrentContext() else { return }
		
		backgroundColor?.setFill()
		let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: backgroundCornRadius)
		path.fill()
		
		if let image = artWork {
			let spacing: CGFloat = 5 + lineWidth
			let drawingRect = self.bounds.inset(by: UIEdgeInsets.init(top: spacing, left: spacing, bottom: spacing, right: spacing))
			image.draw(in: drawingRect)
		}
		
		controlsBackgroundColor.setFill()
		let path1 = UIBezierPath(roundedRect: self.eclipseRect, cornerRadius: self.eclipseRect.height / 2.0)
		path1.fill()
		
		ctx.setFillColor(controlsColor.cgColor)
		ctx.setLineWidth(1.0)
		
		switch playState {
			case .idle:
				ctx.move(to: topPoint)
				ctx.addLine(to: rightPoint)
				ctx.addLine(to: bottomPoint)
				ctx.closePath()
				ctx.fillPath()
				break
			default:
				ctx.fill(stopRect)
				break
		}
	}
	
	@objc
	func buttonTouched() {
		guard player != nil else {
			return
		}
		switch playState {
			case .idle:
				let _ = play()
				break
			case .playing:
				stop()
				break
			default:
				break
		}
	}
	
	func play() -> Bool {
		if let player = player, player.play() {
			progressLayers?.play()
			playState = .playing
			setNeedsDisplay()
			return true
		}
		return false
	}
	
	func stop() {
		if let player = player {
			player.stop()
			player.currentTime = 0.0
			progressLayers?.stop()
			playState = .idle
			setNeedsDisplay()
		}
	}
	
	func handleRouteChange(_ notification: Notification?) {
		let reasonValue: AVAudioSession.RouteChangeReason = notification?.userInfo?[AVAudioSessionRouteChangeReasonKey] as? AVAudioSession.RouteChangeReason ?? .unknown
		let routeDescription = notification?.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
		
		if let routeDescription = routeDescription {
			print(routeDescription.debugDescription)
			switch reasonValue {
				case AVAudioSession.RouteChangeReason.oldDeviceUnavailable:
					stop()
					break
				default:
					break
			}
		}
	}
	
	public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		stop()
	}
	
	public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
		
	}
	
	public func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
		stop()
	}
	
	public func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
		
	}
}
