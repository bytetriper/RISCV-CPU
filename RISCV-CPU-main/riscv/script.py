
for i in range(32):
    for j in range(i):
        print("    ",end='')
    print("(Valid[{}]&Busy[{}])?{}:".format(i,i,i))