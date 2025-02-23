import oscP5.*;
import netP5.*;
import deadpixel.keystone.*;


// info bot setup
// any fine tuning
  //LED's
    //turning on/off light when the autoplay function ends
  //title centering
// info bot setup (UPDATE REFRENFENCES IN INFO SECTION)
// any fine tuning (LED's, title things)
// attach the things to the toios
// record the video
// submit the deliverables


Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;
PImage mapImg;
PImage infoImg;

//constants
//The soft limit on how many toios a laptop can handle is in the 10-12 ranges
//the more toios you connect to, the more difficult it becomes to sustain the connection
int nCubes = 6;
int cubesPerHost = 12;
int maxMotorSpeed = 115;
int xOffset;
int yOffset;

//// Instruction for Windows Users  (Feb 2. 2025) ////
// 1. Enable WindowsMode and set nCubes to the exact number of toio you are connecting.
// 2. Run Processing Code FIRST, Then Run the Rust Code. After running the Rust Code, you should place the toio on the toio mat, then Processing should start showing the toio position.
// 3. When you re-run the processing code, make sure to stop the rust code and toios to be disconnected (switch to Bluetooth stand-by mode [blue LED blinking]). If toios are taking time to disconnect, you can optionally turn off the toio and turn back on using the power button.
// Optional: If the toio behavior is werid consider dropping the framerate (e.g. change from 30 to 10)
//
boolean WindowsMode = false; //When you enable this, it will check for connection with toio via Rust first, before starting void loop()

boolean isPlaying = false;

int framerate = 30;

int[] matDimension = {10, 10, 455, 455};

int timelinePrevTick = 0;
int timelineNextTick = 1;
int currentX;
float leftBound;
float rightBound;
float percentToNext;

public int mapTOIOTargetX = 45;
public int mapTOIOTargetY = 45;

int pageNum = 0;
StringList puffinPages = new StringList();
StringList alcaPages = new StringList();
StringList uriaPages = new StringList();

String mapTitle = "Bird Movement Data";

//for OSC
OscP5 oscP5;
//where to send the commands to
NetAddress[] server;

//we'll keep the cubes here
Cube[] cubes;
// variable for the one toio cube that will move along the timeline.
Cube timelineTOIO;
// the one toio that is moving based on the timelineTOIO
Cube mapTOIO;
// toio that will be pressed to pause and play
Cube pauseplayTOIO;
// whether or not the timline is automatically moving. starts still
boolean paused = true;

Cube puffinTOIO;
Cube alcaTOIO;
Cube uriaTOIO;
Cube infoTOIO;

// currently selected bird
BirdData currBird;
//void settings() {
//  size(1000, 1000);
//}

void addHome(BirdData b) {
   b.addPoint(108, 220, "Home");
}

void selectPuffin() {
  BirdData puffin = new BirdData();
  addHome(puffin);
  puffin.addPoint(197, 83,  "");
  puffin.addPoint(173, 235, "");
  addHome(puffin);


  puffin.lapEndDateLabel = "End";
  puffin.imagePath = "data/PuffinMap.png";
  puffin.printPoints();

  currBird = puffin;
  mapTOIO = puffinTOIO;
  mapTitle = "Puffin Movement Data";

}
void selectAlca() {
  BirdData alca = new BirdData();
  //    b.addPoint(108, 220, "Home");
  addHome(alca);
  alca.addPoint(214, 174, "");
  alca.addPoint(370, 164, "");
  alca.addPoint(364, 211, "");
  addHome(alca);

  alca.lapEndDateLabel = "End";
  alca.imagePath = "data/PuffinMap.png";
  alca.printPoints();

  currBird = alca;
  mapTOIO = alcaTOIO;
  mapTitle = "Razorbill Movement Data";

}

void selectUria() {
  BirdData uria = new BirdData();
  addHome(uria);
  uria.addPoint(101, 315, "");
  uria.addPoint(125, 328, "");
  addHome(uria);
  uria.addPoint(132, 323, "");
  uria.addPoint(157, 291, "");
  addHome(uria);

  uria.lapEndDateLabel = "End";
  uria.imagePath = "data/PuffinMap.png";
  uria.printPoints();

  currBird = uria;
  mapTOIO = uriaTOIO;
  mapTitle = "Common Murre Movement Data";

}

