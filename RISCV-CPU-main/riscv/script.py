'''
for i in range(16):
    for j in range(i):
        print("    ",end='')
    print("(Read_Able[{}]&!Readed[{}])|".format(i,i))'''

for i in range(26):
    print("outb('{}');".format(chr(i+97)))