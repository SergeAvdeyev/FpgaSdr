#include <SoftwareSerial.h>

#include <Adafruit_GFX.h>
#include <Adafruit_SPITFT.h>
#include <Adafruit_SPITFT_Macros.h>
#include <gfxfont.h>

//#include <Adafruit_PCD8544.h>

#include <inttypes.h>

// pin 8 - Serial clock out (SCLK)
// pin 7 - Serial data out (DIN)
// pin 6 - Data/Command select (D/C)
// pin 5 - LCD chip select (CS)
// pin 4 - LCD reset (RST)
//Adafruit_PCD8544 display = Adafruit_PCD8544(8, 7, 6, 5, 4);

#include <Adafruit_ST7735.h> // Hardware-specific library
// For the breakout, you can use any 2 or 3 pins
// These pins will also work for the 1.8" TFT shield
#define TFT_CS     10
#define TFT_RST    8  // you can also connect this to the Arduino reset
                      // in which case, set this #define pin to 0!
#define TFT_DC     9

// Option 1 (recommended): must use the hardware SPI pins
// (for UNO thats sclk = 13 and sid = 11) and pin 10 must be
// an output. This is much faster - also required if you want
// to use the microSD card (see the image drawing example)
Adafruit_ST7735 display = Adafruit_ST7735(TFT_CS,  TFT_DC, TFT_RST);

//подключение энкодера
#define ENC_CLK 2
#define ENC_DT 4
#define ENC_SW 3

//подключение FPGA по UART
#define FPGA_UART_RX 10
#define FPGA_UART_TX 11
SoftwareSerial FPGASerial(10, 11); // RX, TX

int32_t freq = 7074000;
int32_t freq_phrase = 593410; //freq in hz/oscil in hz*2^bits = (freq/50000000)*4194304;
int32_t freq_phrase_new = freq_phrase;
byte mode = 1; //1-USB 0-LSB
byte mode_new = mode;
int32_t debouncing_time = 500; //Защита от дребезга контактов и энкодера в миллисекундах
int uart_timeout = 50; //таймаут запроса по uart в миллисек

//служебные переменные
#define MENU_FREQ_HZ 1
#define MENU_FREQ_KHZ 2
#define MENU_FREQ_MHZ 3
#define MENU_MODE 4
#define MENU_COUNT 4
int menu_control_current = MENU_FREQ_HZ;
String freq_string_hz;
String freq_string_khz;
String freq_string_mhz;
int enc_ALast;
int enc_AVal;
int32_t last_micros_debouncer;
String UART_answer_string;
//

void setup() { //первоначальные настройки
  //запускаем UART для отладки
  Serial.begin(115200);
  Serial.println("Hello Computer");

  //запускаем LCD
  //display.initR(INITR_BLACKTAB);
  ////display.begin();
  ////display.setContrast(60);
  //display.fillScreen(ST7735_BLACK); //display.clearDisplay();
  //display.setTextSize(1);
  ////display.setTextColor(BLACK);
  //display.setRotation(1);
  //display.setCursor(0, 0);

  display.initR(INITR_BLACKTAB);
  display.setTextWrap(false); // Allow text to run off right edge
  display.fillScreen(ST7735_BLACK);
  display.setRotation(1);

  display.setCursor(0, 0);
  display.setTextColor(ST7735_YELLOW);
  display.setTextSize(1);
  display.println("Hello world!!!");
  display.println("Hello world!!!");
  display.println("Hello world!!!");

  //запускаем прерывания для энкодера
  pinMode (ENC_DT, INPUT);
  pinMode (ENC_CLK, INPUT);
  pinMode (ENC_SW, INPUT_PULLUP);
  display.println("Hello world 0!!!");
  attachInterrupt(0, checkEncoderRotate, CHANGE);
  attachInterrupt(1, checkEncoderClick, FALLING);

  display.println("Hello world 1!!!");

  //запускаем обмен с FPGA по UART
  FPGASerial.begin(57600);
  FPGASerial.setTimeout(uart_timeout);
  display.println("Hello world 2!!!");
  freq_phrase = getFrequency();
  freq_phrase_new = freq_phrase;
  display.println("Hello world 3!!!");
  freq = getFrequencyFromPhrase(freq_phrase);
  display.println("Hello world 4!!!");
  mode = getMode();
  display.println("Hello world 5!!!");
}