void setup() {
  prepInfo();
  selectAlca();

  // Keystone will only work with P3D or OPENGL renderers,
  // since it relies on texture mapping to deform
  size(1000, 1000, P3D);
  fullScreen(P3D);
  mapImg = loadImage(currBird.imagePath);
  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(950, 450, 20); //Double Mat length

  // We need an offscreen buffer to draw the surface we
  // want projected
  // note that we're matching the resolution of the
  // CornerPinSurface.
  // (The offscreen buffer can be P2D or P3D)
  offscreen = createGraphics(950, 450, P3D);
  //launch OSC sercer
  oscP5 = new OscP5(this, 3333);
  server = new NetAddress[1];
  server[0] = new NetAddress("127.0.0.1", 3334);

  assignCubes();

  xOffset = matDimension[0] - 45;
  yOffset = matDimension[1] - 45;
  


  //do not send TOO MANY PACKETS
  //we'll be updating the cubes every frame, so don't try to go too high
  frameRate(framerate);
  //if(WindowsMode){
  //  check_connection();
  //}
}

void draw() {
  // Convert the mouse coordinate into surface coordinates
  // this will allow you to use mouse events inside the
  // surface from your screen.
  PVector surfaceMouse = surface.getTransformedMouse();
  // most likely, you'll want a black background to minimize
  // bleeding around your projection area
  background(0);

  // Draw the scene, offscreen
  offscreen.beginDraw();
  offscreen.background(255);
  offscreen.fill(0, 0, 0);
  //offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
  mapImg.resize(375, 280);
  offscreen.image(mapImg, 20, 40);
  offscreen.textAlign(TOP, CENTER);
  //offscreen.text(mapTitle, 20, 20, 375, 10);
  offscreen.text(mapTitle, 122, 20); //This may need to be adjusted/centered based on length

  drawTimeline();
  drawInfo();
  drawIcons();
  drawPlayPauseButton();

  offscreen.endDraw();

  // render the scene, transformed using the corner pin surface
  surface.render(offscreen);
  ////START TEMPLATE/DEBUG VIEW
  //background(255);
  //stroke(0);
  long now = System.currentTimeMillis();

  //draw the "mat"
  //fill(255);
  //rect(matDimension[0] - xOffset, matDimension[1] - yOffset, matDimension[2] - matDimension[0], matDimension[3] - matDimension[1]);


  //draw the cubes
  pushMatrix();
  offscreen.translate(xOffset, yOffset);

  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);

    if (cubes[i].isActive) {
      pushMatrix();
      offscreen.translate(cubes[i].x, cubes[i].y);
      if (i > 1) { //This lets us deal with two mats (determines how many tois are on mat 2)
        offscreen.translate(450, 0);
      }
      offscreen.fill(0);
      offscreen.textSize(15);
      offscreen.text(i, 0, -20);
      offscreen.noFill();
      offscreen.rotate(cubes[i].theta * PI/180);
      offscreen.rect(-10, -10, 20, 20);
      offscreen.line(0, 0, 20, 0);
      popMatrix();
    }
  }
  popMatrix();
  //END TEMPLATE/DEBUG VIE

  //INSERT YOUR CODE HERE!
  if (!paused) {
     autoplayTimeline();
  }
  print("paused: " + paused);
  if (mapTOIO != null) {
    mapTOIO.led(100, 163, 251, 255);
  }
}
void drawTimeline() {
  int timelineMaxWidth = 320;
  int timelineOffset = 45;
  int timelineStartX = timelineOffset;
  int timelineEndX = timelineStartX + timelineMaxWidth;
  int timelineY = 365;
  int tickHeight = 30; // Height of the tick marks
  int numTicks = currBird.getNumPoints(); // Number of tick marks

  // Draw the central timeline line
  offscreen.stroke(0); // Set line color to black
  offscreen.strokeWeight(4);
  offscreen.line(timelineStartX, timelineY, timelineEndX, timelineY);

  // Calculate tick mark spacing
  float spacing = timelineMaxWidth / (numTicks - 1);
  ArrayList<Float> tickXs = new ArrayList<Float>();
  // Draw tick marks and labels
  for (int i = 0; i < numTicks; i++) {
    float tickX = timelineStartX + i * spacing;
    tickXs.add(tickX);
    // Draw the tick mark
    offscreen.stroke(0); // Set line color to black
    offscreen.strokeWeight(2);
    offscreen.line(tickX, timelineY - tickHeight / 2, tickX, timelineY + tickHeight / 2);

    // Draw the label (if it exists)
    if (i < currBird.getNumPoints()) {
      Point point = currBird.points.get(i);
      if (!point.label.isEmpty()) { // Only draw if the label is not empty
        drawLabel(tickX, timelineY - tickHeight / 2, point.label);
      }
    } else {
      // drawing the FINAL tick mark,
      // that represents the bird returning to to the first point.
      if (!currBird.lapEndDateLabel.isEmpty()) {
        drawLabel(tickX, timelineY - tickHeight / 2, currBird.lapEndDateLabel);
      }
    }
  }

  ///TOIO MAP TARGETTING

  //Here onward is for toio targeting on map
  //Determine which tick we're moving towards
  if (timelineTOIO.x > timelineStartX && timelineTOIO.x < timelineEndX) {
    //System.out.println("A");
    if (timelineNextTick >= 0 && timelineNextTick < tickXs.size()) {
      leftBound = tickXs.get(timelinePrevTick);
      rightBound = tickXs.get(timelineNextTick);
    } else {
      leftBound = tickXs.get(tickXs.size()-2);
      rightBound = tickXs.get(tickXs.size()-1);
    }
    //System.out.println("Done A");
    if (timelineTOIO.x > rightBound) {
      //System.out.println("B");
      timelinePrevTick = timelineNextTick;
      timelineNextTick = timelineNextTick + 1;
      //System.out.println("Done B");
    } else if (timelineTOIO.x < leftBound) {
      //System.out.println("C");
      timelineNextTick = timelinePrevTick;
      timelinePrevTick = timelinePrevTick - 1;
      //System.out.println("Done C");
    }
  } else if (timelineTOIO.x <= timelineStartX) {
    timelinePrevTick = 0;
    timelineNextTick = 1;
    timelineTOIO.target(int(tickXs.get(0)), timelineY, 90);
  } else if (timelineTOIO.x >= timelineEndX) {
    timelinePrevTick = numTicks-2;
    timelineNextTick = numTicks-1;
    timelineTOIO.target(int(tickXs.get(numTicks-1)), timelineY, 90);
  }
  currentX = timelineTOIO.x;
  percentToNext = ((currentX - leftBound) / (rightBound - leftBound));
  //print("\n\n percentToNext = " + percentToNext + "\n\n");
  //System.out.println(percentToNext);
  //System.out.println("D");
  //System.out.println("E");

  int lastPointIndex = currBird.points.size() - 1;
  int leftX = int(currBird.points.get(lastPointIndex).x);
  int leftY = int(currBird.points.get(lastPointIndex).y);

  // error bounds calculation, since there were times where timelineNextTick is out of bounds.
  int rightX = int(currBird.points.get(lastPointIndex).x);
  int rightY = int(currBird.points.get(lastPointIndex).y);
  if (timelineNextTick >= 0 && timelineNextTick < currBird.points.size()) {
    leftY = int(currBird.points.get(timelinePrevTick).y);
    leftX = int(currBird.points.get(timelinePrevTick).x);
    rightX = int(currBird.points.get(timelineNextTick).x);
    rightY = int(currBird.points.get(timelineNextTick).y);
  }
  //System.out.println("F");
  //System.out.println("E");
  //System.out.println("F");
  //System.out.println(percentToNext);
  //System.out.println(int((leftX + ((leftX - rightX)) * percentToNext)));
  mapTOIOTargetX = int(leftX + ((rightX - leftX)) * percentToNext);
  mapTOIOTargetY = int(leftY + ((rightY - leftY)) * percentToNext);
  //print("\nLEFT = " + leftX +  "," + leftY + "\nRIGHT = " + rightX + "," + rightY + "\n");
  //print("\nXXXXXXXX       " + mapTOIOTargetX + " " + mapTOIOTargetY + "            XXXXXXXXXXXXXXXX\n");

  int deltaX = rightX - leftX;
  int deltaY = rightY - leftY;
  // calculate the angle between the two points
  double angleRadians = Math.atan2(deltaY, deltaX);
  int angleDegrees = (int) Math.floor(Math.toDegrees(angleRadians));

  if (mapTOIO != null) {
      mapTOIO.target(mapTOIOTargetX, mapTOIOTargetY, angleDegrees);
  }
}

