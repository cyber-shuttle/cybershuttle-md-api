# Python program to read
# json file

import json

# Opening JSON file
f = open('qwikmd.json')

# returns JSON object as 
# a dictionary
data = json.load(f)

# Iterating through the json
# list
for i in data['Input']:
	print(i.get('prm'))

# Closing file
f.close()
