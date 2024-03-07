#include <EEPROM.h>

const int ledPin = 3;
const int buttonPin = 4;
const int solenoidPin = 6;

unsigned long currentMillis;
unsigned long PreMillisForBlink = 0;
unsigned long PreMillisForCycle = 0;
unsigned long PreMillisForHold = 0;
unsigned long PreMillisForSafety = 0;

byte currentStep = 1;
bool notSafety = false;

bool cycleStarted = false;
bool ledOn = true;
int16_t steps[12];
int16_t holdTime;
byte solednoidPower;
int skipedStepTime;
int32_t stepTime;

void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(solenoidPin, OUTPUT);
  pinMode(buttonPin, INPUT);
  Serial.begin(9600);
  Serial.flush();
  for ( int i=0; i <= 11; i++ ) {
    steps[i] = eeprom_read_word((uint16_t*)(i * 2));
  }
  if (steps[0] == 0) stepTime = skipedStepTime;
  else stepTime = steps[0] * 1000;
  holdTime = eeprom_read_word((uint16_t*)24);
  skipedStepTime = eeprom_read_word((uint16_t*)26);
  solednoidPower = EEPROM.read(28);
  digitalWrite(ledPin, HIGH);
}

String input = "";
String dataOutput = "";
String wStr = "";
byte paramNumber = 0;

void loop() {
  
  currentMillis = millis(); 

  while (Serial.available()) {
      input = Serial.readString();
      byte inputLen = input.length();
      if (input == "query") {
          for ( int i=0; i <= 11; i++ ) dataOutput += String(steps[i]) + ";";
          dataOutput += String(holdTime) + ";";
          dataOutput += String(skipedStepTime) + ";";
          dataOutput += String(solednoidPower) + ";";
          Serial.print(dataOutput);
          input = "";
      }
      else if (inputLen > 26) {   
              for ( int i=0; i < inputLen; i++ ) {
                if (input[i] != ';') wStr += input[i];
                else {
                  if (paramNumber < 15) {
                    eeprom_write_word((uint16_t*)(paramNumber * 2), (uint16_t)wStr.toInt()); 
                  }
                  else EEPROM.write(28, (byte)wStr.toInt());
                  wStr = "";
                  paramNumber++;
                }
              }
              Serial.print("success");
              input = "";
           } 
  }

  if (digitalRead(buttonPin) == LOW) {
    cycleStarted = !cycleStarted;
    while (digitalRead(buttonPin) == LOW) {};
    delay(100);
    if (cycleStarted) PreMillisForCycle = currentMillis;
    else {
      currentStep = 1;
      if (steps[currentStep - 1] == 0) stepTime = skipedStepTime;
      else stepTime = steps[currentStep - 1] * 1000;
      ledOn = true;
      digitalWrite(ledPin, HIGH);
    }
  }

  if (cycleStarted) {
    if ( currentMillis - PreMillisForCycle > stepTime ) {
        PreMillisForCycle = currentMillis;
        analogWrite(solenoidPin, solednoidPower);
        digitalWrite(LED_BUILTIN, HIGH);
        PreMillisForHold = currentMillis;
        if (currentStep < 12) {
          currentStep++;
          if (steps[currentStep - 1] == 0) stepTime = skipedStepTime;
          else stepTime = steps[currentStep - 1] * 1000;
        }
        else {
          cycleStarted = false;
          analogWrite(solenoidPin, 0);
          digitalWrite(LED_BUILTIN, LOW);
          currentStep = 1;
          if (steps[currentStep - 1] == 0) stepTime = skipedStepTime;
          else stepTime = steps[currentStep - 1] * 1000;
          ledOn = true;
          digitalWrite(ledPin, HIGH);
        }
    }
    if ( currentMillis - PreMillisForHold > holdTime ) {
        analogWrite(solenoidPin, 0);
        digitalWrite(LED_BUILTIN, LOW);
    }    
  }
  
  if ( currentMillis - PreMillisForBlink > 300 ) {
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
22 - Step12 (Lo) Step number * 2 - 1
23 - Step12 (Hi) 
24 - Hold time in msec (Lo)
25 - Hold time in msec (Hi)
26 - skipedStepTime (Lo)
27 - skipedStepTime (Hi)
28 - Solednoid power 0-255
 */
 