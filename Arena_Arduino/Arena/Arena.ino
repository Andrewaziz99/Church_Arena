/*
===========================================
 Quiz Buzzer System
 Arduino Uno
===========================================

Buttons:
Team 1 -> D2
Team 2 -> D3
Team 3 -> D4
Team 4 -> D5

LEDs:
Team 1 -> D6
Team 2 -> D7
Team 3 -> D8
Team 4 -> D9

Buzzer:
D10

Communication:
9600 baud

Arduino -> Flutter
TEAM_1
TEAM_2
TEAM_3
TEAM_4

Flutter -> Arduino
RESET

===========================================
*/

const int buttonPins[] = {2, 3, 4, 5};
const int ledPins[] = {6, 7, 8, 9};
const int buzzerPin = 10;

bool locked = false;
int winner = -1;

void setup() {

  Serial.begin(9600);

  for (int i = 0; i < 4; i++) {
    pinMode(buttonPins[i], INPUT_PULLUP);
    pinMode(ledPins[i], OUTPUT);
    digitalWrite(ledPins[i], LOW);
  }

  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, LOW);

  Serial.println("READY");
}

void loop() {

  checkButtons();

  checkSerial();
}

void checkButtons() {

  if (locked)
    return;

  for (int i = 0; i < 4; i++) {

    if (digitalRead(buttonPins[i]) == LOW) {

      delay(20);

      if (digitalRead(buttonPins[i]) == LOW) {

        winner = i;
        locked = true;

        digitalWrite(ledPins[i], HIGH);

        tone(buzzerPin, 1200, 250);

        Serial.print("TEAM_");
        Serial.println(i + 1);

        while (digitalRead(buttonPins[i]) == LOW);

        break;
      }
    }
  }
}

void checkSerial() {

  if (!Serial.available())
    return;

  String command = Serial.readStringUntil('\n');

  command.trim();

  if (command == "RESET") {

    resetGame();
  }
}

void resetGame() {

  locked = false;
  winner = -1;

  for (int i = 0; i < 4; i++) {
    digitalWrite(ledPins[i], LOW);
  }

  noTone(buzzerPin);

  Serial.println("RESET_DONE");
}