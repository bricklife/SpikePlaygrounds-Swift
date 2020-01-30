//
//  ViewController.swift
//  MotorControl-iOS
//
//  Created by Shinichiro Oba on 2020/01/30.
//

import UIKit
import ExternalAccessory

class ViewController: UIViewController {
    
    @IBOutlet weak var speedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private let protocolString = "com.lego.les"
    private var connectedSession: EASession?
    
    private var commandQueue: [String] = []
    private var speed: Int = 0
    
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
        session.outputStream?.delegate = self
        session.outputStream?.open()
        
        self.connectedSession = session
    }
    
    private func sendCommand(_ command: String) {
        guard let outputStream = connectedSession?.outputStream else { return }
        
        guard outputStream.hasSpaceAvailable else {
            commandQueue.append(command)
            return
        }
        
        guard var data = command.data(using: .utf8) else { return }
        
        data.append(0x0d) // 末尾に \r を追加
        
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
            if let bytes = buffer.bindMemory(to: UInt8.self).baseAddress {
                // ４．セッションの出力ストリームにバイト列を送信する
                outputStream.write(bytes, maxLength: buffer.count)
            }
        }
    }
    
    private func setSpeed(_ speed: Int) {
        self.speed = speed
        speedLabel.text = speed.description
        
        for port in ["A","B","C","D","E","F"] {
            let command = #"{"i":"\#(port)","m":"scratch.motor_start","p":{"port":"\#(port)","speed":\#(speed),"stall":true}}"#
            sendCommand(command)
        }
    }
    
    @IBAction func openButtonPushed(_ sender: Any) {
        //openAccessoryPicker()
        openSessionWithConnectedAccessory()
    }
    
    @IBAction func plusButtonPushed(_ sender: Any) {
        setSpeed(min(speed + 10, 100))
    }
    
    @IBAction func minusButtonPushed(_ sender: Any) {
        setSpeed(max(speed - 10, -100))
    }
    
    @IBAction func resetButtonPushed(_ sender: Any) {
        setSpeed(0)
    }
}

extension ViewController: StreamDelegate {
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            print(aStream, "openCompleted")
            
        case .hasSpaceAvailable:
            print(aStream, ".hasSpaceAvailable")
            if commandQueue.count > 0 {
                let command = commandQueue.removeFirst()
                sendCommand(command)
            }
            
        case .hasBytesAvailable:
            print(aStream, ".hasBytesAvailable")
            
        case .endEncountered:
            print(aStream, ".endEncountered")
            
        case .errorOccurred:
            print(aStream, ".errorOccurred")
            
        default:
            print(aStream, "default")
        }
    }
}
