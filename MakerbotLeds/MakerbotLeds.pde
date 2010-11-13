/* -*- mode: c++ -*- */
#include <Messenger.h>

/* Change these two definitions if you add or remove any
 * LEDs */
#define COLORLEDCOUNT 1
#define FADELEDCOUNT 1

/* This changes the minimum and maximum output level for the
 * colored LEDs */
#define RGBMIN 0
#define RGBMAX 255

/* The same as above, but for the normal LEDs */
#define MONOMIN 0
#define MONOMAX 255

/* Don't change these */
#define CHANNELCOUNT 3
#define RED 0
#define GREEN 1
#define BLUE 2

#define DEBOUNCE 50

struct rgb {
  int r, g, b, rpin, gpin, bpin;
};

/* Change/add RGB LEDs here. The format is {Red Value, Green
 * Value, Blue Value, Red Pin, Green Pin, Blue Pin} where
 * the values only control the initial value. Each set of
 * brackets should be followed by a comma */
struct rgb color[COLORLEDCOUNT] = {
  {RGBMAX, RGBMIN, RGBMIN, 6, 5, 3}
};

struct rgb usercolor = {0, 0, 0, 6, 5, 3};

struct fade {
  int level, pin;
  bool inc;
};

/* Change/add normal LEDs here. The format is {Initial
 * Value, Pin, Increasing}. */
struct fade mono[FADELEDCOUNT] = {
  {MONOMIN, 9, true}
};

/* The delay between color changes. Lower values mean faster
 * fading. Set to zero to not wait at the end of an
 * iteration. */
unsigned int delaytime = 30;

/* The value to change the color by on each iteration. Lower
 * values mean slower fading. Set this to zero to disable
 * color fading. */
unsigned int rgbdelta = 1;

/* The value to change levels by on each iteration.  Lower
 * values mean slower fading. Set this to zero to disable
 * pulsing. */
unsigned int fadedelta = 1;

unsigned int i, j, k;

/* When this is false, everything is off. */
boolean enablefade = true;

Messenger ser = Messenger();

long lastpress = 0;

int stepmono(struct fade* output) {
  if (output->level <= MONOMIN || output->level >= MONOMAX)
    output->inc = !output->inc;

  if (output->inc) {
    output->level += fadedelta;
    if (output->level > MONOMAX)
      output->level = MONOMAX;
  } else {
    output->level -= fadedelta;
    if (output->level < MONOMIN)
      output->level = MONOMIN;
  }

  return 0;
}

int steprgb(struct rgb* output) {
  if (output->r == RGBMIN && output->g > RGBMIN && output->b == RGBMAX) {
    output->g -= rgbdelta;
    if (output->g < RGBMIN) {
      output->g = RGBMIN;
    }
  } else if (output->r < RGBMAX && output->g == RGBMIN && output->b == RGBMAX) {
    output->r += rgbdelta;
    if (output->r > RGBMAX) {
      output->r = RGBMAX;
    }
  } else if (output->r == RGBMAX && output->g == RGBMIN && output->b > RGBMIN) {
    output->b -= rgbdelta;
    if (output->b < RGBMIN) {
      output->b = RGBMIN;
    }
  } else if (output->r == RGBMAX && output->g < RGBMAX && output->b == RGBMIN) {
    output->g += rgbdelta;
    if (output->g > RGBMAX) {
      output->g = RGBMAX;
    }
  } else if (output->r > RGBMIN && output->g == RGBMAX && output->b == RGBMIN) {
    output->r -= rgbdelta;
    if (output->r < RGBMIN) {
      output->r = RGBMIN;
    }
  } else if (output->r == RGBMIN && output->g == RGBMAX && output->b < RGBMAX) {
    output->b += rgbdelta;
    if (output->b > RGBMAX) {
      output->b = RGBMAX;
    }
  }

  return 0;
}

void setcolor(struct rgb* output, boolean transform=true) {
  if (transform) {
    unsigned int r, g, b;

    r = (output->r > 254) ? 1 : 255 - output->r;
    g = (output->g > 254) ? 1 : 255 - output->g;
    b = (output->b > 254) ? 1 : 255 - output->b;

    analogWrite(output->rpin, r);
    analogWrite(output->gpin, g);
    analogWrite(output->bpin, b);
  } else {
    analogWrite(output->rpin, output->r);
    analogWrite(output->gpin, output->g);
    analogWrite(output->bpin, output->b);
  }
}

void setmono(struct fade* output) {
  analogWrite(output->pin, output->level);
}

/* Messages of the form "[enable] [red] [green] [blue]" are expected,
 * where enable is 0 to set to autofade, and RGB values are in the
 * interval [0,1023] */
void message() {
  if (ser.readInt() == 0) {
    enablefade = true;
    delaytime = ser.readInt();
    rgbdelta = ser.readInt();
    return;
  }
  enablefade = false;

  usercolor.r = ser.readInt();
  usercolor.g = ser.readInt();
  usercolor.b = ser.readInt();

  setcolor(&usercolor, false);
}

void setup() {
  for (i=0; i<COLORLEDCOUNT; i++) {
    pinMode(color[i].rpin, OUTPUT);
    pinMode(color[i].gpin, OUTPUT);
    pinMode(color[i].bpin, OUTPUT);
  }

  for (i=0; i<FADELEDCOUNT; i++) {
    pinMode(mono[i].pin, OUTPUT);
  }

  Serial.begin(9600);
  ser.attach(message);
}

void loop() {
  if (enablefade) {
    for (i=0; i<COLORLEDCOUNT; i++) {
      steprgb(&color[i]);
      setcolor(&color[i]);
    }

    for (i=0; i<FADELEDCOUNT; i++) {
      stepmono(&mono[i]);
      setmono(&mono[i]);
    }

    delay(delaytime);
  }

  while (Serial.available()) {
    ser.process(Serial.read());
  }
}
