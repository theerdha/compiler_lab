#include "myl.h"

int printStr(char * c)
{
	int i  = 0;
	int ret = 0;
	while(c[i] != '\0')
	{
		i++;
	}
    

	__asm__ __volatile__ (
		"movl $1, %%eax \n\t"
		"movq $1, %%rdi \n\t"
		"syscall \n\t"
		:"=r"(ret)
		:"S"(c),"d"(i+1)

	);

	char a[1] ;
	a[0] = '\n';

	__asm__ __volatile__ (
		"movl $1, %%eax \n\t"
		"movq $1, %%rdi \n\t"
		"syscall \n\t"
		:
		:"S"(a),"d"(1)

	);
	return ret-1;
	//without \0 at the end
}

int readInt(int * n)
{
	int ret = 0;
	char buff[9] = {0};
	__asm__ __volatile__ (
		"movl $0, %%eax \n\t"
		"movq $0, %%rdi \n\t"
		"syscall \n\t"
		: "=r"(ret)
		:"S"(buff),"d"(9)

	);
	
	int i;
	if(buff[0] == '-') i = 1;
	else i = 0;
	while(buff[i] != '\n')
	{
		i++;
	}
	
	i--;

	for(int y = 0; y <= i; y++)
	{
		if(! ((48 <= buff[y] && buff[y] <= 57) || buff[y] == 45)) return ERR;
	}

	for(int y = 1; y <= i; y++)
	{
		if(! ((48 <= buff[y] && buff[y] <= 57))) return ERR;
	}


	int k = 1;
	int num = 0;

	if(buff[0] == '-')
	{
		while(i >= 1)
		{
			num += k * (buff[i] - '0');
			i --;
			k = k*10; 
		}
		num = -num;
	}

	else
	{
		while(i >= 0)
		{
			num += k * (buff[i] - '0');
			i --;
			k = k*10; 
		}
	}
    
	return num;
}

int printInt(int n)
{
	char buff[9];
	char zero='0';
	int i=0,j,k,bytes;
	int ret = 0;
	if(n==0) buff[i++]=zero;
	else
	{
		if(n<0) 
		{
			buff[i++]='-';
			n=-n;
		}
		while(n)
		{
			int dig=n%10;
			buff[i++]=(char)(zero+dig);
			n/=10;
		}
		if(buff[0]=='-') j=1;
		else j=0;
		k=i-1;
		while(j<k)
		{
			char temp=buff[j];
			buff[j++]=buff[k];
			buff[k--]=temp;
		}
	}
	buff[i]='\n';
	bytes=i+1;
	__asm__ __volatile__ (
		"movl $1, %%eax \n\t"
		"movq $1, %%rdi \n\t"
		"syscall \n\t"
		: "=r"(ret)
		:"S"(buff),"d"(bytes)

	);
	
	if(ret < 0) return ERR;
    else return ret-1;
    //ret - 1 if we dont count "\n"
} 

int readFlt(float *f)
{
	char buff[10] = {0};
	int ret;
	__asm__ __volatile__ (
		"movl $0, %%eax \n\t"
		"movq $0, %%rdi \n\t"
		"syscall \n\t"
		:"=r"(ret)
		:"S"(buff),"d"(10)

	);


	int total_length ;
	if(buff[0] == '-') total_length = 1;
	else total_length = 0;
	int dot = -1;
	while(buff[total_length] != '\n')
	{
		if(buff[total_length] == '.') dot = total_length;
		total_length++;
	}
	
	total_length--;

	for(int y = 0; y <= total_length; y++)
	{
		if(! ((48 <= buff[y] && buff[y] <= 57) || buff[y] == 45 || buff[y] == 46)) return ERR;
	}

	for(int y = 1; y <= total_length; y++)
	{
		if(! ((48 <= buff[y] && buff[y] <= 57) || buff[y] == 46)) return ERR;
	}

	int noofdots = 0;
	if(buff[0] == '.')return ERR;
	for(int y = 0; y <= total_length; y++)
	{
		if(buff[y] == '.')  noofdots++;
	}
	if(noofdots > 1) return ERR; 


	if(dot == -1)
	{
		dot = total_length+1;
	}

	float num = 0;
	int i = dot - 1;
	float  k = 1;

	if(buff[0] == '-')

	{
		while(i >= 1)
		{
			num += k * (buff[i] - '0');
			i --;
			k = k*10; 
		}

		i = dot + 1;
		k = 0.1;
		while(i <= total_length)
		{
			num += k*(buff[i] - '0');
			i ++;
			k = k/10;
		}

		num = -num;
	}

	else
	{
		while(i >= 0)
		{
			num += k * (buff[i] - '0');
			i --;
			k = k*10; 
		}

		i = dot + 1;
		k = 0.1;
		while(i <= total_length)
		{
			num += k*(buff[i] - '0');
			i ++;
			k = k/10;
		}
	}

	
	*f = num;
	if(ret < 0) return ERR;
	else return OK;

}