void drawLabel(float x, float y, String label) {
  // Set text properties
  offscreen.fill(200, 50, 50); // Soft red color
  offscreen.textSize(14);      // Set text size
  offscreen.textAlign(CENTER, BOTTOM); // Center the text horizontally and align it to the bottom

  // Add a subtle white outline for readability
  offscreen.fill(255); // White color for the outline
  offscreen.text(label, x + 1, y - 5); // Slightly offset to create an outline effect
  offscreen.text(label, x - 1, y - 5);
  offscreen.text(label, x, y - 6);
  offscreen.text(label, x, y - 4);

  // Draw the main text
  offscreen.fill(200, 50, 50); // Soft red color
  offscreen.text(label, x, y - 5);
}

void drawInfo() {
  int infoMaxWidth = 300;
  int infoMaxHeight = 300;
  int infoOffset = 750;
  int infoStartX = infoOffset;
  int infoEndX = infoStartX + infoMaxWidth;
  int infoY = 50;
  String title = "Info Section";
  StringList pages = new StringList();
  pages.append("Info.png");
  pages.append(" ");
  pages.append(" ");
  pages.append(" ");
  if (mapTOIO == puffinTOIO) {
    title = "Atlantic puffin";
    pages = puffinPages;
  }
  else if (mapTOIO == alcaTOIO) {
    title = "Razorbill";
    pages = alcaPages;
  }
  else if (mapTOIO == uriaTOIO) {
    title = "Common Murre";
    pages = uriaPages;
  }
  offscreen.fill(163, 251, 255);
  offscreen.rect(infoStartX-(infoMaxWidth/2) - 5,infoY - 20,infoMaxWidth + 10, 20);
  offscreen.rect(infoStartX-(infoMaxWidth/2) - 5,infoY + 20,infoMaxWidth + 10, infoMaxHeight+10);
  offscreen.fill(0, 0, 0);
  offscreen.text(title, infoStartX, infoY);
  if (pageNum == 0) {
    infoImg = loadImage(pages.get(pageNum));
    infoImg.resize(infoMaxWidth,infoMaxHeight);
    offscreen.image(infoImg, infoStartX-(infoMaxWidth/2),infoY + 25);
  }
  else {
    offscreen.textAlign(CENTER, TOP);
    // added mod 4 to avoid index errors
    offscreen.text(pages.get(pageNum % 4), infoStartX-(infoMaxWidth/2), infoY + 25, infoMaxWidth - 10, infoMaxHeight + 5);
  }

  pageNum = int(infoTOIO.theta / 90);
  System.out.println(pageNum);

  //  timelineTOIO.target(timelineTOIO.x, timelineTOIO.y, currentRotationDirectionAngle);

}

