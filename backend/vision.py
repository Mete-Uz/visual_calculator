from copy import deepcopy

import numpy as np
import pytesseract
from pytesseract import Output
import cv2
import imutils
import pandas as pd

pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'


def extractTable(file):
    gray = cv2.cvtColor(file, cv2.COLOR_BGR2GRAY)
    # gray = cv2.fastNlMeansDenoising(gray,gray)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (51, 11))
    gray = cv2.GaussianBlur(gray, (7, 7), 0)
    blackhat = cv2.morphologyEx(gray, cv2.MORPH_BLACKHAT, kernel)
    grad = cv2.Sobel(blackhat, ddepth=cv2.CV_32F, dx=1, dy=0, ksize=-1)
    grad = np.absolute(grad)
    (minVal, maxVal) = (np.min(grad), np.max(grad))
    grad = (grad - minVal) / (maxVal - minVal)
    grad = (grad * 255).astype("uint8")
    grad = cv2.morphologyEx(grad, cv2.MORPH_CLOSE, kernel)
    thresh = cv2.threshold(grad, 0, 255,
                           cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
    thresh = cv2.dilate(thresh, None, iterations=3)
    cnts = cv2.findContours(thresh.copy(), cv2.RETR_EXTERNAL,
                            cv2.CHAIN_APPROX_SIMPLE)

    cnts = imutils.grab_contours(cnts)
    biggest = max(cnts, key=cv2.contourArea)
    (x, y, w, h) = cv2.boundingRect(biggest)
    biggest = file[y:y + h, x:x + w]
    im = deepcopy(file)
    cv2.rectangle(im, (x, y), (x + w, y + h), (0, 255, 0), 2)
    return biggest


def normalOrientation(image):
    height, width, _ = image.shape
    image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    im_bw = cv2.threshold(image, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
    lines = cv2.HoughLinesP(im_bw, 1, np.pi / 180, 200, minLineLength=width / 12, maxLineGap=width / 150)
    angles = []
    if lines is not None:
        for line in lines:
            x1, y1, x2, y2 = line[0]
            angles.append(np.arctan2(y2 - y1, x2 - x1))
    landscape = np.sum([abs(angle) > np.pi / 4 for angle in angles]) > len(angles) / 2
    if landscape:
        angles = [
            angle
            for angle in angles
            if np.deg2rad(90 - 30) < abs(angle) < np.deg2rad(90 + 30)
        ]
    else:
        angles = [angle for angle in angles if abs(angle) < np.deg2rad(30)]

    if len(angles) < 5:
        return image
    angle_deg = np.rad2deg(np.median(angles))
    if landscape:
        if angle_deg < 0:
            image = cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE)
            angle_deg += 90
        elif angle_deg > 0:
            image = cv2.rotate(image, cv2.ROTATE_90_COUNTERCLOCKWISE)
            angle_deg -= 90
    M = cv2.getRotationMatrix2D((width / 2, height / 2), angle_deg, 1)
    image = cv2.warpAffine(image, M, (width, height), borderMode=cv2.BORDER_REPLICATE)
    return image


def sharpenText(img):
    filter = np.array([[-1, -1, -1], [-1, 9, -1], [-1, -1, -1]])
    return cv2.filter2D(img, -1, filter)


def biggestNumRange(strlist):
    emptyitems = []
    a, b, curr, max_ = -1, -1, -1, -1
    for c in range(len(strlist)):
        if strlist[c] == '':
            emptyitems.append(c)
    if len(emptyitems) == 0:
        return -1, len(strlist)
    for index in emptyitems:
        if curr == -1:
            curr = index
        elif index - curr > max_:
            max_ = index - curr
            a, b = curr, index
            curr = index
        else:
            curr = index
    if max_ == -1:
        if curr > len(strlist) - 1:
            return -1, curr
        else:
            return curr, len(strlist)
    return a, b


def findColNum(list_of_lists):
    list_len = []
    for i in list_of_lists:
        if len(i) != 0:
            list_len.append(len(i))
    return max(list_len, key=list_len.count)


def imageToDataframe(file):
    biggest = extractTable(file)
    biggest = normalOrientation(biggest)
    height, width = biggest.shape
    results = pytesseract.image_to_data(biggest, config="--psm 6", output_type=Output.DICT)
    coords = []
    ocrText = []
    for i in range(0, len(results["text"])):
        x = results["left"][i]
        y = results["top"][i]
        text = results["text"][i]
        conf = results["conf"][i]
        if float(conf) > 50:
            coords.append((x, y))
            ocrText.append(text)
    table = []
    row = []
    x_coords = []
    x_row = []
    for c in range(len(coords)):
        numerics = ''
        for char in ocrText[c]:
            if char.isdigit() or char == '.' or char == ',':
                if char == ',':
                    char = '.'
                numerics += char
        row.append(numerics)
        if not numerics == '':
            x_row.append(coords[c][0])
        if c + 1 >= len(coords):
            x_coords.append(x_row)
            table.append(row)
            break
        if not (coords[c][1] - height / 50 <= coords[c + 1][1] <= coords[c][1] + height / 50):
            x_coords.append(x_row)
            table.append(row)
            row = []
            x_row = []
    final = []
    x_coords_final = []
    for (strlist, crod) in zip(table, x_coords):
        start, end = biggestNumRange(strlist)
        final.append(strlist[start + 1: end])
        x_coords_final.append(crod[start: end])
    num_col = findColNum(final)
    bad_rows = []
    for c in range(len(final)):
        if len(final[c]) == num_col:
            canonical_x = x_coords_final[c]
            break
    for c in range(len(final)):
        null_index = []
        if not (num_col * 0.75 <= len(final[c]) <= num_col * 1.25):
            bad_rows.insert(0, c)
        else:
            ind = 0
            for d in range(num_col):
                try:
                    if not (canonical_x[d] - width / 50 <= x_coords_final[c][ind] <= canonical_x[d] + width / 50):
                        null_index.insert(0, d)
                    else:
                        ind += 1
                except:
                    print('ERR')
            for e in null_index:
                final[c].insert(e, None)
    for c in bad_rows:
        final.pop(c)
    final = pd.DataFrame(final)
    return final.round(2).astype(float)


if __name__ == "__main__":
    image = cv2.imread('test.png')
    _, img_encoded = cv2.imencode('.png', image)
    img_encode = np.array(img_encoded)
    print(imageToDataframe(image))