void loop() { //постоянный цикл
  delay(100);
  displayInfo();
  if (freq_phrase != freq_phrase_new)
  {
    int32_t freq_from_uart = setFrequency(freq_phrase_new);
    while (freq_from_uart != freq_phrase_new)
    {
      Serial.print("wrong phase answered ANS: ");
      Serial.print(freq_from_uart);
      Serial.print(" NEED: ");
      Serial.println(freq_phrase_new);
      freq_from_uart = setFrequency(freq_phrase_new);
    }
    freq_phrase = freq_phrase_new;
  }
  if (mode != mode_new)
  {
    int32_t mode_from_uart = setMode(mode_new);
    while (mode_from_uart != mode_new)
    {
      Serial.print("wrong mode answered ANS: ");
      Serial.print(mode_from_uart);
      Serial.print(" NEED: ");
      Serial.println(mode_new);
      mode_from_uart = setMode(mode_new);
    }
    mode = mode_new;
  }
}

void checkEncoderClick() { //смена разрадности переключения частоты валкодером
  if (digitalRead(ENC_SW) == HIGH) return;
  detachInterrupt(1);

  if ((int32_t)(micros() - last_micros_debouncer) >= debouncing_time * 1000) { //защита от дребезга контактов
    if (digitalRead(ENC_SW) == LOW)
    {
      menu_control_current++;
      if (menu_control_current > MENU_COUNT) menu_control_current = 1;
    }
    last_micros_debouncer = micros();
  }
  attachInterrupt(1, checkEncoderClick, FALLING);
}

void EncoderRotated(int direction) //энкодер повернули, здесь обработчик, direction -1 - влево, 1 - вправо
{
  switch (menu_control_current) {
    case MENU_FREQ_HZ:
      freq += 100 * direction;
      setFrequencyPhrase(freq);
      break;
    case MENU_FREQ_KHZ:
      freq +=  1000 * direction;
      setFrequencyPhrase(freq);
      break;
    case MENU_FREQ_MHZ:
      freq +=  1000000 * direction;
      setFrequencyPhrase(freq);
      break;
    case MENU_MODE:
      mode_new = mode + direction;
      if (mode_new > 1) mode_new = 0;
      if (mode_new < 0) mode_new = 1;
      break;
    default:
      break;
  }
}

void checkEncoderRotate() {
  enc_AVal = digitalRead(ENC_CLK);
  if (enc_AVal != enc_ALast) { // проверка на изменение значения на выводе А по сравнению с предыдущим запомненным, что означает, что вал повернулся
    // а чтобы определить направление вращения, нам понадобится вывод В.
    if (digitalRead(ENC_DT) != enc_AVal) {  // Если вывод A изменился первым - вращение по часовой стрелке
      EncoderRotated(1);
    } else {// иначе B изменил свое состояние первым - вращение против часовой стрелки
      EncoderRotated(-1);
    }
  }
  enc_ALast = enc_AVal;
}

byte setMode(byte new_mode)
{
  //посылаем команду выбора новой моды
  Serial.print("Switching mode to: ");
  Serial.print(new_mode, DEC);
  Serial.print(" ");

  FPGASerial.write(0x08);
  FPGASerial.flush();
  FPGASerial.write(new_mode);
  FPGASerial.flush();

  byte UART_answer = readUARTByte();
  Serial.print("Answer from FPGA: ");
  Serial.println(UART_answer);
  return UART_answer;
}

byte getMode()
{
  //посылаем команду получения текущей частоты
  byte res = 0;
  FPGASerial.write(0x07);
  FPGASerial.flush();
  byte UART_answer = readUARTByte();
  Serial.print("Current mode is ");
  Serial.println(UART_answer);
  return res;
}

int32_t setFrequency(int32_t new_freq_phrase)
{
  //посылаем команду смещения текущей частоты
  Serial.print("Switching frequency to: ");
  Serial.print(new_freq_phrase);
  Serial.print(" ");

  FPGASerial.write(0x06);
  FPGASerial.flush();
  unsigned char simb = new_freq_phrase >> 24;
  Serial.print(simb, HEX);
  Serial.print(".");
  FPGASerial.write(simb);
  FPGASerial.flush();
  simb = (new_freq_phrase & (0xff << 8)) >> 16;
  Serial.print(simb, HEX);
  Serial.print(".");
  FPGASerial.write(simb);
  FPGASerial.flush();
  simb = (new_freq_phrase & (0xff << 8)) >> 8;
  Serial.print(simb, HEX);
  Serial.print(".");
  FPGASerial.write(simb);
  FPGASerial.flush();
  simb = new_freq_phrase & 0xff;
  Serial.print(simb, HEX);
  Serial.print(" ");
  Serial.print(getFrequencyFromPhrase(new_freq_phrase));
  Serial.print(" ");
  FPGASerial.write(simb);
  FPGASerial.flush();
  UART_answer_string = readUARTString();
  Serial.print("Answer from FPGA: ");
  Serial.println(UART_answer_string);
  return HexStringToInt(UART_answer_string);
}