void prepInfo() {
  puffinPages.append("PuffinImage.jpg");
  puffinPages.append("The Atlantic puffin (Fratercula arctica), also known as the common puffin, is a species of seabird in the auk family. The Atlantic puffin breeds in Russia, Iceland, Ireland, Britain, Norway, Greenland, Newfoundland and Labrador, Nova Scotia, and the Faroe Islands, and as far south as Maine in the west and France in the east. It is most commonly found in the Westman Islands, Iceland. Although it has a large population and a wide range, the species has declined rapidly, at least in parts of its range, resulting in it being rated as vulnerable by the IUCN.");
  puffinPages.append("On land, it has the typical upright stance of an auk. At sea, it swims on the surface and feeds on zooplankton, small fish, and crabs, which it catches by diving underwater, using its wings for propulsion. Spending the autumn and winter in the open ocean of the cold northern seas, the Atlantic puffin returns to coastal areas at the start of the breeding season in late spring. It nests in clifftop colonies, digging a burrow in which a single white egg is laid. Chicks mostly feed on whole fish and grow rapidly.");
  puffinPages.append(" After about 6 weeks, they are fully fledged and make their way at night to the sea. They swim away from the shore and do not return to land for several years. Colonies are mostly on islands with no terrestrial predators, but adult birds and newly fledged chicks are at risk of attacks from the air by gulls and skuas. The puffin's striking appearance, large, colourful bill, waddling gait, and behaviour have given rise to nicknames such as 'clown of the sea' or 'sea parrot'. It is the official bird of the Canadian province of Newfoundland and Labrador.");

  alcaPages.append("AlcaImage.jpg");
  alcaPages.append("The razorbill (Alca torda) is a North Atlantic colonial seabird and the only extant member of the genus Alca of the family Alcidae, the auks. It is the closest living relative of the extinct great auk (Pinguinus impennis). Historically, it has also been known as 'auk', 'razor-billed auk' and 'lesser auk'. Razorbills are primarily black with a white underside. The male and female are identical in plumage; however, males are generally larger than females.");
  alcaPages.append("This agile bird, which is capable of both flight and diving, has a predominantly aquatic lifestyle and only comes to land in order to breed. It is monogamous, choosing one partner for life. Females lay one egg per year. Razorbills nest along coastal cliffs in enclosed or slightly exposed crevices. The parents spend equal amounts of time incubating, and once the chick has hatched, they take turns foraging for their young.");
  alcaPages.append("Presently, this species faces major threats, including the destruction of breeding sites, oil spills, and deterioration of food quality. The IUCN records the population of the species as fluctuating, causing its status to interchange. It has been recorded that the population had increased from 2008 to 2015, decreased from 2015 to 2021, and appears to be increasing or stable at the present. It is estimated that the current global razorbill population lies between 838,000 and 1,600,000 individuals. In 1918, the razorbill was protected in the United States by the Migratory Bird Treaty Act.");


  uriaPages.append("UriaImage.jpg");
  uriaPages.append("The common murre or common guillemot (Uria aalge) is a large auk. It has a circumpolar distribution, occurring in low-Arctic and boreal waters in the North Atlantic and North Pacific. It spends most of its time at sea, only coming to land to breed on rocky cliff shores or islands. Common murres are fast in direct flight but are not very agile. They are highly mobile underwater using their wings to 'fly' through the water column, where they typically dive to depths of 30–60 m (100–195 ft). Depths of up to 180 m (590 ft) have been recorded.");
  uriaPages.append("Common murres breed in colonies at high densities. Nesting pairs may be in bodily contact with their neighbours. They make no nest; their single egg is incubated between the adult's feet on a bare rock ledge on a cliff face. Eggs hatch after ~30 days incubation. The chick is born downy and can regulate its body temperature after 10 days. Some 20 days after hatching, the chick leaves its nesting ledge and heads for the sea, unable to fly, but gliding for some distance with fluttering wings, accompanied by its male parent. Male guillemots spend more time diving, and dive more deeply than females during this time.");
  uriaPages.append("Chicks are capable of diving as soon as they hit the water. The female stays at the nest site for some 14 days after the chick has left. Both male and female common murres moult after breeding and become flightless for 1–2 months. Some populations have short migration distances, instead remaining close to the breeding site year-round. Such populations return to the nest site from autumn onwards. Adult birds balance their energetic budgets during the winter by reducing the time that they spend flying and are able to forage nocturnally.");

}

