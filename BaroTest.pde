/*
  The simplest possible test code for the BMP085 Barometric Pressure Sensor from Sparkfun:
  http://www.sparkfun.com/products/9694
  
  Created by Myles Grant <myles@mylesgrant.com>
  See also: https://github.com/grantmd/QuadCopter
  
  Adopted from: http://wiring.org.co/learning/libraries/bmp085.html
  
  This program is free software: you can redistribute it and/or modify 
  it under the terms of the GNU General Public License as published by 
  the Free Software Foundation, either version 3 of the License, or 
  (at your option) any later version. 

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
  GNU General Public License for more details. 

  You should have received a copy of the GNU General Public License 
  along with this program. If not, see <http://www.gnu.org/licenses/>. 
*/

#include <Wire.h>

#define I2C_ADDR 0x77 // The i2c address of the BMP

unsigned long previousTime = 0;

const unsigned char oversampling_setting = 3; //oversampling for measurement
const unsigned char pressure_conversiontime[4] = { 
  5, 8, 14, 26 };  // delays for oversampling settings 0, 1, 2 and 3 

// sensor registers from the BOSCH BMP085 datasheet
int ac1;
int ac2; 
int ac3; 
unsigned int ac4;
unsigned int ac5;
unsigned int ac6;
int b1; 
int b2;
int mb;
int mc;
int md;

// variables to keep the values
int temperature = 0;
long pressure = 0;

void setup(){
  Serial.begin(115200);
  Wire.begin();
  
  bmpInit();
  
  previousTime = millis();
}

void loop(){
  if (millis() - previousTime >= 5000){
    readAll();
    
    previousTime = millis();
  }
}

// Verify the bmp is present
void bmpInit(){
  Serial.println("Initing BMP");
  
  getCalibrationData();
}

// Read "all" the data off the bmp and print it
void readAll(){
  int ut = readUT();
  Serial.print("Uncompensated Temp: ");
  Serial.println(ut, DEC);
  
  long up = readUP();
  Serial.print("Uncompensated Pressure: ");
  Serial.println(up, DEC);
}

// Read the calibration data off the device
void getCalibrationData(){
  Serial.println("Reading Calibration Data");
  
  sendReadRequest(0xAA);
  ac1 = readWord();
  Serial.print("AC1: ");
  Serial.println(ac1, DEC);
  
  sendReadRequest(0xAC);
  ac2 = readWord();
  Serial.print("AC2: ");
  Serial.println(ac2, DEC);
  
  sendReadRequest(0xAE);
  ac3 = readWord();
  Serial.print("AC3: ");
  Serial.println(ac3, DEC);
  
  sendReadRequest(0xB0);
  ac4 = readWord();
  Serial.print("AC4: ");
  Serial.println(ac4, DEC);
  
  sendReadRequest(0xB2);
  ac5 = readWord();
  Serial.print("AC5: ");
  Serial.println(ac5, DEC);
  
  sendReadRequest(0xB4);
  ac6 = readWord();
  Serial.print("AC6: ");
  Serial.println(ac6, DEC);
  
  sendReadRequest(0xB6);
  b1 = readWord();
  Serial.print("B1: ");
  Serial.println(b1, DEC);
  
  sendReadRequest(0xB8);
  b2 = readWord();
  Serial.print("B2: ");
  Serial.println(b1, DEC);
  
  sendReadRequest(0xBA);
  mb = readWord();
  Serial.print("MB: ");
  Serial.println(mb, DEC);
  
  sendReadRequest(0xBC);
  mc = readWord();
  Serial.print("MC: ");
  Serial.println(mc, DEC);
  
  sendReadRequest(0xBE);
  md = readWord();
  Serial.print("MD: ");
  Serial.println(md, DEC);
}

// read uncompensated temperature value
unsigned int readUT(){
  writeSetting(0xf4, 0x2e);
  delay(5); // the datasheet suggests 4.5 ms
  sendReadRequest(0xf6);
  return readWord();
}

// read uncompensated pressure value
long readUP(){
  writeSetting(0xf4, 0x34+(oversampling_setting<<6));
  delay(pressure_conversiontime[oversampling_setting]);

  unsigned char msb, lsb, xlsb;
  sendReadRequest(0xf6);

  requestBytes(3);
  msb = readNextByte();
  lsb |= readNextByte();
  xlsb |= readNextByte();
  return (((long)msb<<16) | ((long)lsb<<8) | ((long)xlsb)) >>(8-oversampling_setting);
}

//
// I2C helper functions
//

// Write a setting to the device at register data_address
byte writeSetting(byte data_address, byte data_value){
  Wire.beginTransmission(I2C_ADDR);
  Wire.send(data_address);
  Wire.send(data_value);
  return Wire.endTransmission();
}

// Tell the device that we will be reading from register data_address
byte sendReadRequest(byte data_address){
  Wire.beginTransmission(I2C_ADDR);
  Wire.send(data_address);
  return Wire.endTransmission();
}

// Request 2 bytes and read it
word readWord(){
  requestBytes(2);
  return ((Wire.receive() << 8) | Wire.receive());
}

// Request some number of bytes
void requestBytes(int bytes){
  Wire.beginTransmission(I2C_ADDR);
  Wire.requestFrom(I2C_ADDR, bytes);
}

// Read the next available byte
byte readNextByte(){
  return Wire.receive();
}
