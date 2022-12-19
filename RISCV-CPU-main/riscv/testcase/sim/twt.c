#include"io.h" 
 int f(int a,int b)
{
    return a+b;
}
int main(){
    int a=1;int b=3;
    volatile int c=f(a,b);
   outb(c+96);
    return 0;
}