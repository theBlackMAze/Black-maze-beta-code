/*
SJ SERVER script 
This Squirrel code is to control the comms of several imps and the slingshot biodata app
This code also controls one of the imps directly.

Bioharness data: 
The Biodata app will report threshold values to this url
these values will be stored in a var in this script
The data will then be tested against the active imps required threshold 
if the test is positive the relavant imp will be switched on

Imps/ devices:
each of the imps in the system will send an on flag once they are active
This can be set via  a push button on the device itself or via a url
The flag var (array) just sets an imp to active or inactive. 
The script will deactivate all other imps on reciept of an imp active message
This data will be sent as a url var such as imp1=1 to activate imp1
At this stage all imps states are boolian:
active/inactive: to denote which imp is being used 
on/off Sending a 1 or a 0 to the imp to start or stop its process
The processes vary on the imps/ devices but the structure and the comms remain the same
Some of the outputs are not imps but external urls.
The external urls operate in the same way as the imps though they may not trigger the active state with a switch but via a url alone
*/

/*
THE BLACKMAZE MODIFICATIONS - EXTENDING THE EXISTING SERVER CODE 
PLAN
TO SELECT THE CURRENT BIO DEVICE (PHONE + HEARTATE MONITOR COMBO)
TO RECIEVE THRESHOLD EVENTS FROM THAT DEVICE
SET UP CONTROL LOGIC BASED ON GAME DESIGN THAT USES THOSE THRESHOLDS
SEND OUT DEVICE STATES TO BOXES
RECIEVE DEVICE STATE UPDATES FROM THE BOXES
RECIEVE GAME STATE EVENTS FROM THE ADMIN INTERFACE
//
THE ADMIN INTERCFACE WILL SEND THE FOLLOWING DATA
CURRENT DEVICE
GAME START
GAME STOP
//
THE ADMIN INTERFACE WILL REQUEST THE FOLLOWING DATA
DEVICE STATE
ACTIVE DEVICE
GAME STATE - LIVE:Bool, 
BOX/S STATE - ACTIVATED:Bool, HELD ACTIVE:Bool
PLAYER STATE -THRESHOLDS SENT:String , HEARTBEATS REMAINING:Int 
//
//

TODO:
JSON SEND A ON START UP MESSAGE INC
WHICH DEVICE IS IN PLAY
HOW MANY BOXES THERE ARE
WHAT ARE THE TRIGGER EVENTS FOR THOSE BOXED

TODO:
DEVICE SELECTION




*/

//activeDev <-null;
//
//VARIABLES AND DATA
//
// a var to store the active imp (was an array but a var works better)
activeImp <- 0; 
//
const adminURL = "http://www.evans-studio.net/blackmaze/squirrelParser1.php";// the admin page

//a var for the biodata states
bdThresh <- null;
//a flag to control whether we are sending data about control lights or other mechanisms
// 0 will mean we are not sending light messages, 
//1 will mrn we are
//We can also use this flag as the var to send to the imps to set their light state
lightFlag <- 0;
lightPass <- 0;
// device/ imp urls
//TODO: UPDATE VAR NAMES TO MATCH BOXES, 
/*doorURL <- "https://agent.electricimp.com/I1n1OyjmGxj8";
zoeURL <- "https://agent.electricimp.com/eO8OUNZDiM_x";
vidURL <- "http://msge.slingshoteffect.co.uk/electric-imp-jekyll.php";
boxURL <- "https://agent.electricimp.com/d3fDLJPFktfW";
box2URL <- "https://agent.electricimp.com/ggu_f5Ydzxqt";
vidImp <- "https://agent.electricimp.com/pTThigr9Z9A4";
*/
//Box1 <- "https://agent.electricimp.com/I1n1OyjmGxj8";
//Box1 <- "https://agent.electricimp.com/5j-Am5M5g39H";

Box2 <- "https://agent.electricimp.com/eO8OUNZDiM_x";
Box5 <- null;

Box3 <-"https://agent.electricimp.com/eksaCXlDLHF8";
//Box4 <- "https://agent.electricimp.com/pTThigr9Z9A4";
Box4 <- "https://agent.electricimp.com/4Pt_T0st737U";
Box1 <- "https://agent.electricimp.com/d3fDLJPFktfW";//
//
Box0 <- "https://agent.electricimp.com/ggu_f5Ydzxqt";//This is the house lights
//
box1Val <-"Blowing";
//box2Val <-"BreathingInOut";
box2Val <-"Leaning";
box3Val <-"2";
box4Val <-"HoldingBreath";
box5Val <- "BreathingIn"

