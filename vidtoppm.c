#include <stdio.h>
#include <stdlib.h>

int main() {
    // FFmpeg command to extract frames as raw RGB images
    // video is 1280 x 720p 10 secs long
    const char *cmd = "ffmpeg -i short.mp4 -vf \"fps=1\" frame_%04d.ppm";
    
    int ret = system(cmd);
    
    if (ret == 0) {
        printf("Frames extracted successfully!\n");
    } else {
        printf("Error extracting frames.\n");
    }
    
    return 0;
}