int printFlt(float n)
{
	char str[20];
	int i = 0;
	int ret = 0;
	if(n<0) 
	{
		str[i++]='-';
		n=-n;
	}

    int ipart = (int)n;
    float fpart = n - (float)ipart;
    int f1part;
    
    
    if(ipart == 0) str[i++] = '0';
    else
	{   while (ipart)
	    {
	        str[i++] = (ipart%10) + '0';
	        ipart = ipart/10;
	    }
	}
    int k, j=i-1, temp;
    if(str[0]=='-') k=1;
		else k=0;
    while (k<j)
    {
        temp = str[k];
        str[k] = str[j];
        str[j] = temp;
        k++; j--;
    }

    str[i] = '\0';
    str[i] = '.';  
	fpart = fpart * 100000;
	f1part = (int)fpart;

    k = i + 1;
    i++;
    while (f1part)
    {
        str[i++] = (f1part%10) + '0';
        f1part = f1part/10;
    }
 
    while (i - k < 5)str[i++] = '0';
    j=i-1; 
    while (k<j)
    {
        temp = str[k];
        str[k] = str[j];
        str[j] = temp;
        k++; j--;
    }

    str[i] = '\n';
    int bytes=i+1;
    __asm__ __volatile__ (
		"movl $1, %%eax \n\t"
		"movq $1, %%rdi \n\t"
		"syscall \n\t"
		:"=r"(ret)
		:"S"(str),"d"(bytes)

	);

	if(ret < 0) return ERR;
	else return ret-1;
	 //ret - 1 if we dont count "\n"
}

int printDbl(double n)
{
	char str[20];
	int i = 0;
	int ret = 0;
	if(n<0) 
	{
		str[i++]='-';
		n=-n;
	}

    int ipart = (int)n;
    float fpart = n - (float)ipart;
    int f1part;
    
    
    if(ipart == 0) str[i++] = '0';
    else
	{   while (ipart)
	    {
	        str[i++] = (ipart%10) + '0';
	        ipart = ipart/10;
	    }
	}
    int k, j=i-1, temp;
    if(str[0]=='-') k=1;
		else k=0;
    while (k<j)
    {
        temp = str[k];
        str[k] = str[j];
        str[j] = temp;
        k++; j--;
    }

    str[i] = '\0';
    str[i] = '.';  
	fpart = fpart * 100000;
	f1part = (int)fpart;

    k = i + 1;
    i++;
    while (f1part)
    {
        str[i++] = (f1part%10) + '0';
        f1part = f1part/10;
    }
 
    while (i - k < 5)str[i++] = '0';
    j=i-1; 
    while (k<j)
    {
        temp = str[k];
        str[k] = str[j];
        str[j] = temp;
        k++; j--;
    }

    str[i] = '\n';
    int bytes=i+1;
    __asm__ __volatile__ (
		"movl $1, %%eax \n\t"
		"movq $1, %%rdi \n\t"
		"syscall \n\t"
		:"=r"(ret)
		:"S"(str),"d"(bytes)

	);

	if(ret < 0) return ERR;
	else return ret-1;
	 //ret - 1 if we dont count "\n"
}

