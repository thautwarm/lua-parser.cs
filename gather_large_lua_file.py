import os
import io
xs = open("test.lua", 'w', encoding='utf-8')

for dirname, _, filenames in os.walk("tests"):
    
    for filename in filenames:
        if filename.endswith(".lua"):
            with open(os.path.join(dirname, filename), encoding='utf-8') as f:
                xs.write("do\n")
                xs.write(f.read())
                xs.flush()
                xs.write("end\n")
                xs.write("\n")

xs.close()