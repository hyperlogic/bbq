#ifndef APP_H
#define APP_H

struct Color {
    float r;
    float g;
    float b;
    float a;
};
struct App {
    Color clear_color;
    Color quad_color;
};

#endif
