import requests

img = open("test.jpg", 'rb').read()
headers = {'Type': 'Baseline'}
r = requests.post("http://10.202.0.179:8100", data=img, headers=headers)

# And done.
print(r.text) # displays the result body.