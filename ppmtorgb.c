#include <stdio.h>
#include <stdlib.h>
//PPM processing code to read and print RGB values of an image maybe not necessary or can be integrated into the other files
typedef struct {
    unsigned char r, g, b;  // Red, Green, Blue channels
} Pixel;

void processPPM(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        printf("Error: Could not open file %s\n", filename);
        return;
    }

    char format[3];
    int width, height, maxVal;

    fscanf(file, "%2s\n%d %d\n%d\n", format, &width, &height, &maxVal);

    if (format[0] != 'P' || format[1] != '6') {
        printf("Error: Not a P6 PPM file!\n");
        fclose(file);
        return;
    }

    Pixel **image = (Pixel **)malloc(height * sizeof(Pixel *));
    for (int i = 0; i < height; i++)
        image[i] = (Pixel *)malloc(width * sizeof(Pixel));

    for (int i = 0; i < height; i++)
        fread(image[i], sizeof(Pixel), width, file);

    fclose(file);

    printf("RGB Matrix of %s:\n", filename);
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            printf("(%3d,%3d,%3d) ", image[i][j].r, image[i][j].g, image[i][j].b);
        }
        printf("\n");
    }

    for (int i = 0; i < height; i++)
        free(image[i]);
    free(image);
}

int main() {
    processPPM("frame_0001.ppm"); //sample filename
    return 0;
}
