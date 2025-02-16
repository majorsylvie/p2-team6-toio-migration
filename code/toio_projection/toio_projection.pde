import oscP5.*;
import netP5.*;
import deadpixel.keystone.*;

Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;
PImage mapImg;

//constants
//The soft limit on how many toios a laptop can handle is in the 10-12 range
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
boolean WindowsMode = true; //When you enable this, it will check for connection with toio via Rust first, before starting void loop()

int framerate = 30;

int[] matDimension = {10, 10, 455, 455};


//for OSC
OscP5 oscP5;
//where to send the commands to
NetAddress[] server;

//we'll keep the cubes here
Cube[] cubes;
// variable for the one toio cube that will move along the timeline.
Cube timelineTOIO;

// current dataset
BirdData currBird;
//void settings() {
//  size(1000, 1000);
//}


void setup() {
  BirdData kazCrane = new BirdData();

  // dummy triangle data
  kazCrane.addPoint(200, 150, "Starting Date");
  kazCrane.addPoint(150, 250, "Middle Date");
  kazCrane.addPoint(250, 250);
  kazCrane.imagePath = "Kazakhstan.png";
  kazCrane.printPoints();

  // TODO dataset selection
  currBird = kazCrane;
  
  // Keystone will only work with P3D or OPENGL renderers,
  // since it relies on texture mapping to deform
  size(1000, 1000, P3D);
  mapImg = loadImage(kazCrane.imagePath);
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
  translate(xOffset, yOffset);

  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);

    if (cubes[i].isActive) {
      pushMatrix();
      translate(cubes[i].x, cubes[i].y);
      if (i > 0) { //This lets us deal with two mats (determines how many tois are on mat 2)
        translate(450, 0);
      }
      fill(0);
      textSize(15);
      text(i, 0, -20);
      noFill();
      rotate(cubes[i].theta * PI/180);
      rect(-10, -10, 20, 20);
      line(0, 0, 20, 0);
      popMatrix();
    }
  }
  popMatrix();
  //END TEMPLATE/DEBUG VIE

  //INSERT YOUR CODE HERE!
}

void drawTimeline() {
  System.out.println("drawing timeline,,,");
  int timelineMaxWidth = 380;
  int timelineOffset = 20;
  int timelineStartX = timelineOffset;
  int timelineEndX = timelineStartX + timelineMaxWidth;
  int timelineY = 400;
  int tickHeight = 30; // Height of the tick marks
  int numTicks = currBird.getNumPoints() + 1; // Number of tick marks

  // central line
  stroke(0); // Set line color to white
  strokeWeight(4);
  offscreen.line(timelineStartX, timelineY, timelineEndX, timelineY);

  // tick mark spacing
  float spacing = timelineMaxWidth / (numTicks - 1);

  for (int i = 0; i < numTicks; i++) {
    float tickX = timelineStartX + i * spacing;
    offscreen.line(tickX, timelineY - tickHeight / 2, tickX, timelineY + tickHeight / 2);
  }
  // reset stroke weight from 4
  strokeWeight(2);
}

void drawTick(int x, int y, String label) {
  // Draw the tick mark
  strokeWeight(2);
  line(x, y - 10, x, y + 10);

  // Draw the label
  fill(200, 50, 50); // Soft red color
  textSize(14);      // Set text size
  textAlign(CENTER, BOTTOM); // Center the text horizontally and align it to the bottom

  // Add a subtle white outline for readability
  fill(255); // White color for the outline
  text(label, x + 1, y - 15); // Slightly offset to create an outline effect
  text(label, x - 1, y - 15);
  text(label, x, y - 16);
  text(label, x, y - 14);

  // Draw the main text
  fill(200, 50, 50); // Soft red color
  text(label, x, y - 15);
}

void assignCubes() {
  System.out.println("assigning cubes");
  //create cubes
  cubes = new Cube[nCubes];
  for (int i = 0; i< nCubes; ++i) {
    cubes[i] = new Cube(i);
  }

  // assign toiobot purposes
  timelineTOIO = cubes[0];
}
