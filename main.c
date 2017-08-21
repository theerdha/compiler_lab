#include "myl.h"

int main()
{
    int z,ret;
	
     int i = -1200;
     ret = printInt(i);
     printInt(ret); 


    // printf("print float\n");
     float n = -1.256;
    ret =  printFlt(n);
    printInt(ret);

     
     char * str = "hey my name is theerdha";  
     ret = printStr(str);
      printInt(ret);

    
     int k;
     ret = readInt(&k);
    
     if(ret != ERR)printInt(k);
     printInt(ret);

     
    float f;
    z = readFlt(&f);
    if(z != ERR)printFlt(f);
    printInt(z);
    

    return 0;
}