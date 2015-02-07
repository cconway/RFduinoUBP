//
//  ViewController.swift
//  UBA-Demo
//
//  Created by Chas Conway on 2/1/15.
//  Copyright (c) 2015 Chas Conway. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, RFduinoManagerDelegate {

	var rfdManager:RFduinoManager = RFduinoManager()
	
	
	@IBOutlet weak var connectButton: UIButton!
	@IBOutlet weak var connectionStatusLabel: UILabel!
	@IBOutlet weak var valueLabel: UILabel!
	
	@IBAction func didTapConnectButton(sender: UIButton) {
		
		switch (rfdManager.peripheralState) {
			
		case .Unassigned:
			
			let serviceUUIDs:[CBUUID]? = [CBUUID(string: "2220")]
			rfdManager.scanForRFduinos(serviceUUIDs)
			
		case .Scanning:
			break
			
		case .Disconnected:
			rfdManager.connect()
			
		case .Connecting:
			break
			
		case .Connected:
			rfdManager.disconnect()
			
		case .Notifying:
			rfdManager.disconnect()
			
		default:
			break
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		rfdManager.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	
	// MARK: - RFduinoManagerDelegate methods
	func rfduinoManagerFoundPeripherals(peripherals: [CBPeripheral]) {
		
		if let aPeripheral = peripherals.first {
			
			rfdManager.setSelectedPeripheral(aPeripheral)
		}
	}
	
	func rfduinoManagerPeripheralStateChanged(state: RFduinoPeripheralState) {
		
		switch (state) {
			
		case .Unassigned:
			connectButton.setTitle("Scan For Devices", forState: UIControlState.Normal)
			connectionStatusLabel.text = "No Peripheral Chosen"
			
		case .Scanning:
			connectButton.setTitle("Cancel", forState: UIControlState.Normal)
			connectionStatusLabel.text = "Scanning..."
		
		case .Disconnected:
			connectButton.setTitle("Connect", forState: UIControlState.Normal)
			connectionStatusLabel.text = "Not Connected"
			
		case .Connecting:
			connectButton.setTitle("Cancel", forState: UIControlState.Normal)
			connectionStatusLabel.text = "Connecting..."
			
		case .Connected:
			connectButton.setTitle("Disconnect", forState: UIControlState.Normal)
			connectionStatusLabel.text = "Connected"
			
		case .Notifying:
			connectButton.setTitle("Disconnect", forState: UIControlState.Normal)
			connectionStatusLabel.text = "Communicating..."
			
		default:
			break;
		}
	}
	
	func rfduinoManagerReceivedMessage(messageIdentifier: UInt16, txFlags: UInt8, payloadData: NSData) {
		
//		println("Received SLIP payload with ID = \(messageIdentifier)")

		var measurementPayload = MeasurementType(A: 0, B: 0, C: 0, D: 0, E: 0, F: 0, G: 0, H: 0, Z: 0, J: 0, K: 0, L: 0)
		payloadData.getBytes(&measurementPayload, length:payloadData.length)

//		println("Measurement = \(measurementPayload.A)")
		
		valueLabel.text = "\(measurementPayload.A)"
	}
}

