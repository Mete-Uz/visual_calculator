import json

from flask import Flask, render_template, request, jsonify
from language_understanding import *
from vision import *
from stats import *
from functions import *

app = Flask(__name__)

@app.route('/solve_matheq', methods = ['POST'])
def mathsolution():
    if request.method == 'POST':
        req_data = request.get_json()
        lateks = req_data['latex']
        lateks = lateks.replace("\\\\", "\\")
        lateks = lateks.replace("\"", "")
        lateks = lateks.replace("\n", "")
        phrase = req_data['phrase']
        intent = get_intent(phrase)
        res = solve_matheq(lateks, intent)
        res = res.replace("\\left", "")
        res = res.replace("\\right", "")
        return jsonify(res)

@app.route('/img2table', methods = ['POST'])
def image2table():
    if request.method == 'POST':
        img = request.files['file']
        img.save("img.jpg")
        image = cv2.imread("img.jpg")
        res = imageToDataframe(image)
        df_list = res.values.tolist()
        JSONP_data = jsonify(df_list)
        return JSONP_data

@app.route('/stats', methods = ['POST'])
def statable():
    if request.method == 'POST':
        buffer = ''
        flag = False
        firtflag = False
        List = []
        List_squared = []
        req_data= request.get_json()
        for c in req_data['list']:
            if flag and c != ',' and c != ']':
                buffer = buffer + c
            if c == '[':
                if firtflag:
                    flag = True
                firtflag = True

            if c == ',' and flag:
                List.append(buffer)
                buffer = ''
            if c == ']' and flag:
                flag = False
                List.append(buffer)
                buffer = ''
                List_squared.append(List)
                List = []
        df = pd.DataFrame(List_squared).astype(float)
        phrase = req_data['phrase']
        intent = get_intent(phrase)
        type_,res = get_stats(df, intent)
        res_list = res.values.tolist()
        JSONP_data = jsonify(res_list)

        return JSONP_data

if __name__ == '__main__':
    app.run(host='0.0.0.0', port= 5000)