// an array to store the imp and device urls in
impURLs <- [Box0, Box1, Box2, Box3, Box4, Box5];
//data to send to devices to switch them off once inactive(not currenly implemented)
//endData <- [null, "box=0", "servo=0", "", "servo=0"];
//
//NEW VARS FOR BLACK MAZE
//
//THE DEVICES
//device1<-"d4cf215f8cafe19";//samsung mini
device1 <- "8cb68d57dbeca3bb";//moto e 1
//device2<-"39457e6f7e316c5";//nexus
device2 <- "4cfac9f60541984e";//moto e 2
device3 <- "238fe0c27b14661a";//moto e 3
device4 <- "4bef965f44f2e42e";//moto e 4
devId <- [null,device1,device2,device3,device4];
//
device1Time<-0;
device2Time<-0;
device3Time<-0;
device4Time<-0;
device5Time<-0;
//
deviceTimes <- [null,device1Time,device2Time,device3Time,device4Time,device5Time];//the time stamp of the latest device update
deviceTimeOut <- 45;//time elapsed until device times out
//
deviceCheckTimer <-null;// teh var for the imp.wakeup loop
//
box1Id <-"2313394cead3dbee";
boxId <- [null, box1Id];
//TODO the rest of  the box id's 

activeDevice <-null;//which device is set to be used in the maze
sendDevice<-null;// the id of the device sending data
device1Live<-false;
device2Live<-false;
device3Live<-false;
device4Live<-false;
liveDev<-[null,device1Live,device2Live, device3Live, device4Live, device4Live];
//
deviceName <- [null,"device1Live","device2Live","device3Live","device4Live","device5Live"];
//
//THE GAME VARS
gameLive <- false;// is the game live or not 
heartBeatLimit<- 1000; //How many heart beats in the game
heartBeatCount<-0;//How many heartbeats used
//
boxTriggerTime<-10000;//time box stays triggered for in milliseconds
box1Triggered<-false;// box will be triggered or not
box2Triggered<-false;
box3Triggered<-false;
box4Triggered<-false;
box5Triggered<-false;
//

//
boxHoldDuration<-10000;//how long will an action hold a box in state
box1Held<-false;// box will be held or no, this is a player keeping the box in state with a button or a mic
box2Held<-false;
box3Held<-false;
box4Held<-false;
box5Held<-false;
//
//data to send
//boxSendData <- [null, "data=s","data=b","data=tt$"+boxTriggerTime, "data=ht$"+boxHoldDuration];//BLACKMAZE
boxSendData <- [null, "data=s","data=b", "data=w", "data=l", "data=r"];// s= box on, b = box off, w = lights to win state, l = lights to lose state, r = reset lights
adminSendData <- ["activeDevice", "box1State", "box2State", "box3State", "box4State", "box5State", "heartBeatLimit", "game", "setDevice"];
//
//
heartrateRaw<-0;
//Could do resprate too
//
// HEART RATES BELOW ARE SET TO THE AVERAGE OF TEH RANEG
// THE ACTUAL THRESHOLDS ARE NOTED BESIDES THEM
greenHeart<-65;//<70
yellowHeart<-75;//70 - 80
orangeHeart<-85;//80 - 90
redHeart<-95;//>90
//
interval<-1.01;//HOW MANY SECONDS BETWEEN BEATS, CALCULATED USING HEART RATE VALUES ABOVE
//
heartState<-65;// A VAR FOR HOLDING THE CURRENT HEART THRESHOLD STATE. DEFAULTS TO 65
//
testCounter<-0;//JUST A VAR TO TEST HOW MANY TIMES A FUNCTION IS CALLED
//
heartBeatTimer<-null;// THIS WILL BE OUR IMP.WAKEUP LOOP TO CANCEL AND THEN START AGAIN.

//FUNCTIONS
//
// doing something with the response from the http request
function processResponse(resp) {
  //server.log("the server status code was " + resp.statuscode);
}


// The Simple HTTP bit 
function simpleHttp(d1,d2, admin){
    if(!admin){
           //Build the url to call in a var called url
           local url= impURLs[d1] + "?" + boxSendData[d2];
           local request = http.get(url);
           request.sendsync();
           //imp.sleep(8);//can't remeber the merit n this
    }else if(admin){
        
        local url= adminURL + "?" + d1+"="+d2;
           local request = http.get(url);
           request.sendsync();
    }
}


