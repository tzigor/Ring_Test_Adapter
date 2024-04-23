#include <EEPROM.h>

const int ledPin = 3;
const int buttonPin = 4;
const int solenoidPin = 6;
const uint16_t buttonHoldTime = 100;  // mSec

unsigned long currentMillis;
unsigned long PreMillisForBlink = 0;
unsigned long PreMillisForCycle = 0;
unsigned long PreMillisForHold = 0;
unsigned long PreMillisForHoldButton = 0;
unsigned long PreMillisForSafety = 0;

byte currentStep = 1;
bool notSafety = false;
bool buttonPressed = false;

bool cycleStarted = false;
bool ledOn = true;
uint32_t steps[14];
uint16_t holdTime;
uint16_t skipedStepTime;
byte solednoidPower;
uint16_t memValue;

uint16_t blinkPeriod;

int32_t stepTime;

void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(solenoidPin, OUTPUT);
  pinMode(buttonPin, INPUT);
  pinMode(buttonPin, INPUT_PULLUP);
  Serial.begin(9600);
  Serial.flush();
  holdTime = eeprom_read_word((uint16_t*)28);
  skipedStepTime = eeprom_read_word((uint16_t*)30);
  solednoidPower = EEPROM.read(32);
  for ( int i=0; i <= 13; i++ ) {
    memValue = (uint16_t*)eeprom_read_word((uint16_t*)(i * 2));
    steps[i] = (uint32_t)memValue * 1000;
    if (steps[i] == 0) steps[i] = skipedStepTime;
  }
  digitalWrite(ledPin, HIGH);
  blinkPeriod = 500; 
}

String input = "";
String dataOutput = "";
String wStr = "";
byte paramNumber = 0;
word pramToWrite;

void loop() {
  
  currentMillis = millis(); 

  while (Serial.available()) {
      input = Serial.readString();
      byte inputLen = input.length();
      if (input == "query") {
          for ( int i=0; i <= 13; i++ ) dataOutput += String((uint16_t)(steps[i] / 1000)) + ";";
          dataOutput += String(holdTime) + ";";
          dataOutput += String(skipedStepTime) + ";";
          dataOutput += String(solednoidPower) + ";";
          Serial.print(dataOutput);
          input = "";
      }
      else if (inputLen > 36) {   
              for ( int i=0; i < inputLen; i++ ) {
                if (input[i] != ';') wStr += input[i];
                else {
                  if (paramNumber < 17) {
                    eeprom_write_word((uint16_t*)(paramNumber * 2), (uint16_t)wStr.toInt()); 
                  }
                  else EEPROM.write(32, (byte)wStr.toInt());
                  wStr = "";
                  paramNumber++;
                }
              }
//              Serial.print(input);
              Serial.print("success");
              input = "";
           } 
  }


  if (digitalRead(buttonPin) == LOW) {
    PreMillisForHoldButton = currentMillis;
    while (digitalRead(buttonPin) == LOW) { 
      currentMillis = millis(); 
    }
    delay(10);
    if ( currentMillis - PreMillisForHoldButton > buttonHoldTime ) buttonPressed = true;
  } else buttonPressed = false; 

  if (buttonPressed) {
    blinkPeriod = 500; 
    cycleStarted = !cycleStarted;
    if (cycleStarted) PreMillisForCycle = currentMillis;
    else {
      currentStep = 1;
      ledOn = true;
      digitalWrite(ledPin, HIGH);
    }
  }

  if (cycleStarted) {
    if ( currentMillis - PreMillisForCycle > steps[currentStep - 1] ) {
        PreMillisForCycle = currentMillis; 
        if (currentStep == 13) blinkPeriod = 60; 
        if (currentStep < 14) {
          analogWrite(solenoidPin, 150);
          delay(30);
          analogWrite(solenoidPin, solednoidPower);
          digitalWrite(LED_BUILTIN, HIGH);
          PreMillisForHold = currentMillis;
          currentStep++;
        }  
        else {
          cycleStarted = false;
          analogWrite(solenoidPin, 0);
          digitalWrite(LED_BUILTIN, LOW);
          currentStep = 1;
          ledOn = true;
          digitalWrite(ledPin, HIGH);
        }
    }
    if ( currentMillis - PreMillisForHold > holdTime ) {
        analogWrite(solenoidPin, 0);
        digitalWrite(LED_BUILTIN, LOW);
    }    
  }
  
  if ( currentMillis - PreMillisForBlink > blinkPeriod ) {
      PreMillisForBlink = currentMillis;
      ledOn = !ledOn;
      if (ledOn) digitalWrite(ledPin, HIGH);
      else if (cycleStarted) digitalWrite(ledPin, LOW); 
  }    
}

/* EEPROM Map:
0 - Step1 (Lo) in sec
1 - Step1 (Hi) 
...
26 - Step14 (Lo) (Step number - 1) * 2
27 - Step14 (Hi) 
28 - Hold time in msec (Lo)
29 - Hold time in msec (Hi)
30 - skipedStepTime (Lo)
31 - skipedStepTime (Hi)
32 - Solednoid power 0-255
 */
 
