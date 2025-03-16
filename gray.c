#include <stdio.h>
#include <stdlib.h>
//sample ppm processing code makes the image grayscale
typedef struct {
    unsigned char r, g, b;
} Pixel;

void convertToGrayscale(Pixel *pixels, int width, int height) {
    for (int i = 0; i < width * height; i++) {
        unsigned char gray = (unsigned char)(0.299 * pixels[i].r + 0.587 * pixels[i].g + 0.114 * pixels[i].b);
        pixels[i].r = pixels[i].g = pixels[i].b = gray; 
    }
}

void readPPM(const char *filename, Pixel **pixels, int *width, int *height) {
    FILE *fp = fopen(filename, "rb");
    if (!fp) {
        printf("Error: Cannot open file %s\n", filename);
        exit(1);
    }

    char format[3];
    fscanf(fp, "%2s", format);
    if (format[0] != 'P' || format[1] != '6') {
        printf("Error: Not a P6 PPM file\n");
        fclose(fp);
        exit(1);
    }

    fscanf(fp, "%d %d\n255\n", width, height);

    int size = (*width) * (*height);
    *pixels = (Pixel *)malloc(size * sizeof(Pixel));

    fread(*pixels, sizeof(Pixel), size, fp);
    fclose(fp);
}

void writePPM(const char *filename, Pixel *pixels, int width, int height) {
    FILE *fp = fopen(filename, "wb");
    fprintf(fp, "P6\n%d %d\n255\n", width, height);
    fwrite(pixels, sizeof(Pixel), width * height, fp);
    fclose(fp);
    printf("Grayscale PPM saved as: %s\n", filename);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <input.ppm> <output.ppm>\n", argv[0]);
        return 1;
    }

    int width, height;
    Pixel *pixels;

    readPPM(argv[1], &pixels, &width, &height);
    convertToGrayscale(pixels, width, height);
    writePPM(argv[2], pixels, width, height);

    free(pixels);
    return 0;
}