// get the incoming data and set our vars with it
function testIncoming(request, response){
    /*
    BLACKMAZE
    POSS TEST FOR ID OF INCOMING DATA BEFORE IMPLEMENTING IT
    LOOK FOR DATA REQUESTS AND CALL A RESPONSE FUNCTION
    LOOK THROUGH ALL INCOMING DATA THOUGH AND DONT BREAK ON A TRY CATCH LOOP AS WE CURRENTLY DO
    //
    SPECIFICS
    //
    LOOK FOR BIODATA THRESHOLDS AND UPDATE THE RELAVENT VAR
    LOOK FOR BOX STATES AND UPDATE THEIR RELAVANT VARS
    Call a function to process the changes an onUpdate() function
    UPDATE ANY CHANGES TO THE LIVE PAGE (VIA JSON?)
    */
  // server.log("testIncoming() is being called");
   // locL <-request.query.len();
 //  server.log("request length reads as "+locL);
    //LOOP THROUGHTEH INCOMING REQUEST
    foreach(key, value in request.query){
    //CHECK FOR EVERY VALUE THEN HAND ANY WE FIND TO THE threshHold() function
    
    //MATRIX VIEW!!!
    /*
    server.log("key = = "+key);
    server.log("value = = "+value);
    */
    
    
//  CHECK THE VAUES VIA KEY
     
     switch(key){
        case "test1":
             //server.log("test 1 found");
             break
        case "test2" :
            //server.log("test 2 found");
            break
        case "uniqueID":
            //server.log("uniqueId in test incoming")
            setVal(key, value,false);//get the unique id of the device that is sending the data
            break
        case "setDevice":
            setVal(key, value, false);//set the the current device
            setVal(key, value, true);
           // simpleHTTP(key,value,true );
        case "rawHeart":
            threshHold(key, value);
            break
        case "game":
            setVal(key, value, false);
            setVal(key, value, true);
            //simpleHTTP(key,value,true );
            break
        case "boxTriggerTime":
            setVal(key, value,false);//these are game vars so we cal setVal to set them
            break
        case "boxHoldDuration":
            setVal(key, value,false);
            // simpleHTTP(key, value ,true );
            break
        case "heartBeatLimit":
            setVal(key, value, false);
            setVal(key, value, true);
            //simpleHTTP(key, value ,true );
            break
        case "heartrate":
            threshHold(key, value);
            break
        
        case "breath":
            threshHold(key, value);
            break
        case "posture":
            threshHold(key, value);
           // server.log("posture event = "+ value);
            break
        case "accelerometer":
            threshHold(key, value);
            //server.log("accelerometer event = "+ value);
            break    
        case "box1Val"://the threshold that will trigger the box
            box1Val=value;
            simpleHttp(key, value, true);
            //server.log("box 1 set to trigger when "+value);
            break
        case "box2Val"://the threshold that will trigger the box
            box2Val=value;
            simpleHttp(key, value, true);
            //server.log("box 2 set to trigger when "+value)
            break
        case "box3Val"://the threshold that will trigger the box
            box3Val=value;
            simpleHttp(key, value, true); 
            //server.log("box 3 set to trigger when "+value)
            break
        case "box4Val"://the threshold that will trigger the box
            box4Val=value;
            simpleHttp(key, value, true);  
            //server.log("box 4 set to trigger when "+value)
            break
        case "box5Val"://the threshold that will trigger the box
            box4Val=value;
            simpleHttp(key, value, true);  
            server.log("box 5 set to trigger when "+value)
            break    
        case "box1State":
            if(value=="3"){
                box1Held=true;
            }else if (value=="1"){
                box1Held=false;
            }
            
            boxTest();
            simpleHttp(key, value, true); 
            //server.log(key +" = "+ value);
            //
            break
        case "box2State":
            if(value=="3"){
                box2Held=true;
            }else if (value=="1"){
                box2Held=false;
            }
            boxTest();
            simpleHttp(key, value, true); 
            //server.log(key +" = "+ value);
            //
            break 
        case "box3State":
            if(value=="3"){
                box3Held=true;
            }else if (value=="1"){
                box3Held=false;
            }
            boxTest();
            simpleHttp(key, value, true); 
            //server.log(key +" = "+ value);
            //
            break 
        case "box4State":
            if(value=="3"){
                box4Held=true;
            }else if (value=="1"){
                box4Held=false;
            }
            boxTest();
            simpleHttp(key, value, true); 
            //server.log(key +" = "+ value);
            //
            break 
        case "box5State":
            if(value=="3"){
                box4Held=true;
            }else if (value=="1"){
                box5Held=false;
            }
            boxTest();
            simpleHttp(key, value, true); 
            //server.log(key +" = "+ value);
            //
            break    
        case "boxID":
            //
            break
        case "never happened":
            server.log("strange things are afoot at the circle k");
            break
            
        case "resetLights":
            simpleHttp(0,5,false);
             server.log("we switched off the house lights");
        } 
    }
//
response.send(200, webPage);

}


