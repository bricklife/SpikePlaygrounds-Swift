//
//  ViewController.swift
//  SendCommand-macOS
//
//  Created by Shinichiro Oba on 2020/01/17.
//

import Cocoa
import IOBluetooth
import IOBluetoothUI

class ViewController: NSViewController {
    
    @IBOutlet weak var commandTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private var connectedChannel: IOBluetoothRFCOMMChannel?
    
    private func openDeviceSelectorController() {
        // １．Bluetoothデバイスを探す
        guard let deviceSelector = IOBluetoothDeviceSelectorController.deviceSelector() else { return }
        
        if deviceSelector.runModal() != Int32(kIOBluetoothUISuccess) {
            print("Canceled")
            return
        }
        
        if let device = deviceSelector.getResults()?.first as? IOBluetoothDevice {
            // ５．チャンネルIDを指定してRFCOMMチャンネルを開く
            device.openRFCOMMChannelSync(&connectedChannel, withChannelID: 1, delegate: nil)
        }
    }
    
    private func sendCommand(_ command: String) {
        guard let connectedChannel = connectedChannel else { return }
        guard var data = command.data(using: .utf8) else { return }
        
        data.append(0x0d) // 末尾に \r を追加
        
        data.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) -> Void in
            if let bytes = buffer.baseAddress {
                // ６．RFCOMMチャンネルにバイト列を送信する
                connectedChannel.writeSync(bytes, length: UInt16(buffer.count))
            }
        }
    }
    
    @IBAction func openButtonPushed(_ sender: Any) {
        openDeviceSelectorController()
    }
    
    @IBAction func disconnectButtonPushed(_ sender: Any) {
        connectedChannel?.close()
    }
    
    @IBAction func streamingButtonPushed(_ sender: Any) {
        sendCommand(#"{"m":"program_modechange","p":{"mode":"play"}}"#)
    }
    
    @IBAction func downloadButtonPushed(_ sender: Any) {
        sendCommand(#"{"m":"program_modechange","p":{"mode":"download"}}"#)
    }
    
    @IBAction func sendButtonPushed(_ sender: Any) {
        sendCommand(commandTextField.stringValue)
    }
}

