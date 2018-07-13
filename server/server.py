from flask import Flask, request
import pickle
import os
from os.path import expanduser
from random import randint

app = Flask(__name__)

@app.route('/', methods=['POST'])
def result():
    #print(request.headers) # should display 'bar'
    print(len(request.data))

    if request.headers['Type'] == 'Baseline':
        fh = open("baseline.jpg", 'wb')
        fh.write(request.headers['Image'].decode('base64'))
        fh.close()

    x = randint(0, 100000)        
    
    fh = open("//Users/mnarang//hack//server//test//" + str(x) + ".jpg", "wb")
    fh.write(request.headers['Image'].decode('base64'))
    fh.close()

    #outfile = open("img.jpg", 'wb')  # Open a file for binary write
    #outfile.write(request.data)  # Write it
    #outfile.flush()  # Optional but a good idea
    #outfile.close()

    return 'Received !' # response to your request.

app.run("0.0.0.0", port=8100)