int32_t getFrequency()
{
  //посылаем команду получения текущей частоты
  int32_t res = 0;
  FPGASerial.write(0x05);
  FPGASerial.flush();
  UART_answer_string = readUARTString();
  res = HexStringToInt(UART_answer_string);
  Serial.print("Current freq is ");
  Serial.print(UART_answer_string);
  Serial.print(" ");
  Serial.println(getFrequencyFromPhrase(res));
  return res;
}

int32_t HexStringToInt(String in) //преобразование строки шестнадцатеричного числа в число
{
  if (in.length() % 2) in = "0" + in;
  char char_array[64];
  in.toCharArray(char_array, 64);
  return strtol(char_array, NULL, 16);
}

byte readUARTByte() //считываем байт из UART
{
  long starttime = millis();
  while (FPGASerial.available() == 0 && (millis() - starttime < uart_timeout)) { }
  byte res = FPGASerial.read();
  return res;
}

String readUARTString() //считываем строку из UART до символа \n (не включительно)
{
  long starttime = millis();
  String inString = "";
  while (FPGASerial.available() == 0 && (millis() - starttime < uart_timeout)) { }
  char inChar = (char)FPGASerial.read();
  while (inChar != '\n') {
    if (millis() - starttime > uart_timeout) return "TIMEOUT";
    if (FPGASerial.available() > 0)
    {
      inString += (char)inChar;
      inChar = FPGASerial.read();
    }
  }
  return inString;
}

void setFrequencyPhrase(int32_t new_freq) //высчитываем фазу частоты для FPGA
{
  if (freq < 0) freq = 0;
  if (new_freq < 0) new_freq = 0;
  freq_phrase_new = round(((float)new_freq / 50000000) * 4194304); //freq in hz/oscil in hz*2^bits = (freq/50000000)*4194304;
  Serial.print("Encoder set new frequency phase to ");
  Serial.print(freq_phrase_new);
  Serial.print(" ");
  Serial.println(new_freq);
}

int32_t getFrequencyFromPhrase(int32_t phrase) //высчитываем фазу частоты для FPGA
{
  return round(((float)phrase / 4194304) * 50000000 / 100) * 100; //freq in hz/oscil in hz*2^bits = (freq/50000000)*4194304;
}

void displayInfo() { //вывод информации на экран
  display.fillScreen(ST7735_BLACK); //display.clearDisplay();
  display.setCursor(0, 0);
  display.setTextSize(1);

  //добавляем пробелов для вывода частоты
  freq_string_hz = String(freq % 1000);
  freq_string_khz = String((int32_t)(freq / 1000) % 1000);
  freq_string_mhz = String((int32_t)(freq / 1000000) % 1000000);

  if (menu_control_current == MENU_FREQ_MHZ)
    display.setTextColor(ST7735_WHITE); //display.setTextColor(WHITE, BLACK);
  display.print(freq_string_mhz);
  display.setTextColor(ST7735_YELLOW); //display.setTextColor(BLACK, WHITE);
  display.print(".");

  if (menu_control_current == MENU_FREQ_KHZ)
    display.setTextColor(ST7735_WHITE); //display.setTextColor(WHITE, BLACK);
  display.print(addNuls(freq_string_khz));
  display.setTextColor(ST7735_YELLOW); //display.setTextColor(BLACK, WHITE);
  display.print(".");

  if (menu_control_current == MENU_FREQ_HZ)
    display.setTextColor(ST7735_WHITE); //display.setTextColor(WHITE, BLACK);
  display.print(addNuls(freq_string_hz));
  display.setTextColor(ST7735_YELLOW); //display.setTextColor(BLACK, WHITE);
  display.print(" ");

  if (menu_control_current == MENU_MODE)
    display.setTextColor(ST7735_WHITE); //display.setTextColor(WHITE, BLACK);
  if (mode == 1) display.println("USB");
  if (mode == 0) display.println("LSB");
  //display.setTextColor(BLACK, WHITE);

  //display.display();
}

String addNuls(String str) //добавляем нули, чтобы получить по 3 в группе
{
  if (str.length() == 1) return "00" + str;
  if (str.length() == 2) return "0" + str;
  return str;
}