// register the HTTP handler
http.onrequest(testIncoming);
//


//BLACK MAZE


function threshHold(key, value){
  if(gameLive==true){
      if(sendDevice==activeDevice){// this checks to see if the latest device to send data is the active device 
      
      /*
      TODO
      check how much of this data needs to be filtered in this way?
      
      
      */
      
        if(key== "rawHeart"){
            //do something with the heart rate
        }else if(key=="heartrate"){
            beatCalc(value);
           // server.log("got this far");
        };
        
        //
        if(value==box1Val){
            simpleHttp(1,1,false);//set box value
            server.log("Box1: data1 = "+value);
             simpleHttp(1,2,true )// update teh admin
            
        }else if(value==box2Val){
            simpleHttp(2,1,false);
            server.log("Box2: data1 ="+value);
             simpleHttp(2,2,true );
            
        }else if(value==box3Val){
            simpleHttp(3,1,false);
            server.log("Box3: data1 = "+value);
             simpleHttp(3,2,true )//update teh admin
        }else if(value==box4Val){
            simpleHttp(4,1,false);
            server.log("Box4: data1 = "+value);
             simpleHttp(4,2,true )
            
        }else if(value==box5Val){
            simpleHttp(5,1,false);
            server.log("Box5: data1 = "+value);
             simpleHttp(5,2,true )
            
        }
        /*
        else if(key=="box1Held"){
            box1Held=value;
            boxTest();
            simpleHttp(1,3,true );
        }else if(key=="box2Held"){
            box2Held=value;
            boxTest();
            simpleHttp(2,3,true );
        }else if(key=="box3Held"){
            box3Held=value;
            boxTest();
             simpleHttp(3,3,true );
        }else if(key=="box4Held"){
            box4Held=value;
            boxTest();
             simpleHttp(4,3,true );
        }else if(key=="box5Held"){
            box5Held=value;
            boxTest();
             simpleHttp(5,3,true );
        }*/
      }
  }
}
//
function setVal(key, value,admin){
    if (!admin){
    if(key=="boxHoldDuration"){
        boxHoldDuration=value;
        //call back admin server
    }else if(key =="boxTriggerTime"){
        boxTriggerTime=value;
        //call back admin server
    }else if(key=="game"){
        gameSet(value);
        //call back admin server
    }else if(key=="heartBeatLimit"){
        heartBeatLimit = value.tointeger();
       // server.log("heartBeatLimit set to"+value);
        //call back admin server
    }else if(key=="setDevice"){
        local cd = value.tointeger();//current device no
        activeDevice=devId[cd];//
       // server.log("activeDevice id = "+activeDevice);
        
        //Call back admin server
        
    }else if (key=="uniqueID"){
        //server.log("key uniqueID");
        sendDevice=value;
        for(local i=1; i<= (devId.len() - 1);i++){
           // server.log("the loop reads "+i)
             if(value==devId[i]){
                 deviceTimes[i]=time();
             }
        }
        
        
       // server.log("send device = "+value);
       // server.log("activeDevice = "+activeDevice);
        /*for(local a=0;a<5;a+=1){
            if( devId[a]==value){
                if (liveDev[a]==false){
                    liveDev[a]= true;
                    server.log("Device "+a+" is live");
                    
                    //TODO: turn off the devices
                }
            }
        }*/
        
    }
    }else if(admin){
        
        simpleHttp(key,value, admin);
    }
}


function boxSet(){
    //server.log("boxSet call 1");
    //SET  THE BOX STATES FROM SCRATCH
    //TO USE THE simpleHttp() FUNCTION THIS MEANS MAKING 3 CALLS FOR EACH BOX
    //BOX 1
    simpleHttp(1,2,false);//MAKESURE THE BOX IS OFF
   // simpleHttp(1,3,false);//SET THE BOX TRIGGER TIME
    //simpleHttp(1,4,false);//SET THE BOX HOLD DURATION
    //BOX 2
    simpleHttp(2,2,false);
  //  simpleHttp(2,3,false);
//    simpleHttp(2,4,false);
    //BOX 3
    simpleHttp(3,2,false);
 //   simpleHttp(3,3,false);
   // simpleHttp(3,4,false);
    //BOX 4
    simpleHttp(4,2,false);
    //simpleHttp(4,3,false);
    //simpleHttp(4,4,false);
    //server.log("boxSet call 2");
    
}

