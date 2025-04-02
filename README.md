# CEPARCO Integrating Project

## Overview
This project focuses on optimizing the ViBE background subtraction algorithm using SIMD (Single Instruction, Multiple Data) parallelization with AVX/AVX2 instructions. The implementation is designed for processing CCTV or stationary camera footage in real-time, providing an efficient method for background subtraction on devices lacking GPU acceleration.

To ensure correctness and efficiency, a non-parallelized C/C++ benchmark implementation is provided for verification. Performance comparisons are conducted against other parallelized background subtraction methods, including OpenCV's Gaussian Mixture Model and frame difference algorithms.

## Project Structure
### (1) PARCO Integrating Project parallel
- contains the parallelized ViBE algorithm utilizing SIMD operations.
- optimized for AVX/AVX2 instructions to accelerate Euclidean distance computations.
- processes video frames in parallel for real-time background subtraction.
### (2) PARCO Integrating Project real
- contains the basic, non-parallelized C implementation of the ViBE algorithm.
- serves as a benchmark for correctness verification and performance comparison.

## How to Run the Project
- download ffmpeg through: https://ffmpeg.org/download.html
- the guide on how to download ffmpeg can be found here: https://phoenixnap.com/kb/ffmpeg-windows
- open the Visual Studio solution provided in the repository.
- run the appropriate project (PARCO Integrating Project parallel for the SIMD implementation, or PARCO Integrating Project real for the basic implementation).
- the output video will be generated in the corresponding folder: PARCO Integrating Project parallel/PARCO Integrating Project parallel or PARCO Integrating Project real/PARCO Integrating Project real
- the default output video is set to 5 FPS for efficiency, as higher FPS requires more processing time.
- if the input video titled "short.mp4" cant be loaded because it's too large for git, here's an alternative link to copy paste into the folders mentioned above: https://drive.google.com/drive/folders/1gzh8Kjfhrz5VFJ5lVa8d7atMygARJhzE?usp=sharing

## Execution Screenshots

## Parallelization Approach
### (1) Original ViBE Algorithm (without AVX)
In the original, sequential Vibe algorithm:
- Each pixel in the current image is compared with the corresponding pixel in the history image.
- If the difference between the pixel values exceeds a predefined threshold, the pixel is marked for further processing.
- The segmentation map is updated based on the threshold check, one pixel at a time.

This approach processes pixels individually, which becomes inefficient for large images due to the lack of parallelism.
### (2) Parallelized ViBE Algorithm (with AVX)
In the AVX parallelized version of the Vibe algorithm, we performed several key optimizations:
1. Vectorized Loading: Instead of processing each pixel individually, we load 32 pixels into a single 256-bit AVX register, enabling parallel processing of multiple pixels at once.
2. Broadcast Threshold: The threshold value is broadcast across all 32 positions in the AVX register, ensuring that every pixel in the vector uses the same threshold for comparison.
3. Vectorized Subtraction: The absolute differences between the current image pixels and the corresponding pixels in the history image are computed simultaneously for all 32 pixels using SIMD instructions.
4. Threshold Comparison: The absolute differences are compared with the threshold in parallel, with each comparison being performed for all 32 pixels in a single instruction.
5. Segmentation Update: The segmentation map is updated in parallel by modifying the segmentation values for all 32 pixels simultaneously, based on the comparison results.

By processing 32 pixels per instruction cycle, we reduce the number of operations and speed up the algorithm significantly, especially for large images.
## Peformance Analysis

## Video Presentation

## Conclusion
