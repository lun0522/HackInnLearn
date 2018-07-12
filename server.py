from flask import Flask, request
import pickle

app = Flask(__name__)
@app.route('/', methods=['POST'])
def result():
    request.headers['Type'] # should display 'bar'
    print(len(request.data))

    outfile = open("img.jpg", 'wb')  # Open a file for binary write
    outfile.write(request.data)  # Write it
    outfile.flush()  # Optional but a good idea
    outfile.close()

    return 'Received !' # response to your request.

app.run("0.0.0.0", port=8100)