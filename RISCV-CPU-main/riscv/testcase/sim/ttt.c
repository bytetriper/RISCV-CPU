#include"io.h"
int a=1;
void f(int c){
    if(c>1)
    {    
        outb(a+96);
        f(c-1);
    }
    else
    {
        a=a+1;
    }
}
int main(){
    f(3);
    return a;
}