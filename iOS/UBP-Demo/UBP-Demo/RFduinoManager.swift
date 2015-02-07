//
//  RFduinoManager.swift
//  UBA-Demo
//
//  Created by Chas Conway on 2/1/15.
//  Copyright (c) 2015 Chas Conway. All rights reserved.
//

import Foundation
import CoreBluetooth

private var BLEScanDuration = 3.0

public enum RFduinoPeripheralState {
	
	case Unassigned
	case Unavailable(CBCentralManagerState)
	case Scanning
	case Disconnected
	case Connecting
	case Connected
	case Notifying
}

protocol RFduinoManagerDelegate {
	
	func rfduinoManagerFoundPeripherals(peripherals:[CBPeripheral])
	func rfduinoManagerPeripheralStateChanged(state:RFduinoPeripheralState)
	func rfduinoManagerReceivedMessage(messageIdentifier:UInt16, txFlags:UInt8, payloadData:NSData)
}


class RFduinoManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, SLIPBufferDelegate {
	
	// MARK: - Public
	
	// MARK: Properties
	var selectedPeripheral:CBPeripheral? {  // Read-only access to _selectedPeripheral
		
		get { return _selectedPeripheral }
	}
	
	var delegate:RFduinoManagerDelegate? {
		didSet {
			// Help delegate initialize by sending current state directly after delegate assignment
			delegate?.rfduinoManagerPeripheralStateChanged(peripheralState)
		}
	}
	var peripheralState: RFduinoPeripheralState = .Unassigned {
		
		didSet { delegate?.rfduinoManagerPeripheralStateChanged(peripheralState) }
	}
	
	// MARK: Methods
	override init() {
		
		super.init()
		
		centralManager = CBCentralManager(delegate: self, queue: nil)
		slipBuffer.delegate = self
	}
	
	func scanForRFduinos(serviceUUIDs: [CBUUID]?) {
		
		//		scanCallback = callback
		
		if (centralManager.state == CBCentralManagerState.PoweredOn) {
			
			scanResults = Array();
			
			println("Beginning scan for RFduino peripherals")
			centralManager.stopScan()
			centralManager.scanForPeripheralsWithServices(serviceUUIDs, options: nil)
			scanTimer = NSTimer.scheduledTimerWithTimeInterval(BLEScanDuration, target: self, selector: "scanTimerDidFire", userInfo: nil, repeats: false)
			
			peripheralState = .Scanning
			
		} else {
			
			onReadyBlock = { () -> () in
				
				self.scanForRFduinos(serviceUUIDs)
			}
		}
	}
	
	func setSelectedPeripheral(peripheral:CBPeripheral?) {
		
		_selectedPeripheral = peripheral
	}
	
	func connect() {
		
		if let thePeripheral = _selectedPeripheral {
			
			thePeripheral.delegate = self;
			
			centralManager.connectPeripheral(thePeripheral, options: nil);
			
			peripheralState = .Connecting
		}
	}
	
	func disconnect() {
		
		if _selectedPeripheral?.state == CBPeripheralState.Connected || _selectedPeripheral?.state == CBPeripheralState.Connecting {
			
			centralManager.cancelPeripheralConnection(_selectedPeripheral)
		}
	}
	
	// MARK: - Private
	// MARK: Properties
	typealias ScanResult = (peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!)
	
	private var centralManager: CBCentralManager!
	private var slipBuffer = SLIPBuffer()
	private var scanTimer: NSTimer?
	private var scanResults: [ScanResult]?
	private var onReadyBlock: (() -> ())?
	private var _selectedPeripheral: CBPeripheral? {
		
		willSet(newPeripheral) {
			
			if (newPeripheral == nil) {
				
				// Disconnect from current peripheral
				centralManager.cancelPeripheralConnection(_selectedPeripheral)
			}
		}
		
		didSet {
			
			if let aPeripheral = _selectedPeripheral {
				
				peripheralState = .Disconnected
				
				connect()
			
			} else {
				
				peripheralState = .Unassigned
			}
		}
	}
	
	// MARK: Methods
	func scanTimerDidFire() -> Void {
		
		centralManager.stopScan();
		peripheralState = .Unassigned
		
		var peripherals = scanResults?.map({ (aResult: ScanResult) -> CBPeripheral in
			
			return aResult.peripheral
		})
		
		if let foundPeripherals = peripherals {
		
//			scanCallback!( error: nil, peripherals: foundPeripherals )
			delegate?.rfduinoManagerFoundPeripherals(foundPeripherals)
			
		} else {
			
//			scanCallback!( error: nil, peripherals: [])
			delegate?.rfduinoManagerFoundPeripherals([])
		}
	}
	
	
	// MARK: - CBCentralManagerDelegate methods
	func centralManagerDidUpdateState(central: CBCentralManager!) {
		
		switch (central.state) {
			
		case .PoweredOn:
			
			println("CoreBluetooth powered on");
			
			if let aBlock = onReadyBlock {
				
				aBlock();
				onReadyBlock = nil;
			}
			
		default:
			
			break;
		}
	}
	
	
	func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
		
		scanResults?.append( (peripheral, advertisementData, RSSI) )
	}
	
	func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
		
		println("Connected to RFduino");
		
		peripheralState = .Connected
		
		peripheral.discoverServices(nil)
	}
	
	func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
		
		println("Failed to connect to RFduino")
		peripheralState = .Disconnected
	}
	
	func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
		
		println("Disconnected from RFduino")
		peripheralState = .Disconnected
	}
	
	
	// MARK: - CBPeripheralDelegate methods
	func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
		
		println("Discovered services on RFduino");
		
		for anObject in peripheral.services {
			
			if let aService = anObject as? CBService {
				
				peripheral.discoverCharacteristics(nil, forService: aService)
			}
		}
	}
	
	func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
		
		println("Discovered characteristics on RFduino");
		
		for anObject in service.characteristics {
			
			if let aCharacteristic = anObject as? CBCharacteristic {
				
				if (aCharacteristic.properties & CBCharacteristicProperties.Notify) == CBCharacteristicProperties.Notify {
					
					// Register to be notified whenever the RFduino transmits
					peripheral.setNotifyValue(true, forCharacteristic: aCharacteristic)
				}
			}
		}
	}
	
	func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
		
		println("Enabled notification of RFduino transmission")
		peripheralState = .Notifying
	}
	
	func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
		
		if let anError = error {
			
			println("Characteristic update error = \(error)")
			
		} else {
			
			println("RFduino transmitted")
			slipBuffer.appendEscapedBytes(characteristic.value)
		}
	}
	
	
	// MARK: - SLIPbufferDelegate methods
	func slipBufferReceivedPayload(payloadData: NSData, payloadIdentifier: UInt16, txFlags: UInt8) {
		
		// Inform delegate
		if let theDelegate = delegate {
			
			theDelegate.rfduinoManagerReceivedMessage(payloadIdentifier, txFlags: txFlags, payloadData: payloadData)
		}
	}
}