void drawIcons() {
  PImage PuffinIcon = loadImage("PuffinIcon.png");
  PImage AlcaIcon = loadImage("AlcaIcon.png");
  PImage UriaIcon = loadImage("UriaIcon.png");

  int iconMaxWidth = 60;
  int iconMaxHeight = 60;
  int iconOffset = 445;
  int iconStartX = iconOffset;
  int iconEndX = iconStartX + iconMaxWidth;
  int iconY = 60;
  int iconSpacing = 20;
  String title = "Select\nAnimal:";

  offscreen.fill(125,249,255);
  offscreen.rect(iconStartX-(40),iconY - 20,iconMaxWidth + 15, 250);
  offscreen.fill(0, 0, 0);

  offscreen.textAlign(TOP, BASELINE);
  offscreen.text(title, iconStartX-32.5, iconY);


  int birdX = iconStartX-(iconMaxWidth/2);
  int puffY = iconY + 20;
  int alcaY = iconY + (70 + iconSpacing);
  int uriaY = iconY + (145 + iconSpacing);


  PuffinIcon.resize(iconMaxWidth,iconMaxHeight);
  offscreen.image(PuffinIcon, birdX,puffY);

  AlcaIcon.resize(iconMaxWidth,iconMaxHeight);
  offscreen.image(AlcaIcon, birdX,alcaY);

  UriaIcon.resize(iconMaxWidth,iconMaxHeight);
  offscreen.image(UriaIcon, birdX,uriaY);

  // offset because toio's were a little up :D
  int cont = 60;
  puffinTOIO.homeX = birdX;
  puffinTOIO.homeY = puffY + cont;

  uriaTOIO.homeX = birdX;
  uriaTOIO.homeY = uriaY + cont -10;

  alcaTOIO.homeX = birdX;
  alcaTOIO.homeY = alcaY + cont - 5;


  // DETECT WHICH TOIO IS SELECTED
  if (!isToioNearHome(puffinTOIO)) {
    //print("PUFFIN SELECTED");
    selectPuffin();
  } else if (!isToioNearHome(alcaTOIO)) {
    //print("ALCA SELECTED");
    selectAlca();
  } else if (!isToioNearHome(uriaTOIO)) {
    // print("URIA SELECTED");
    selectUria();
  }

  if (isToioNearHome(puffinTOIO) && mapTOIO == puffinTOIO) {
    mapTOIO = null;
  } else if (isToioNearHome(alcaTOIO) && mapTOIO == alcaTOIO) {
    mapTOIO = null;
  } else if (isToioNearHome(uriaTOIO) && mapTOIO == uriaTOIO) {
    mapTOIO = null;
  }
}

