// code from: https://docs.opencv.org/4.x/d1/dc5/tutorial_background_subtraction.html
// and https://opencv.org/blog/reading-and-writing-videos-using-opencv/#h-writing-a-video-in-opencv
#include <iostream>
#include <sstream>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/videoio.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/video.hpp>
#include <windows.h>
#include <time.h>
#include <vector>


using namespace cv;
using namespace std;

const char* params
= "{ help h         |           | Print usage }"
"{ input          | short.mp4 | Path to a video or a sequence of image }"
"{ algo           | MOG2      | Background subtraction method (KNN, MOG2) }";


void bgsubThread(Ptr<BackgroundSubtractor> pBackSub, int i, Mat frame, vector<Mat> fgMasks) {
    Mat fgMask;
    pBackSub->apply(frame, fgMask);
    fgMasks[i] = fgMask.clone();
}

int main(int argc, char* argv[])
{
    CommandLineParser parser(argc, argv, params);
    parser.about("This program shows how to use background subtraction methods provided by "
        " OpenCV. You can process both videos and images.\n");
    if (parser.has("help"))
    {
        //print help information
        parser.printMessage();
    }

    //create Background Subtractor objects
    Ptr<BackgroundSubtractor> pBackSub;
    if (parser.get<String>("algo") == "MOG2")
        pBackSub = createBackgroundSubtractorMOG2();
    else
        pBackSub = createBackgroundSubtractorKNN();

    VideoCapture capture(samples::findFile(parser.get<String>("input")));
    if (!capture.isOpened()) {
        //error in opening the video input
        cerr << "Unable to open: " << parser.get<String>("input") << endl;
        return 0;
    }

    // Get frame width and height
    int frame_width = static_cast<int>(capture.get(cv::CAP_PROP_FRAME_WIDTH));
    int frame_height = static_cast<int>(capture.get(cv::CAP_PROP_FRAME_HEIGHT));

    // Define the codec and create VideoWriter object
    cv::VideoWriter out("output.avi", cv::VideoWriter::fourcc('X', 'V', 'I', 'D'), 30.0, cv::Size(frame_width, frame_height));
    cv::VideoWriter out2("output.avi", cv::VideoWriter::fourcc('X', 'V', 'I', 'D'), 30.0, cv::Size(frame_width, frame_height));



    // TIMER
    clock_t start, end;
    double total_time_seq, total_time_thread;
    int n = 0;

    Mat frame, fgMask, fgMaskColor;
    vector<Mat> frames, fgMasks;

    // sequential
    //get all the input frames
    while (true) {
        capture >> frame;
        if (frame.empty())
            break;
        frames.push_back(frame.clone());
        n++;
    }

    start = clock();
    for (int i = 0; i < n; i++) {
        //update the background model
        pBackSub->apply(frames[i], fgMask);
        fgMasks.push_back(fgMask.clone());
    }
    end = clock();
    total_time_seq = ((double)(end - start)) * 1E3 / CLOCKS_PER_SEC;


    for (int i = 0; i < n; i++) {
        cv::cvtColor(fgMasks[i], fgMaskColor, COLOR_GRAY2BGR);

        //write the frame to the output video file
        out.write(fgMaskColor);
    }

    printf("Sequential done!\n");
    
    // threaded
    vector<thread> threads;
    start = clock();
    //launch all threads in parallel
    for (int i = 0; i < n; i++) {
        threads.emplace_back(bgsubThread, pBackSub, i, frames[i], fgMasks);
    }

    //join all threads after they are started
    for (auto& t : threads) {
        t.join();
    }
    end = clock();
    total_time_thread = ((double)(end - start)) * 1E3 / CLOCKS_PER_SEC;

    printf("Parallel done!\n");
    for (int i = 0; i < n; i++) {
        cv::cvtColor(fgMasks[i], fgMaskColor, COLOR_GRAY2BGR);

        //write the frame to the output video file
        out2.write(fgMaskColor);
    }
    

    capture.release();
    out.release();
    out2.release();

    printf("\n\nn = %d\n", n);
    printf("total time C GMM = %llf\n", total_time_seq);
    printf("total time threaded GMM = %llf\n", total_time_thread);


    return 0;
}