//
//  ViewController.swift
//  SendCommand-iOS
//
//  Created by Shinichiro Oba on 2020/01/18.
//

import UIKit
import ExternalAccessory

class ViewController: UIViewController {
    
    @IBOutlet weak var commandTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private let protocolString = "com.lego.les"
    private var connectedSession: EASession?
    
    private func openAccessoryPicker() {
        // １．MFi認定を受けているBluetoothデバイスを接続する
        EAAccessoryManager.shared().showBluetoothAccessoryPicker(withNameFilter: nil, completion: { [weak self] (error) in
            guard error == nil else { return }
            self?.openSessionWithConnectedAccessory()
        })
    }
    
    private func openSessionWithConnectedAccessory() {
        // ２．該当の通信プロトコルをサポートしている接続済みデバイスを探す
        guard let accessory = EAAccessoryManager.shared().connectedAccessories.first(where: { $0.protocolStrings.contains(protocolString) } ) else { return }
        
        // ３．通信プロトコルを指定してセッションを開く
        guard let session = EASession(accessory: accessory, forProtocol: protocolString) else { return }
        
        session.outputStream?.schedule(in: .current, forMode: .default)
        session.outputStream?.open()
        
        self.connectedSession = session
    }
    
    private func sendCommand(_ command: String) {
        guard let outputStream = connectedSession?.outputStream else { return }
        guard var data = command.data(using: .utf8) else { return }
        
        data.append(0x0d) // 末尾に \r を追加
        
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
            if let bytes = buffer.bindMemory(to: UInt8.self).baseAddress {
                // ４．セッションの出力ストリームにバイト列を送信する
                outputStream.write(bytes, maxLength: buffer.count)
            }
        }
    }
    
    @IBAction func openButtonPushed(_ sender: Any) {
        //openAccessoryPicker()
        openSessionWithConnectedAccessory()
    }
    
    @IBAction func streamingButtonPushed(_ sender: Any) {
        sendCommand(#"{"m":"program_modechange","p":{"mode":"play"}}"#)
    }
    
    @IBAction func downloadButtonPushed(_ sender: Any) {
        sendCommand(#"{"m":"program_modechange","p":{"mode":"download"}}"#)
    }
    
    @IBAction func sendButtonPushed(_ sender: Any) {
        sendCommand(commandTextView.text)
    }
}
