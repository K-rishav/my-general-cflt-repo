# python3 stringify-gcp-credentials.py gcp-credentials.json output.txt
#!/usr/bin/python

import os
import sys
import json

script_path = os.path.abspath(__file__) # i.e. /path/to/dir/foobar.py
script_dir = os.path.split(script_path)[0] #i.e. /path/to/dir/
print(script_dir)
rel_path_input = sys.argv[1]
rel_path_output = sys.argv[2]

abs_file_path_input = os.path.join(script_dir, rel_path_input)
print(abs_file_path_input)
abs_file_path_output = os.path.join(script_dir, rel_path_output)
print(abs_file_path_output)

with open(abs_file_path_input) as f:
  data = json.load(f)


with open(abs_file_path_output,"w+" ) as f:
  f.write(json.dumps(json.dumps(data)))
