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

## Peformance Analysis

## Video Presentation

## Conclusion
