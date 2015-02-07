

#include <RFduinoBLE.h>
#include "libUBP.h"
#include "constants.h"
#include "data_types.h"

// Necessary because otherwise compiler won't find them nested in another library
#include <Arduino.h>
#include <crc8.h>


void setup() {
  
  // put your setup code here, to run once:
  setupRFDuino();
  
  Serial.begin(9600);
}

void loop() {
  
  MeasurementType aMeasurement;
  aMeasurement.A = 1.234;
  aMeasurement.B = 4.321;
  aMeasurement.C = 0.0;
  aMeasurement.D = 0.0;
  aMeasurement.E = 0.0;
  aMeasurement.F = 0.0;
  aMeasurement.G = 0.0;
  aMeasurement.H = 0.0;
  aMeasurement.Z = 0.0;
  aMeasurement.J = 0.0;
  aMeasurement.K = 0.0;
  aMeasurement.L = 54.321;
  bool success = UBP_queuePacketTransmission(MEASUREMENT_v1, UBP_TxFlagIsRPC, (char *) &aMeasurement, sizeof(MeasurementType));
  if (success) Serial.println("Packet queued successfully");
  else Serial.println("Failed to enqueue packet");
  
  // put your main code here, to run repeatedly:
  while (UBP_isBusy() == true) UBP_pump();
  
  delay(1000);
  
  aMeasurement.A = 2.134;
  aMeasurement.B = 4.321;
  aMeasurement.C = 0.0;
  aMeasurement.D = 0.0;
  aMeasurement.E = 0.0;
  aMeasurement.F = 0.0;
  aMeasurement.G = 0.0;
  aMeasurement.H = 0.0;
  aMeasurement.Z = 0.0;
  aMeasurement.J = 0.0;
  aMeasurement.K = 0.0;
  aMeasurement.L = 54.321;
  success = UBP_queuePacketTransmission(MEASUREMENT_v2, UBP_TxFlagNone, (char *) &aMeasurement, sizeof(MeasurementType));
  if (success) Serial.println("Packet queued successfully");
  else Serial.println("Failed to enqueue packet");
  
  // put your main code here, to run repeatedly:
  while (UBP_isBusy() == true) UBP_pump();
  
  RFduino_ULPDelay( SECONDS(1) );
}


// --------------------------

void setupRFDuino() {
  
  RFduinoBLE.deviceName = "RFduino";
  RFduinoBLE.advertisementData = "data";
  RFduinoBLE.advertisementInterval = MILLISECONDS(300);
  RFduinoBLE.txPowerLevel = 0;  // (-20dbM to +4 dBm)

  // Start the BLE stack
  RFduinoBLE.begin();
  
}
  
// ---------------------------

void UBP_receivedPacket(unsigned short packetIdentifier, UBP_TxFlags txFlags, void *packetBuffer) {
  
  switch (packetIdentifier) {
    
    case MEASUREMENT_v1: {
      
        
      
      break;
    }
  }
}