function gameSet(val){
    //server.log("gameSet() called");
    if(val=="true"){
        if(gameLive!=true){
            gameLive=true;//ATTEMPTING TO DEBOUNCE THE GAME START UP CALL
            server.log("GAME ON!!")
           // boxSet();
            heartBeatCount=0;
            heartTimer();//SET THE TIMING FUNCTION RUNNING
            simpleHttp(0,5,false);// house lights off
            simpleHttp(1,5,false);
            simpleHttp(2,5,false);
            simpleHttp(3,5,false);
            simpleHttp(4,5,false);
            simpleHttp(5,5,false);
        }
        
    }else if(val=="false"){
        //
        server.log("GAME CANCELLED");
        gameLive=false;
        simpleHttp("game","false",true);//update the admin
        simpleHttp("winCondition","Cancelled",true);//update the admin
        //TODO
        //stop stuff :)
         simpleHttp(0,3,false);// CURRENTLY SET TO PUT THE LIGHTS ON
         simpleHttp(1,3,false);
        simpleHttp(2,3,false);
        simpleHttp(3,3,false);
        simpleHttp(4,3,false);
        simpleHttp(5,3,false);
        
    }
}
function boxTest(){
    //ARE ALL FOUR BOXES IN THE HELD STATE
    
    
    //if((box1Held==true)&&(box2Held==true)&&(box3Held==true)&&(box4Held==true)){
     if((box1Held==true)&&(box3Held==true)&&(box4Held==true)){
        gameOver("Win");
        //server.log("WE HAVE A WIN!!!");
        
        
    }
}
function gameOver(end){
    
    //GAME OVER
    //LIGHT THE LIGHTS
    simpleHttp("winCondition",end,true);//update the admin
    
    if(end=="Lose"){
        
        gameLive=false;
        simpleHttp("game","false",true);//update the admin
        server.log("GAME  OVER you "+end);
        simpleHttp(0,4,false);//house lights
        simpleHttp(1,4,false);
        simpleHttp(2,4,false);
        simpleHttp(3,4,false);
        simpleHttp(4,4,false);
        simpleHttp(5,4,false);
    }else if(end=="Win"){
        
        gameLive=false;
        simpleHttp("game","false",true);//update the admin
        server.log("GAME  OVER you "+end);
        simpleHttp(0,3,false);// house lights
        simpleHttp(1,3,false);
        simpleHttp(2,3,false);
        simpleHttp(3,3,false);
        simpleHttp(4,3,false);
        simpleHttp(5,3,false);
    }
    
}
function beatCalc(cur){
    //TEST TEH PARAM TO SEE WHAT THE CURRENT HEART STATE IS
    // SET HEART STATE
    //CALCULATE INTERVAL
    
    if(cur=="green"){
        heartState=greenHeart;
        
    }else if(cur=="yellow"){
         heartState=yellowHeart;
        
    }else if(cur=="orange"){
        heartState=orangeHeart;
        
    }else if(cur=="red"){
        heartState=redHeart;
        
    }
    
    interval=(heartState/60.0);
   
}

function heartTimer(){
   // server.log("heartTimer called");
    if(heartBeatTimer) imp.cancelwakeup(heartBeatTimer);
    
    //server.log("heartTimer called");
        if( gameLive==true){
            
            heartBeat();//and this should set the rythem
            //
            heartBeatTimer= imp.wakeup(interval,heartTimer);//This should do it
            //heartBeatTimer= imp.wakeup(1.0,heartTimer);
        }
    
    
}



function heartBeat(){
    //
    //local countdown=heartBeatLimit - heartBeatCount;
    
    server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    /*
    if ((heartBeatLimit - heartBeatCount)==300){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }else if ((heartBeatLimit - heartBeatCount)==250){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }else if ((heartBeatLimit - heartBeatCount)==200){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }else if ((heartBeatLimit - heartBeatCount)==150){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }else if ((heartBeatLimit - heartBeatCount)==100){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }else if ((heartBeatLimit - heartBeatCount)==60){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }else if ((heartBeatLimit - heartBeatCount)==30){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }else if ((heartBeatLimit - heartBeatCount)==20){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }else if ((heartBeatLimit - heartBeatCount)==10){
        server.log("Countdown = "+(heartBeatLimit - heartBeatCount));
    }*/
    if( heartBeatCount <= heartBeatLimit){
        heartBeatCount++;
        
    }else if(heartBeatCount >= heartBeatLimit){
        gameOver("Lose");
        
    }
    
}