boolean isToioNearHome(Cube c) {
  int tolerance = 30;

  int p1 = c.x;
  int q1 = c.y;
  int p2 = c.homeX;
  int q2 = c.homeY;
  int distance = (int) Math.ceil(Math.sqrt((q2 - q1) * (q2 - q1) + (p2 - p1) * (p2 - p1)));
  //print(c.id + " is " + distance + " ; ");
  return distance <= tolerance;
}

void runHome(Cube c) {
  c.target(c.homeX,c.homeY,270);
}
void togglePause() {
  // function to either play or pause the automatic timeline toio movement.
  if (paused) {
    // if previously paused, play
    paused = false;

    //autoplayTimeline();

  } else {
    // if previously playing, pause
    paused = true;

    print("stop boy stop!!");


  }

}

void autoplayTimeline() {
   // function to automatically move the timelineTOIO back and forth.
   //motorTarget(timelineTOIO, mode, 5, 0, 80, 0, x, y, theta);
   print(paused);
   print(paused);
   
  
   int m = millis();
   int mm = m % 8000;
   if (m % 8000 < 500) {
       print("GOING TO START");
       timelineTOIO.target(95,385,0);
   } else if (mm > 4500 && mm < 5000) {
       print("GOING TO END");
       timelineTOIO.target(380,385,0);

   }

//   timelineTOIO.target(95,385,0);
  //    timelineTOIO.target(380,385,0);

   //timelineTOIO.motor(100,100,200);
   //timelineTOIO.target(0,2,50,0,95,365,0);
   //elay(4200);

   //timelineTOIO.target(0,2,50,0,400,365,0);

   //void target(int control, int timeout, int mode, int maxspeed, int speedchange,  int x, int y, int theta) {

}



void assignCubes() {
  System.out.println("assigning cubes");
  //create cubes
  cubes = new Cube[nCubes];
  for (int i = 0; i< nCubes; ++i) {
    cubes[i] = new Cube(i);
     System.out.println(cubes);
  }

  // assign toiobot purposes
  timelineTOIO = cubes[0];
  //mapTOIO = cubes[1]; //This will be dynamically changed via selection
  pauseplayTOIO = cubes[4];
  pauseplayTOIO.isPausePlay = true;

  puffinTOIO = cubes[1];
  alcaTOIO = cubes[2];
  uriaTOIO = cubes[3];
  infoTOIO = cubes[5];
  //(also 1 is meant for bird selection this is just a stand in for testing)
  System.out.println("done assigning cubes");
  System.out.println(cubes);
}

void drawPlayPauseButton() {
  int buttonMaxWidth = 85;
  int buttonHeight = 40;
  int buttonX = 470;
  int buttonY = 50 + 180 + 85;

  // ADD PLAYPAUSE TOGGLE
  offscreen.fill(163, 251, 255);

  offscreen.rect(buttonX, buttonY, buttonMaxWidth, buttonHeight);

  offscreen.fill(0);
  offscreen.textSize(20);
  offscreen.textAlign(CENTER, CENTER);

  if (!paused) {
    offscreen.fill(0,0,0);
    offscreen.text("Pause", buttonX + buttonMaxWidth / 2, buttonY + buttonHeight / 2);
    pauseplayTOIO.led(50,0,255,0);
  } else {
    offscreen.fill(0,0,0);
    offscreen.text("Play", buttonX + buttonMaxWidth / 2, buttonY + buttonHeight / 2);
  }
}
