#include <DmxSimple.h>

#include <SoftwareSerial.h>

/*


*/
int RXPin = 10;
int TXPin = 11;
//INCLUDES
//



SoftwareSerial impSerial(RXPin,TXPin);
//
// BASIC VARS TO SET 
//
int red = 0;
int green = 0;
int blue = 0;
int flag = 0;
int fade1 = 256;

int fadeReset= 256;// a reset value for the faders
int val=0;
//int peak = 300;//THE ANALOG INPUT THRESHOLD ON THE MIC
int peak = 400;//BOX 5
//int peak = 300;//BOX 2
//int peak = 500;//THE LEVEL OF BOX 3 WAS AMBIENTLY MUCH HIGHER

int timeControl = 100;//set a slowing rate for fades  here this will be a delay measured in millis
int rate = 4; // also for setting the rate at which the fade occurs. 1 i standard 2 is double etc
int baudRate = 9600;//THE BAUD RATE USED FOR SERIAL COMMS - MUST MATCH THAT OF THE IMP

//
//COMMS INFO
//
//TO DO!!!
//ALL THE VARS BELOW ARE SET DIRECTLY AND NOT USING THESE VALUES!!
String boxOn = "s";// THE CHAR WE ARE USING AS AN ON SIGNAL
String boxOff = "b";// TEH CHAR WE ARE USING AS AN OFF SIGNAL
String state1 = "2";// THE CHAR WE SEND WHEN WE ARE IN STATE 2: BOX ON
String state2 = "1";// THE CHAR WE SEND WHEN WE ARE IN STATE 1: BOX OFF
String state3 = "3";// THE CHAR WE SEND WHEN WE ARE IN STATE 3: BOX HELD (THIS MEANS SOMEONE IS BLOWING IT)
//
//Stuff for the win lose lights
String winState = "none";//this is set to the current win state.
boolean fearCheck = false;//a bool to use a s as flag to contol teh pause at teh start of the lose lights
int fade2 = 0;
boolean houseLive = false; //a bool to replace boxLive in the house lights mode
//
//THINGS TO ACTIVATE
//
boolean boxLive = false; 





void setup() {
  // put your setup code here, to run once:
  impSerial.begin(baudRate);
  Serial.begin(baudRate);
  DmxSimple.usePin(2);
  DmxSimple.maxChannel(4);
//

}

void loop() {
  // THE COMMS BIT
  char c = impSerial.read();
  if(impSerial){
   //Serial.println("impSerial = ");
 // Serial.println(c); 
  }

  if(String(c)== "s"){
    boxLive=true;
      Serial.println("we have an s");
      // impSerial.write(state1);//SEND STATE "1" BOX ON, TO THE IMP
      impSerial.write("2");//SEND STATE "2" BOX ON, TO THE IMP
      fade1=fadeReset;
      Serial.write("Box On!");
  }else if(String(c)== "b"){
    boxLive=false;
    Serial.println("we have a b");
    //impSerial.write(state2);//SEND STATE "2" BOX OFF, TO THE IMP
    impSerial.write("1");//SEND STATE "1" BOX OFF, TO THE IMP
    boxLive=false;
    fade1=0;
  } else if (String(c) == "w") {
    //win lights are go
   // boxLive=false;
    houseLive = true;
    winState = "win";
    // setLight(c);

  } else if (String(c) == "l") {
    //lose lights are go
   // boxLive=false;
    houseLive = true;
    winState = "lose";
    //setLight(c);
  }else if (String(c) == "r") {
    //reset the lights
    
    winState = "none";
    //Serial.println("reset called");
  }
  //
  //THE SOUND ACTIVATION BIT
  //
  delay(10);
  val = analogRead(0);
  Serial.println(val);
  updateLightState();
  delay(100);
  //
  //THE SIMPLE FADE DOWN
  setLight();// 
  setWinLight();
  
}

//
void setLight(){
  if(boxLive==true){
    if(fade1 > 0){
      fade1-=rate;
      Serial.println(fade1);
    }else{
    //impSerial.write(state2);//SEND STATE 2 "BOX OFF" TO THE IMP
    impSerial.write("1");//SEND STATE 1 "BOX OFF" TO THE IMP
    Serial.println("Box Off");
    boxLive=false;
  }
    delay(timeControl);// a calibration var that allows us to slow down the loop update rate
    DmxSimple.write(3, fade1);
    DmxSimple.write(2, fade1);
    DmxSimple.write(1, fade1);
  }
}
void updateLightState(){
  //CHECK TO SEE IF THERE LIGHT IS CURRENTLY ACTIVE 
  //AND IF IT IS CHECK TO SEE IF THE SOUND INPUT IS HIGH
  //IF IT IS RESET THE FADE LEVEL TO HIGH
  if(boxLive==true){
    if(fade1>=1){
      if(val>peak){
        Serial.println(val);
        Serial.write("Box Held");
        fade1=fadeReset;
        //impSerial.write(state3);// SEND STATE 3 "HELD" TO THE IMP
        impSerial.write("3");// SEND STATE 3 "HELD" TO THE IMP
      }
    }
  }
}
//
void setWinLight() {
  if (houseLive == true) {
    //
    //LIGHTS FOR WINNERS
    //
     if(winState=="win"){
       //
        if(fade2 <= (255-rate)){
        fade2+=rate;
         Serial.println("ping");
         //locDelay=0;
        }
        //Serial.println("win light");
       // DmxSimple.write(3, fade2);
        DmxSimple.write(2, fade2);
        //DmxSimple.write(1, fade2);
       //
     }
     //
     //LIGHTS FOR LOSERS
     //
     else if(winState=="lose"){
       if (fearCheck==false){
         delay(3000);
         fearCheck = true;
         Serial.println("fearCheck");
       }
       if(fade2 <= (254-rate)){
          fade2+=rate;
          // delay(100);
       }
       //DmxSimple.write(3, fade2);
       DmxSimple.write(1, fade2);
       // DmxSimple.write(1, fade2);
    }
    //
    //RESET STUFF
    //
    else if(winState=="none"){
        DmxSimple.write(3, 0);
        DmxSimple.write(2, 0);
        DmxSimple.write(1, 0);
        houseLive=false;
        fearCheck = false;
        fade2=0;
    }
    //
    delay(100);// a calibration var that allows us to slow down the loop update rate
  //  Serial.println("fade2= ");
    Serial.println(fade2);
  } 
}

