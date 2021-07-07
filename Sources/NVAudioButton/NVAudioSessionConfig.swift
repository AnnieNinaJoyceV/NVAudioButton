//
//  NVAudioSessionConfig.swift
//  NVAudioButton
//
//  Created by Joyce on 14/05/21.
//

import Foundation
import AVKit

@objc protocol NVAudioSessionConfigDelegate: NSObjectProtocol {
	@objc optional func handleRouteChange(_ notification: Notification?)
}

final class NVAudioSessionConfig: NSObject {
	var isConfigured = false
	
	static let instanceVar: NVAudioSessionConfig? = {
		var instance = NVAudioSessionConfig()
		instance.configAudioSession()
		NotificationCenter.default.addObserver(self, selector: #selector(configAudioSession), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
		return instance
	}()
	
	class func instance() -> Any? {
		return instanceVar
	}
	
	@objc
	func configAudioSession() {
		do {
			try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
			try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
			try AVAudioSession.sharedInstance().setActive(true)
			isConfigured = true
		} catch {
			isConfigured = false
			print("Error: AVAudioSession: \(error.localizedDescription)")
		}
	}
	
	func registerAudioSessionNotification(for delegate: NVAudioSessionConfigDelegate?) {
		if delegate?.responds(to: #selector(NVAudioSessionConfigDelegate.handleRouteChange(_:))) ?? false {
			//configure notification when audio route change
			if let delegate = delegate {
				NotificationCenter.default.addObserver(delegate,
													   selector: #selector(NVAudioSessionConfigDelegate.handleRouteChange(_:)),
													   name: AVAudioSession.routeChangeNotification,
													   object: nil)
			}
		}
	}
	
	func unregisterAudioSessionNotification(for delegate: NVAudioSessionConfigDelegate?) {
		if let delegate = delegate {
			NotificationCenter.default.removeObserver(delegate,
													  name: AVAudioSession.routeChangeNotification,
													  object: nil)
		}
	}
}
