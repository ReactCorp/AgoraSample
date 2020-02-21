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
    var uids = [String]()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        label.text = "own uid:"
        
        joinChannel()
    }
    
    func joinChannel() {
        agora = AgoraRtcEngineKit.sharedEngine(withAppId: <#APP_ID#>, delegate: self)
        agora.setChannelProfile(.communication)
        agora.setAudioProfile(.speechStandard, scenario: .gameStreaming)
        agora.setParameters("{\"che.audio.force.bluetooth.a2dp\":true}")
        agora.joinChannel(byToken: nil, channelId: "demoChannel1", info: nil, uid: 0) { [weak self] (sid, uid, elapsed) in
            if let weakSelf = self {
                weakSelf.label.text = "own uid: \(uid)"
                weakSelf.agora.setRemoteVoicePosition(uid, pan: 0, gain: 0.5)
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
