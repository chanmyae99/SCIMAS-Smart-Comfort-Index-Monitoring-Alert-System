#include "WiFiS3.h"
#include <WiFiS3.h>
#include "ThingSpeak.h"

#include "Air_Quality_Sensor.h"
#include "Seeed_SHT35.h"

// #include "secrets.h"

#define SECRET_SSID ""
#define SECRET_PASS ""

#define SECRET_CH_ID 3013843			// replace 0000000 with your channel number
#define SECRET_WRITE_APIKEY "TTUU91CQS0W58CZR"   // replace XYZ with your channel write API Key

///////please enter your sensitive data in the Secret tab/arduino_secrets.h
char ssid[] = "ChanMyaeAung123";        // your network SSID (name)
char pass[] = "saichan123";    // your network password (use for WPA, or use as key for WEP)
int keyIndex = 0;            // your network key index number (needed only for WEP)

int status = WL_IDLE_STATUS;
// if you don't want to use DNS (and reduce your sketch size)
// use the numeric IP instead of the name for the server:
//IPAddress server(74,125,232,128);  // numeric IP for Google (no DNS)
char server[] = "www.google.com";    // name address for Google (using DNS)

// Initialize the Ethernet client library
// with the IP address and port of the server
// that you want to connect to (port 80 is default for HTTP):
WiFiClient client;

unsigned long myChannelNumber = SECRET_CH_ID;
const char * myWriteAPIKey = SECRET_WRITE_APIKEY;

/*SAMD core*/
#ifdef ARDUINO_SAMD_VARIANT_COMPLIANCE
    #define SDAPIN  20
    #define SCLPIN  21
    #define RSTPIN  7
    #define SERIAL SerialUSB
#else
    #define SDAPIN  A4
    #define SCLPIN  A5
    #define RSTPIN  2
    #define SERIAL Serial
#endif


SHT35 shtSensor(SCLPIN);              
AirQualitySensor airSensor(A0); 

// Initialize our values
int number1 = 0;
int number2 = random(0,100);
int number3 = random(0,100);
// int number4 = random(0,100);
String myStatus = "";

void setup(void) {

  Serial.begin(9600);
  while (!Serial);

  ThingSpeak.begin(client);  // Initialize ThingSpeak

    // check for the WiFi module:
  if (WiFi.status() == WL_NO_MODULE) {
    Serial.println("Communication with WiFi module failed!");
    // don't continue
    while (true);
  }
  
  String fv = WiFi.firmwareVersion();
  if (fv < WIFI_FIRMWARE_LATEST_VERSION) {
    Serial.println("Please upgrade the firmware");
  }
  
  // attempt to connect to WiFi network:
  while (status != WL_CONNECTED) {
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(ssid);
    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
    status = WiFi.begin(ssid, pass);
     
    // wait 10 seconds for connection:
    delay(10000);
  }
  
 
  Serial.println("\nStarting connection to server...");
  // if you get a connection, report back via serial:
  if (client.connect(server, 80)) {
    Serial.println("connected to server");
    // Make a HTTP request:
    client.println("GET /search?q=arduino HTTP/1.1");
    client.println("Host: www.google.com");
    client.println("Connection: close");
    client.println();
  }
 
    Serial.println("\nStarting connection to server...");
    // if you get a connection, report back via serial:
    if (client.connect(server, 80)) {
        Serial.println("connected to server");
    }

  shtSensor.init();  // Just call init, ignore return
  airSensor.init();  // Also init air sensor

  Serial.println("Sensors initialized. Will check readings in loop.");


}

/* just wrap the received data up to 80 columns in the serial print*/
/* -------------------------------------------------------------------------- */
void read_response() {
/* -------------------------------------------------------------------------- */  
  uint32_t received_data_num = 0;
  while (client.available()) {
    /* actual data reception */
    char c = client.read();
    /* print data to serial port */
    Serial.print(c);
    /* wrap data to 80 columns*/
    received_data_num++;
    if(received_data_num % 80 == 0) { 
      Serial.println();
    }
  }  
}

void loop(void) {
    /* -------------------------------------------------------------------------- */  
    read_response();

    // if the server's disconnected, stop the client:
    if (!client.connected()) {
        Serial.println();
        Serial.println("disconnecting from server.");
        client.stop();

    }

    int quality = airSensor.slope();

    Serial.print("Sensor value: ");
    Serial.println(airSensor.getValue());

    if (quality == AirQualitySensor::FORCE_SIGNAL) {
        Serial.println("High pollution! Force signal active.");
    } else if (quality == AirQualitySensor::HIGH_POLLUTION) {
        Serial.println("High pollution!");
    } else if (quality == AirQualitySensor::LOW_POLLUTION) {
        Serial.println("Low pollution!");
    } else if (quality == AirQualitySensor::FRESH_AIR) {
        Serial.println("Fresh air.");
    }

    u16 value = 0;
    u8 data[6] = {0};
    float temp, hum;
    if (NO_ERROR != shtSensor.read_meas_data_single_shot(HIGH_REP_WITH_STRCH, &temp, &hum)) {
        SERIAL.println("read temp failed!!");
        SERIAL.println("   ");
        SERIAL.println("   ");
        SERIAL.println("   ");
    } else {
        SERIAL.println("read data :");
        SERIAL.print("temperature = ");
        SERIAL.print(temp);
        SERIAL.println(" ℃ ");

        SERIAL.print("humidity = ");
        SERIAL.print(hum);
        SERIAL.println(" % ");

        SERIAL.println("   ");
        SERIAL.println("   ");
        SERIAL.println("   ");
    }

    delay(1000);

    // Connect or reconnect to WiFi
  if(WiFi.status() != WL_CONNECTED){
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(SECRET_SSID);
    while(WiFi.status() != WL_CONNECTED){
      WiFi.begin(ssid, pass);  // Connect to WPA/WPA2 network. Change this line if using open or WEP network
      Serial.print(".");
      delay(5000);     
    } 
    Serial.println("\nConnected.");
  }

  // set the fields with the values
  ThingSpeak.setField(1, temp);
  ThingSpeak.setField(2, hum);
  ThingSpeak.setField(3, airSensor.getValue());
  // ThingSpeak.setField(4, number4);

  // figure out the status message
  if(number1 > number2){
    myStatus = String("field1 is greater than field2"); 
  }
  else if(number1 < number2){
    myStatus = String("field1 is less than field2");
  }
  else{
    myStatus = String("field1 equals field2");
  }
  
  // set the status
  ThingSpeak.setStatus(myStatus);
  
  // write to the ThingSpeak channel
  int x = ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);
  if(x == 200){
    Serial.println("Channel update successful.");
  }
  else{
    Serial.println("Problem updating channel. HTTP error code " + String(x));
  }
  
  // change the values
  number1++;
  if(number1 > 99){
    number1 = 0;
  }
  number2 = random(0,100);
  number3 = random(0,100);
  // number4 = random(0,100);
  
  delay(20000); 

}


