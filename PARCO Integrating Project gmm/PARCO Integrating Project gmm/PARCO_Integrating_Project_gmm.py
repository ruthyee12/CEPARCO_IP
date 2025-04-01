import cv2
import numpy as np

# Initializing the Gaussian Mixture Model (GMM)
n_gaussians = 3  # Number of Gaussians
alpha = 0.03     # Increased learning rate for faster updates
T = 0.7         # Threshold for foreground detection

# Function for normalizing probability density function
def norm_pdf(x, mean, sigma):
    return (1 / (np.sqrt(2 * np.pi) * sigma)) * np.exp(-0.5 * ((x - mean) / sigma) ** 2)

# Capture video
cap = cv2.VideoCapture('short.mp4')  

if not cap.isOpened():
    print("Error: Unable to open video.")
    exit()

# Read first frame
ret, frame = cap.read()
if not ret:
    print("Error: Failed to read video frame.")
    exit()

# Convert to grayscale
frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

# Initialize the background model (GMM)
rows, cols = frame_gray.shape
mean = np.zeros([n_gaussians, rows, cols], np.float64)
variance = np.zeros([n_gaussians, rows, cols], np.float64)
omega = np.zeros([n_gaussians, rows, cols], np.float64)

# Set initial values
mean[1, :, :] = frame_gray
variance[:, :, :] = 400
omega[0, :, :], omega[1, :, :], omega[2, :, :] = 0, 0, 1

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Convert frame to grayscale
    frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY).astype(np.float64)

    # Compute foreground mask
    sigma = np.sqrt(variance[1])  
    diff = cv2.absdiff(frame_gray, mean[1])  

    # Detect foreground
    foreground_mask = (diff > T * sigma).astype(np.uint8) * 255  

    # Update background model
    rho = alpha * norm_pdf(frame_gray, mean[1], sigma)  
    mean[1] = (1 - rho) * mean[1] + rho * frame_gray  
    variance[1] = (1 - rho) * variance[1] + rho * (frame_gray - mean[1]) ** 2  

    # Display the foreground mask
    cv2.imshow('Foreground Mask', foreground_mask)

    # Exit
    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()
