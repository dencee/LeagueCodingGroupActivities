/*
MODIFIED FROM:
--------------
Particles text effects
 
 Uses particles with a seek behavior to make up a word.
 The word is loaded into memory so that each particle can figure out their own position they need to seek.
 Inspired by Daniel Shiffman's arrival explantion from The Nature of Code. (natureofcode.com)
 
 Controls:
 - Left-click for a new word.
 - Drag & right-click over particles to interact with them.
 - Press any key to toggle draw styles.
 
 Author:
 Jason Labbe
 
 Site:
 jasonlabbe3d.com
*/


// Global variables
boolean drawAsPoints = false;


class Particle {
  PVector pos = new PVector(0, 0);
  PVector vel = new PVector(0, 0);
  PVector acc = new PVector(0, 0);
  PVector target = new PVector(0, 0);

  float closeEnoughTarget = 50;
  float maxSpeed = 4.0;
  float maxForce = 0.1;
  float particleSize = 5;
  boolean isKilled = false;

  color startColor = color(0);
  color targetColor = color(0);
  float colorWeight = 0;
  float colorBlendRate = 0.025;

  void move() {
    // Check if particle is close enough to its target to slow down
    float proximityMult = 1.0;
    float distance = dist(this.pos.x, this.pos.y, this.target.x, this.target.y);
    if (distance < this.closeEnoughTarget) {
      proximityMult = distance/this.closeEnoughTarget;
    }

    // Add force towards target
    PVector towardsTarget = new PVector(this.target.x, this.target.y);
    towardsTarget.sub(this.pos);
    towardsTarget.normalize();
    towardsTarget.mult(this.maxSpeed*proximityMult);

    PVector steer = new PVector(towardsTarget.x, towardsTarget.y);
    steer.sub(this.vel);
    steer.normalize();
    steer.mult(this.maxForce);
    this.acc.add(steer);

    // Move particle
    this.vel.add(this.acc);
    this.pos.add(this.vel);
    this.acc.mult(0);
  }

  void draw() {
    // Draw particle
    color currentColor = lerpColor(this.startColor, this.targetColor, this.colorWeight);
    if (drawAsPoints) {
      stroke(currentColor);
      point(this.pos.x, this.pos.y);
    } else {
      noStroke();
      fill(currentColor);
      ellipse(this.pos.x, this.pos.y, this.particleSize, this.particleSize);
    }

    // Blend towards its target color
    if (this.colorWeight < 1.0) {
      this.colorWeight = min(this.colorWeight+this.colorBlendRate, 1.0);
    }
  }

  void kill() {
    if (! this.isKilled) {
      // Set its target outside the scene
      PVector randomPos = generateRandomPos(width/2, height/2, (width+height)/2);
      this.target.x = randomPos.x;
      this.target.y = randomPos.y;

      // Begin blending its color to black
      this.startColor = lerpColor(this.startColor, this.targetColor, this.colorWeight);
      this.targetColor = color(0);
      this.colorWeight = 0;

      this.isKilled = true;
    }
  }
}

public class Pixelate {
  String word;
  ArrayList<Particle> particles = new ArrayList<Particle>();
  int pixelSteps = 9; // Amount of pixels to skip
  PFont font;
  
  public ArrayList<Particle> getParticles(){
    return particles;
  }

  public Pixelate( String word, PFont font, int xPos, int yPos ) {
    this.word = word;
    
    if( font != null ){
      this.font = font;
    } else {
      this.font = createFont("Arial Bold", 120);
    }

    // Makes all particles draw the next word
    // Draw word in memory
    PGraphics pg = createGraphics(width, height);
    pg.beginDraw();
    pg.fill(0);
    pg.textSize(100);
    pg.textAlign(CENTER);
    pg.textFont(font);
    pg.text(this.word, xPos, yPos);
    pg.endDraw();
    pg.loadPixels();

    // Next color for all pixels to change to
    color newColor = color(0);

    int particleCount = particles.size();
    int particleIndex = 0;

    // Collect coordinates as indexes into an array
    // This is so we can randomly pick them to get a more fluid motion
    ArrayList<Integer> coordsIndexes = new ArrayList<Integer>();
    for (int i = 0; i < (width*height)-1; i+= pixelSteps) {
      coordsIndexes.add(i);
    }

    for (int i = 0; i < coordsIndexes.size (); i++) {
      // Pick a random coordinate
      int randomIndex = (int)random(0, coordsIndexes.size());
      int coordIndex = coordsIndexes.get(randomIndex);
      coordsIndexes.remove(randomIndex);

      // Only continue if the pixel is not blank
      if (pg.pixels[coordIndex] != 0) {
        // Convert index to its coordinates
        int x = coordIndex % width;
        int y = coordIndex / width;

        Particle newParticle;

        if (particleIndex < particleCount) {
          // Use a particle that's already on the screen 
          newParticle = particles.get(particleIndex);
          newParticle.isKilled = false;
          particleIndex += 1;
        } else {
          // Create a new particle
          newParticle = new Particle();

          PVector randomPos = generateRandomPos(width/2, height/2, (width+height)/2);
          newParticle.pos.x = randomPos.x;
          newParticle.pos.y = randomPos.y;

          newParticle.maxSpeed = random(2.0, 5.0);
          newParticle.maxForce = newParticle.maxSpeed*0.025;
          newParticle.particleSize = random(3, 6);
          newParticle.colorBlendRate = random(0.0025, 0.03);

          particles.add(newParticle);
        }

        // Blend it from its current color
        newParticle.startColor = lerpColor(newParticle.startColor, newParticle.targetColor, newParticle.colorWeight);
        newParticle.targetColor = newColor;
        newParticle.colorWeight = 0;

        // Assign the particle's new target to seek
        newParticle.target.x = x;
        newParticle.target.y = y;
      }
    }

    // Kill off any left over particles
    if (particleIndex < particleCount) {
      for (int i = particleIndex; i < particleCount; i++) {
        Particle particle = particles.get(i);
        particle.kill();
      }
    }
  }

  void drawPixels() {
    push();

    // Background & motion blur
    noStroke();
//    rect(0, 0, width*2, height*2);

    for (int x = particles.size ()-1; x > -1; x--) {
      // Simulate and draw pixels
      Particle particle = particles.get(x);
      particle.move();
      particle.draw();

      // Remove any dead pixels out of bounds
      if (particle.isKilled) {
        if (particle.pos.x < 0 || particle.pos.x > width || particle.pos.y < 0 || particle.pos.y > height) {
          particles.remove(particle);
        }
      }
    }

    pop();
  }
}

// Picks a random position from a point's radius
PVector generateRandomPos(int x, int y, float mag) {
  PVector randomDir = new PVector(random(0, width), random(0, height));

  PVector pos = new PVector(x, y);
  pos.sub(randomDir);
  pos.normalize();
  pos.mult(mag);
  pos.add(x, y);

  return pos;
}
