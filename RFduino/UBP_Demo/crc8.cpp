// LICENSES: [077915]
// -----------------------------------
// The contents of this file contains the aggregate of contributions
//   covered under one or more licences. The full text of those licenses
//   can be found in the "LICENSES" file at the top level of this project
//   identified by the MD5 fingerprints listed above.

#ifdef NEEDS_ARDUINO_SHIM
#include "Arduino_Types_Shim.h"
#else
#include "Arduino.h"
#endif

#include "crc8.h"

#define CRC8INIT  0x00
#define CRC8POLY  0x18      // 0X18 = X^8+X^5+X^4+X^0

byte CRC8(void *bytes, byte number_of_bytes_to_read) {
  
  byte *data_in = (byte*) bytes;
  byte  crc;
  uint16_t loop_count;
  byte  bit_counter;
  byte  data;
  byte  feedback_bit;
  
  crc = CRC8INIT;

  for (loop_count = 0; loop_count != number_of_bytes_to_read; loop_count++)
  {
    data = data_in[loop_count];
    
    bit_counter = 8;
    do {
      feedback_bit = (crc ^ data) & 0x01;
  
      if ( feedback_bit == 0x01 ) {
        crc = crc ^ CRC8POLY;
      }
      crc = (crc >> 1) & 0x7F;
      if ( feedback_bit == 0x01 ) {
        crc = crc | 0x80;
      }
    
      data = data >> 1;
      bit_counter--;
    
    } while (bit_counter > 0);
  }
  
  return crc;
}
