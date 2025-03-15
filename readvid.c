#include <stdio.h>
#define W 1280
#define H 720
//1280*720p resolution

unsigned char frame[H][W][3] = {0};

void main()
{
    int x, y, count;
    FILE *pipein = popen("ffmpeg -i input.mp4 -f image2pipe -vcodec rawvideo -pix_fmt rgb24 -", "r");
    FILE *pipeout = popen("ffmpeg -y -f rawvideo -vcodec rawvideo -pix_fmt rgb24 -s 1280x720 -r 30 -i - -f mp4 -q:v 5 -an -vcodec mpeg4 output.mp4", "w");

    while(1)
    {
        count = fread(frame, 1, H*W*3, pipein);
        if (count != H*W*3)
            break;

        for (y = 0; y < H; y++)
            for (x = 0; x < W; x++)
            {
                frame[y][x][0] = frame[y][x][0] * 0.393 + frame[y][x][1] * 0.769 + frame[y][x][2] * 0.189;
                frame[y][x][1] = frame[y][x][0] * 0.349 + frame[y][x][1] * 0.686 + frame[y][x][2] * 0.168;
                frame[y][x][2] = frame[y][x][0] * 0.272 + frame[y][x][1] * 0.534 + frame[y][x][2] * 0.131;
            }

        fwrite(frame, 1, H*W*3, pipeout);
    }

    fflush(pipein);
    pclose(pipein);
    fflush(pipeout);
    pclose(pipeout);
}