//
//  SLIPBuffer.swift
//  UBA-Demo
//
//  Created by Chas Conway on 2/4/15.
//  Copyright (c) 2015 Chas Conway. All rights reserved.
//

import Foundation

let PacketIdentifierLength = sizeof(UInt16)
let PacketFlagsLength = sizeof(UInt8)
let PacketChecksumLength = sizeof(UInt8)

protocol SLIPBufferDelegate {
	
	func slipBufferReceivedPayload(payloadData:NSData, payloadIdentifier:UInt16, txFlags:UInt8)
}


class SLIPBuffer {

	var rxBuffer = NSMutableData()
	var delegate:SLIPBufferDelegate?
	
	init() {  // NOTE: Why is this required?
		
	}
	
	func appendEscapedBytes(escapedData:NSData) {
		
		rxBuffer.appendData(escapedData)
		scanRxBufferForFrames()
	}
	
	func scanRxBufferForFrames() {
		
		let endByteIndices = rxBuffer.indexesOfEndBytes()
		
		var previousIndex = NSNotFound
		endByteIndices.enumerateIndexesUsingBlock { (anIndex, stop) -> Void in
			
			if (previousIndex != NSNotFound) {
				
				if anIndex - previousIndex > 2 {  // Contains at least one byte and checksum byte
					
					println("Identified a potential SLIP frame")
					
					let escapedPacketData = self.rxBuffer.subdataWithRange(NSMakeRange(previousIndex + 1, anIndex - previousIndex - 1))
					
					self.decodeSLIPPacket(escapedPacketData)
				
				} else {
					
					println("Ignoring improbable SLIP frame")
				}
			}
			
			previousIndex = anIndex
		}
		
		// Remove byte in buffer up to, but not including, the last END byte
		if previousIndex != NSNotFound {
		
			self.rxBuffer.replaceBytesInRange(NSMakeRange(0, previousIndex), withBytes:UnsafePointer<Int8>.null(), length: 0)
		}
	}
	
	func decodeSLIPPacket(escapedPacket:NSData) {
		
		// Remove SLIP escaping
		let unescapedPacket = escapedPacket.unescapedData()
		
		// Extract embedded checksum from packet
		var embeddedChecksumByte:Int8 = 0
		unescapedPacket.getBytes(&embeddedChecksumByte, range: NSMakeRange(unescapedPacket.length - PacketChecksumLength, PacketChecksumLength))
		
		// Calculate checksum on payload bytes
		let checksummedData = unescapedPacket.subdataWithRange(NSMakeRange(0, unescapedPacket.length - PacketChecksumLength))
		let calculatedChecksum = checksummedData.CRC8Checksum()
		
		if calculatedChecksum == embeddedChecksumByte {
			
			if let aDelegate = delegate {
				
				// Extract payload and payload ID
				var identifier:UInt16 = 0;
				checksummedData.getBytes(&identifier, range: NSMakeRange(0, PacketIdentifierLength))
				
				var txFlags:UInt8 = 0;
				checksummedData.getBytes(&txFlags, range: NSMakeRange(PacketIdentifierLength - 1, PacketFlagsLength))
				
				let payloadData = checksummedData.subdataWithRange(NSMakeRange(PacketIdentifierLength + PacketFlagsLength, checksummedData.length - PacketFlagsLength - PacketIdentifierLength))
				
				// Notify delegate
				aDelegate.slipBufferReceivedPayload(payloadData, payloadIdentifier:identifier, txFlags:txFlags)
			}
			
		} else {
			
			println("SLIP frame failed checksum")
		}
	}
}