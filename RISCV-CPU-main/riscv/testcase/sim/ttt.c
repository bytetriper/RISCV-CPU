#include"io.h"
int a=200;
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
int rm(int c){
    if(c<0)return 1;
    return 0;
}
int main(){
    f(300);
    outlln(172);
    outlln(342);
    return a;
}