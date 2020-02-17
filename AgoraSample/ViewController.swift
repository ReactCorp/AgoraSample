//
//  ViewController.swift
//  AgoraSample
//
//  Created by naratti on 2020/01/22.
//  Copyright © 2020 React inc. All rights reserved.
//

import UIKit
import AgoraRtcEngineKit

class ViewController: UIViewController {

    private var agora: AgoraRtcEngineKit!
    private var scenario: AgoraAudioScenario = .default
    private var uids = [String]()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var audioPortLabel: UILabel!
    @IBOutlet weak var scenarioLabel: UILabel!
    
    private var currentOutputAudioPort: AVAudioSession.PortOverride = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        uidLabel.text = "Own Uid:"
        audioPortLabel.text = "Not Connected"
        scenarioLabel.text = "Not Connected"
        agora = AgoraRtcEngineKit.sharedEngine(withAppId: "AGORA_ID", delegate: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeAudioSessionRoute(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    @IBAction func tapConnect(_ sender: Any) {
        joinChannel()
    }
    
    func joinChannel() {
        agora.setChannelProfile(.communication)
        agora.setParameters("{\"che.audio.force.bluetooth.a2dp\":true}")
        
        if isConnectedHeadPhone() {
            currentOutputAudioPort = .none
            audioPortLabel.text = "AudioPort: .none"
            scenario = .gameStreaming
            scenarioLabel.text = "Scenario: .gameStreaming"
            agora.setDefaultAudioRouteToSpeakerphone(false)
        } else {
            currentOutputAudioPort = .speaker
            audioPortLabel.text = "AudioPort: .speaker"
            scenario = .default
            scenarioLabel.text = "Scenario: .default"
            agora.setDefaultAudioRouteToSpeakerphone(true)
        }
        agora.setAudioProfile(.speechStandard, scenario: scenario)
        agora.enableAudioVolumeIndication(200, smooth: 3)
        
        agora.joinChannel(byToken: nil, channelId: "demoChannel1", info: nil, uid: 0) { [weak self] (sid, uid, elapsed) in
            guard let strongSelf = self else { return }
            strongSelf.uidLabel.text = "own uid: \(uid)"
            if strongSelf.currentOutputAudioPort == .none {
                strongSelf.agora.setEnableSpeakerphone(false)
            } else {
                strongSelf.agora.setEnableSpeakerphone(true)
                let audioSession = AVAudioSession.sharedInstance()
                try? audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                try? audioSession.setActive(true)
            }
        }
    }
    
    private func isConnectedHeadPhone() -> Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        
        for desc in route.outputs {
            if desc.portType == .headphones || desc.portType == .bluetoothLE || desc.portType == .bluetoothHFP || desc.portType == .bluetoothA2DP || desc.portType == .usbAudio {
                return true
            } else {
                return false
            }
        }
        
        return false
    }
    
    @objc private func didChangeAudioSessionRoute(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs {
                if output.portType == .headphones || output.portType == .bluetoothLE || output.portType == .bluetoothHFP || output.portType == .bluetoothA2DP || output.portType == .usbAudio {
                    setOutputAudioPort(.none)
                }
                break
            }
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs {
                    if output.portType == .headphones || output.portType == .bluetoothLE || output.portType == .bluetoothHFP || output.portType == .bluetoothA2DP || output.portType == .usbAudio {
                        setOutputAudioPort(.speaker)
                    }
                    break
                }
            }
        default: ()
        }
    }
    
    private func setOutputAudioPort(_ newAudioPort: AVAudioSession.PortOverride) {
        self.currentOutputAudioPort = newAudioPort
        DispatchQueue.main.async {
            if self.currentOutputAudioPort == .none {
                self.audioPortLabel.text = "AudioPort: .none"
                self.agora.setEnableSpeakerphone(false)
            } else {
                self.audioPortLabel.text = "AudioPort: .speaker"
                self.agora.setEnableSpeakerphone(true)
                let audioSession = AVAudioSession.sharedInstance()
                try? audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                try? audioSession.setActive(true)
            }
            if self.scenario == .gameStreaming {
                self.scenarioLabel.text = "Scenario: .gameStreaming"
            } else {
                self.scenarioLabel.text = "Scenario: .default"
            }
            self.reJoinChannel()
        }
    }
    
    private func reJoinChannel() {
        agora.leaveChannel { [weak self] (stats: AgoraChannelStats) in
            guard let strongSelf = self else { return }
            strongSelf.agora.setChannelProfile(.communication)
            if strongSelf.currentOutputAudioPort == .none {
                strongSelf.agora.setAudioProfile(.speechStandard, scenario: .gameStreaming)
                strongSelf.agora.setDefaultAudioRouteToSpeakerphone(false)
            } else {
                strongSelf.agora.setAudioProfile(.speechStandard, scenario: .default)
                strongSelf.agora.setDefaultAudioRouteToSpeakerphone(true)
            }
            strongSelf.agora.enableAudioVolumeIndication(200, smooth: 3)
            strongSelf.agora.joinChannel(byToken: nil, channelId: "demoChannel1", info: nil, uid: 0) { [weak self] (sid, uid, elapsed) in
                guard let strongSelf = self else { return }
                if strongSelf.currentOutputAudioPort == .none {
                    strongSelf.agora.setEnableSpeakerphone(false)
                } else {
                    strongSelf.agora.setEnableSpeakerphone(true)
                    let audioSession = AVAudioSession.sharedInstance()
                    try? audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                    try? audioSession.setActive(true)
                }
            }
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uids.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        cell.label.text = uids[indexPath.row]

        return cell
    }
}

extension ViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid", uid)
        uids.append(String(uid))
        tableView.reloadData()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("didOfflineOfUid", uid)
        let index = uids.firstIndex(of: String(uid))!
        uids.remove(at: index)
        tableView.reloadData()
    }
}
