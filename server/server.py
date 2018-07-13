from flask import Flask, request
import pickle
import os
from os.path import expanduser
from random import randint
import requests
import face_recognition

app = Flask(__name__)

@app.route('/', methods=['POST'])
def result():
    print("Length of the data: ", len(request.data))

    if not os.path.isfile("//Users//mnarang//hack//server//baseline.jpg"):
        fh = open("//Users//mnarang//hack//server//baseline.jpg", 'wb')
        fh.write(request.headers['Image'].decode('base64'))
        fh.close()

    x = randint(0, 1000000)        
    
    fh = open("//Users/mnarang//hack//server//test//" + str(x) + ".jpg", "wb")
    fh.write(request.headers['Image'].decode('base64'))
    fh.close()

    known_image = face_recognition.load_image_file("//Users//mnarang//hack//server//baseline.jpg")
    unknown_image = face_recognition.load_image_file("//Users/mnarang//hack//server//test//" + str(x) + ".jpg")

    # Check if the unknown image is a face
    faces = face_recognition.face_locations(unknown_image)
    print("Number of faces in the frame: ", faces)

    biden_encoding = face_recognition.face_encodings(known_image)[0]
    if len(faces) != 0:
        unknown_encoding = face_recognition.face_encodings(unknown_image)[0]

        results = face_recognition.compare_faces([biden_encoding], unknown_encoding)
        print(results)

        ''' Only uncomment when running client.
        outfile = open("img.jpg", 'wb')  # Open a file for binary write
        outfile.write(request.data)  # Write it
        outfile.flush()  # Optional but a good idea
        outfile.close() '''

        ret = results[0]
        ret = str(ret)
        return ret

    return "No face"

app.run("0.0.0.0", port=8100)