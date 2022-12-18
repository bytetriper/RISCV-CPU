#include"io.h"
int a=100;
void f(int c){
    if(c>1)
    {    
        a/=10;
        outb(a+96);
        f(c-1);
    }
    else
    {
        a=a+1;
    }
}
int main(){
    //outl(1357);
    outl(1357);
    return a;
}