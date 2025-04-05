#include <ArduinoBLE.h>
#include "Nano33BLEAccelerometer.h"
#include "Nano33BLEGyroscope.h"
#include "Nano33BLEMagnetic.h"

BLEService customService("19B10000-E8F2-537E-4F6C-D104768A1214"); // Definizione del servizio BLE personalizzato

// Definizione delle caratteristice per gli assi dell'accelerometro
BLEFloatCharacteristic xAccelCharacteristic("19B10001-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);
BLEFloatCharacteristic yAccelCharacteristic("19B10002-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);
BLEFloatCharacteristic zAccelCharacteristic("19B10003-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);

// Definizione delle caratteristice per gli assi del giroscopio
BLEFloatCharacteristic xGyroscopeCharacteristic("19B10021-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);
BLEFloatCharacteristic yGyroscopeCharacteristic("19B10022-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);
BLEFloatCharacteristic zGyroscopeCharacteristic("19B10023-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);

// Definizione delle caratteristice per gli assi del magnetometro
BLEFloatCharacteristic xMagCharacteristic("19B10031-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);
BLEFloatCharacteristic yMagCharacteristic("19B10032-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);
BLEFloatCharacteristic zMagCharacteristic("19B10033-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);

BLEIntCharacteristic timeStampCharacteristic("19B10041-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify); // Definizione della caratteristica per il timestamp di misurazione

// DICHIARAZIONE DEI SENSORI UTILIZZATI
Nano33BLEAccelerometerData accelerometerData; // Accelerometro
Nano33BLEGyroscopeData gyroscopeData; // Giroscopio
Nano33BLEMagneticData magneticData; // Magentometro

void setup() {
  // Inizializzazione dell'accelerometro
  Accelerometer.begin();

  // Inizializzazione del giroscpio
  Gyroscope.begin();

  // Inizializzazione del magnetometro
  Magnetic.begin();

  Serial.begin(9600); // Seriale utilizzata per debug 
  while (!Serial);
  
  if (!BLE.begin()) { // Bluetooth Low Energy (BLE)
    Serial.println("Errore BLE!");
    while (1);
  }

  BLE.setLocalName("ArduinoNano33"); // Impostazione del nome del dispositivo BLE

  BLE.setAdvertisedService(customService); // Aggiunta del servizio BLE

  // Aggiunta delle caratteristiche dell'accelerometro al servizio BLE
  customService.addCharacteristic(xAccelCharacteristic);
  customService.addCharacteristic(yAccelCharacteristic);
  customService.addCharacteristic(zAccelCharacteristic);

  // Aggiunta delle caratteristiche del giroscopio al servizio BLE
  customService.addCharacteristic(xGyroscopeCharacteristic);
  customService.addCharacteristic(yGyroscopeCharacteristic);
  customService.addCharacteristic(zGyroscopeCharacteristic);

  // Aggiunta delle caratteristiche del magnetometro al servizio BLE
  customService.addCharacteristic(xMagCharacteristic);
  customService.addCharacteristic(yMagCharacteristic);
  customService.addCharacteristic(zMagCharacteristic);

  //caratteristiche temporali
  customService.addCharacteristic(timeStampCharacteristic); // Aggiunta della caratteristica temporale al servizio BLE

  BLE.addService(customService); // Aggiunta del servizio BLE

  BLE.advertise(); // Pubblicazione del servizio BLE
  Serial.println("In attesa di una connessione BLE...");
}

void loop() {
  static auto lastCheck = millis();
  BLEDevice central = BLE.central(); // Attesa della connessione al canale BLE da parte di un altro dispositivo

  if (central) { // Connessione eseguita
    Serial.print("Connesso a: ");
    Serial.println(central.address());

    while (central.connected()) {        
        if (millis() - lastCheck >= 10 && Accelerometer.pop(accelerometerData) && Gyroscope.pop(gyroscopeData) && Magnetic.pop(magneticData)) {
        lastCheck = millis();

        // Lettura del valore dei  3 assi dell'accelerometro
        float xAccelValue = accelerometerData.x; 
        float yAccelValue = accelerometerData.y;
        float zAccelValue = accelerometerData.z;

        // Lettura del valore dei  3 assi del giroscopio
        float xGyroscopeValue = gyroscopeData.x;
        float yGyroscopeValue = gyroscopeData.y;
        float zGyroscopeValue = gyroscopeData.z; 

        // Lettura del valore dei  3 assi del magnetometro
        float xMagValue = magneticData.x;
        float yMagValue = magneticData.y;
        float zMagValue = magneticData.z;

        // Invio sul canale BLE dei valori dei 3 assi dell'accelerometro
        xAccelCharacteristic.writeValue(xAccelValue); 
        yAccelCharacteristic.writeValue(yAccelValue);
        zAccelCharacteristic.writeValue(zAccelValue);
        
        // Invio sul canale BLE dei valori dei 3 assi del giroscopio
        xGyroscopeCharacteristic.writeValue(xGyroscopeValue);
        yGyroscopeCharacteristic.writeValue(yGyroscopeValue);
        zGyroscopeCharacteristic.writeValue(zGyroscopeValue);

        // Invio sul canale BLE dei valori dei 3 assi del magnetometro
        xMagCharacteristic.writeValue(xMagValue);
        yMagCharacteristic.writeValue(yMagValue);
        zMagCharacteristic.writeValue(zMagValue);

        timeStampCharacteristic.writeValue(lastCheck); // Invia il valore del timestamp
      }
    }
    Serial.println("Connessione persa");
  }
}