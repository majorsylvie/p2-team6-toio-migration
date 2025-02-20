import oscP5.*;
import netP5.*;
import deadpixel.keystone.*;

Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;
PImage mapImg;

//constants
//The soft limit on how many toios a laptop can handle is in the 10-12 ranges
//the more toios you connect to, the more difficult it becomes to sustain the connection
int nCubes = 2;
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
  puffin.imagePath = "Puffins.png";
  puffin.printPoints();
  
  currBird = puffin;

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
  alca.imagePath = "Puffins.png";
  alca.printPoints();

  currBird = alca;
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
  uria.imagePath = "Puffins.png";
  uria.printPoints();
  
  currBird = uria;
}

void setup() {
  selectUria();

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
  offscreen.fill(0, 255, 0);
  offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
  mapImg.resize(375, 280);
  offscreen.image(mapImg, 20, 40);

  drawTimeline();


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
}
void drawTimeline() {
  int timelineMaxWidth = 340;
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
    leftBound = tickXs.get(timelinePrevTick);
    rightBound = tickXs.get(timelineNextTick);
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
  print("\n\n percentToNext = " + percentToNext + "\n\n");
  //System.out.println(percentToNext);
  //System.out.println("D");
  int leftX = int(currBird.points.get(timelinePrevTick).x);
  //System.out.println("E");
  int rightX = int(currBird.points.get(timelineNextTick).x);
  //System.out.println("F");
  int leftY = int(currBird.points.get(timelinePrevTick).y);
  //System.out.println("E");
  int rightY = int(currBird.points.get(timelineNextTick).y);
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
  mapTOIO.target(mapTOIOTargetX, mapTOIOTargetY, angleDegrees);
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
  mapTOIO = cubes[1]; //This will be dynamically changed via selection
  pauseplayTOIO = cubes[2];
  //(also 1 is meant for bird selection this is just a stand in for testing)
  System.out.println("done assigning cubes");
  System.out.println(cubes);
}