//every x sexonds we will check teh device live list and see if there has been a recent update list and 

function liveDeviceList(){
    local now = time();
    for(local i=1;i<=(deviceTimes.len() - 1);i++){
        
        if((now - deviceTimes[i])>deviceTimeOut){
            if(liveDev[i]!=false){
                liveDev[i]=false;
                simpleHttp(deviceName[i],"false", true);
                server.log(deviceName[i]+" =false");
            }
        }else if((now - deviceTimes[i])<deviceTimeOut){
            if(liveDev[i]!=true){
                liveDev[i]=true;
                simpleHttp(deviceName[i],"true", true);
                server.log(deviceName[i]+" =true");
            }
            
        }
    }
    
    
    deviceCheckTimer= imp.wakeup(5,liveDeviceList);//This should do it
    
    
}
//
function serverReset(){
    // update teh admin that the server has reset
    simpleHttp("game","false",true);//update the admin
    simpleHttp("heartBeatLimit",heartBeatLimit,true);//update the admin
    //server.log("how long am ai? = "+devId.len());
    liveDeviceList();//set off teh device checking
     simpleHttp("box1State","1",true )//update teh admin
     simpleHttp("box2State","1",true )//update teh admin
     simpleHttp("box3State","1",true )//update teh admin
     simpleHttp("box4State","1",true )//update teh admin
     simpleHttp("box5State","1",true )//update teh admin
     simpleHttp("winCondition","No-Game",true);//update the admin
     simpleHttp(0,5,false);//house lights off
     /*simpleHttp(1,5,false);//house lights off
     simpleHttp(2,5,false);//house lights off
     simpleHttp(3,5,false);//house lights off
     simpleHttp(4,5,false);//house lights off*/
     
}
serverReset();
//
//device.on("deviceSelected", setActive);
// THE HTML BIT
//the first line sends get requests to the boxes
//the second line just sets the ative user
//webPage <- "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'><html><head><title>terminal 002</title><style>body {background-color: #000000}h1{color:#76EE00};p{color:#76EE00};</style></head><h1>Enter Code</h1><p><form name='input' STYLE='color:#76EE00' action='https://agent.electricimp.com/I1n1OyjmGxj8' method='get'>code: <input STYLE='background-color:#000000; color:#76EE00;' type='text' name='user'><input STYLE='background-color:#000000; color:#76EE00' type='submit' value='Submit'></form></p><p style = color:#76EE00 >quick hack<br/> add a ?active=1 to set the acive user to 1, add a  ?breath=Blowing above to trigger blowing event etc</p></body></html>";
//heartTimer();
webPage <- "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'><html><head><body><title>Hyde Bio demo</title><style>body {background-color: #000000}h1{color:#76EE00};p{color:#76EE00};</style></head><h1>Set data to send  </h1><p><form name='input' STYLE='color:#76EE00' action='https://agent.electricimp.com/UfjeyOiM8dzT' method='get'>heartBeatLimit: <input STYLE='background-color:#000000; color:#76EE00;' type='text' name='heartBeatLimit'><input STYLE='background-color:#000000;color:#76EE00' type='submit' value='Submit'></form></p><p><form name='input' STYLE='color:#76EE00' action='https://agent.electricimp.com/UfjeyOiM8dzT' method='get'>setDevice: <input STYLE='background-color:#000000; color:#76EE00;' type='text' name=‘setDevice’><input STYLE='background-color:#000000;color:#76EE00' type='submit' value='Submit'></form></p><p><form name='input' STYLE='color:#76EE00' action='https://agent.electricimp.com/UfjeyOiM8dzT' method='get'>breath: <input STYLE='background-color:#000000; color:#76EE00;' type='text' name=‘breath’><input STYLE='background-color:#000000;color:#76EE00' type='submit' value='Submit'></form></p><p><form name='input' STYLE='color:#76EE00' action='https://agent.electricimp.com/UfjeyOiM8dzT' method='get'>game: <input STYLE='background-color:#000000; color:#76EE00;' type='text' name=‘game’><input STYLE='background-color:#000000;color:#76EE00' type='submit' value='Submit'></form></p></body></html>";
