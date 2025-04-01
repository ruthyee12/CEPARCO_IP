import cv2
import numpy as np

def nothing(x):
    pass

cv2.namedWindow('Difference')
cv2.createTrackbar('Min Val', 'Difference', 20, 255, nothing)
cv2.createTrackbar('Max Val', 'Difference', 100, 255, nothing)

cap = cv2.VideoCapture('short.mp4')

ret, prev_frame = cap.read()
if not ret:
    print("Error: Unable to read video frame.")
    cap.release()
    cv2.destroyAllWindows()
    exit()

prev_gray = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)
prev_gray = cv2.GaussianBlur(prev_gray, (5, 5), 0)

frame_count = 0  

while True:
    ret, frame = cap.read()
    if not ret:
        break

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)

    diff = cv2.absdiff(prev_gray, gray)

    min_val = cv2.getTrackbarPos('Min Val', 'Difference')
    max_val = cv2.getTrackbarPos('Max Val', 'Difference')

    _, mask = cv2.threshold(diff, min_val, max_val, cv2.THRESH_BINARY)

    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    for contour in contours:
        if cv2.contourArea(contour) > 500:
            x, y, w, h = cv2.boundingRect(contour)
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)

    frame_count += 1
    if frame_count % 5 == 0:  # can change 5 if the vid is too fast
        prev_gray = gray.copy()

    cv2.imshow('Original', frame)
    cv2.imshow('Difference', mask)

    if cv2.waitKey(30) & 0xFF == 27: 
        break

cap.release()
cv2.destroyAllWindows()
