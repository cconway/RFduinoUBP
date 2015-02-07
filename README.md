# RFduinoUBP
Unambitious Binary Protocol for RFduino

Unambitious Binary Protocol is meant to be a simple way of sending structured data between RFduino and iOS clients. It adds a very small amount of protocol to structure the communications flow and automatically handles escaping and framing data over the air using SLIP. The intended purpose of UBP is to facilitate the sending of structured data serialized to binary that can be larger than the maximum transmission unit, 20 bytes, supported by RFduino. This means you can send data structures (e.g. C struct, protobuf) larger than 20 bytes between RFduion and iOS and reconstruction is handled automatically.

The iOS and RFduino demo applications are still in very early stages, but hopefully provide a preview. Please note, there is not currently support for sending from iOS to RFduino. 
