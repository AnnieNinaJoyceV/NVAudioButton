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

final class NVAudioButton: UIButton, NVProgressLayersDelegate, AVAudioPlayerDelegate, NVAudioSessionConfigDelegate {
	func currentProgress() -> CGFloat {
		if let player = player, player.currentTime <= player.duration {
			let process = player.currentTime / player.duration
			return CGFloat(process < -0.1 ? 0.0 : process)
		} else {
			return 0.0
		}
	}
	
	private var player: AVAudioPlayer?
	private var progressLayers: NVProgressLayers?
	private var playState: NVAudioButtonState?
	private var backgroundCornRadius: CGFloat = 0.0
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
	
	public var shape: NVProgressLayersShape = .rectangle {
		didSet {
			self.progressLayers?.progressShape = shape
			setNeedsDisplay()
		}
	}
	
	public var buttonColor: UIColor = .black {
		didSet {
			self.progressLayers?.progressColor = buttonColor
			setNeedsDisplay()
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
		let diameter: CGFloat = min(frame.size.height, frame.size.width) * 0.618
		eclipseRect = CGRect(x: (frame.size.width - diameter) / 2,
							 y: (frame.size.height - diameter) / 2,
							 width: diameter,
							 height: diameter)
		
		let side: CGFloat = diameter * 0.618
		let leftX: CGFloat = eclipseRect.origin.x + (diameter - 0.866 * side) * 0.667
		let topY: CGFloat = eclipseRect.origin.y + (diameter - side) / 2
		let bottomY: CGFloat = eclipseRect.origin.y + (diameter + side) / 2
		let rightX: CGFloat = leftX + 0.866 * side
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
		self.playState = .idle
		self.addTarget(self, action: #selector(buttonTouched), for: .touchUpInside)
		//
		self.progressLayers = NVProgressLayers()
		self.progressLayers?.delegate = self
		self.progressLayers?.progressShape = shape
		self.progressLayers?.lineWidth = 2.0
		self.progressLayers?.backColor = backgroundColor
		self.progressLayers?.progressColor = buttonColor
		self.progressLayers?.cornRadius?.pointee = backgroundCornRadius
		//configure audio session, register notification for handleRouteChange.
		NVAudioSessionConfig.instanceVar?.registerAudioSessionNotification(for: self)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		if stopRect == .zero {
			updateFrame()
		}
	}
	
	override func draw(_ rect: CGRect) {
		super.draw(rect)
		
		backgroundColor?.setFill()
		let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: backgroundCornRadius)
		path.fill()
		
		guard let ctx = UIGraphicsGetCurrentContext() else { return }
		ctx.setFillColor(buttonColor.cgColor)
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
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		stop()
	}
	
	func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
		
	}
	
	func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
		stop()
	}
	
	func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
		
	}
}
