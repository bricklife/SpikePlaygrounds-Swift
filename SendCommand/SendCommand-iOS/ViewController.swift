//
//  ViewController.swift
//  SendCommand-iOS
//
//  Created by Shinichiro Oba on 2020/01/18.
//

import UIKit
import ExternalAccessory

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private let protocolString = "com.lego.les"
    private var connectedSession: EASession?
    
    private func connectedAccessory() -> EAAccessory? {
        return EAAccessoryManager.shared().connectedAccessories.first(where: { $0.protocolStrings.contains(protocolString) } )
    }
    
    private func connect(accessory: EAAccessory) {
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
                outputStream.write(bytes, maxLength: buffer.count)
            }
        }
    }
    
    @IBAction func openButtonPushed(_ sender: Any) {
        if let accessary = connectedAccessory() {
            connect(accessory: accessary)
        } else {
            EAAccessoryManager.shared().showBluetoothAccessoryPicker(withNameFilter: nil, completion: { [weak self] (error) in
                guard error == nil else { return }
                
                if let accessary = self?.connectedAccessory() {
                    self?.connect(accessory: accessary)
                }
            })
        }
    }
    
    @IBAction func streamingButtonPushed(_ sender: Any) {
        sendCommand(#"{"m":"program_modechange","p":{"mode":"play"}}"#)
    }
}
