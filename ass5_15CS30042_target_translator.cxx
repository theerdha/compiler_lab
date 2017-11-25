#include "ass5_15CS30042_translator.h"
#include <iostream>
#include <string>
#include <vector>
#include <stdlib.h>
#include <cstring>
#include "y.tab.h"
#include "myl.h"

using namespace std;

symbolTable* global_symbol_table = new symbolTable("Global"); 


/*handling  string constants as assembler symbols in Data Segments */

string makeConstants()
{
	string buff = "";
	buff += "\t.section\t.rodata\n";
	for(int i = 0; i < StringSet.size();i++)
	{
		buff += ".s" + conv2string(i) +":\n";
		buff += "\t.string "+ StringSet.at(i) + "\n";
	}

	int *a;

	for(int i = 0; i < doubleSet.size();i++)
	{
		double d = doubleSet.at(i);
		a = (int *)(&d);
		buff += ".LC" + conv2string(i) +":\n";
		buff += "\t.long "+ conv2string(a[0]) + "\n";
		buff += "\t.long "+ conv2string(a[1]) + "\n";
	}

	return buff;
}

int getIndexDouble(double d)
{
	for(int i = 0; i < doubleSet.size();i++)
	{
		if(d == doubleSet.at(i)) return i;
	}
	return -1;
}

// Utility function to test
void printstr()
{
	for(int i=0; i< StringSet.size();i++)
	{
		cout << StringSet.at(i)<<endl;
	}
}


/*Generation of Function Prologue - few lines of code at the beginning
of a function,  which prepare the stack and registers for use within
the function. */
string Prologue(symbolTable* ST)
{
	string s = "";
	s += "\t.text\n";
	s += "\t.globl "+ST->name+"\n";
	s += "\t.type "+ST->name+", @function\n";
	s += ST->name + ":\n";
	s += "\tpushq %rbp\n";
	s += "\tmovq %rsp, %rbp\n";
	s += "\tsubq $"+conv2string((ST->offset/16)*16)+", %rsp\n";

	if((ST -> f -> typelist).size() >= 1) s += "\tmovq %rdi, -4(%rbp)\n";
	if((ST -> f -> typelist).size() >= 2) s += "\tmovq %rsi, -8(%rbp)\n";


	//cout << "size to check of "<< ST -> name << "  " << (ST -> f -> typelist).size() << endl;
	return s;
}

/*Generate Function Epilogue - appears at the end of the function, and
restores the stack and registers to the state they were in before the
function was called.*/

string Epilogue(symbolTable* ST)
{
	string s = "";
	s += ".ret_"+ ST->name+":\n";
	s += "\tleave\n";
	s += "\tret\n";
	return s;
}

/* Each label is a struct of label name and the index of the quad that it is present in*/
typedef struct LABEL
{
	string lab;
	int index;
}label;

//class that enabales setting and printing label
class labelSet
{
public:
	vector<label> labels;

	void addlabel(label l)
	{
		labels.push_back(l);
	}

	string getlabel(int s)
	{
		for(int i = 0; i < labels.size(); i++)
		{

			if( (labels.at(i)).index == s) return (labels.at(i)).lab;
		}
		return "nothtere";
	}

	void printlabel()
	{
		for(int i = 0; i < labels.size(); i++)
		{

			cout << ((labels.at(i)).index) << " " << ((labels.at(i)).lab) << endl;
		}
	}

};

labelSet ls;

// Utility function that checks if an argument of the quad is a constant
bool checkconst(string s)
{
	if(s.at(0) == '+' ||  s.at(0) == '-' || s.at(0) == '0' || s.at(0) == '1' || s.at(0) == '2' || s.at(0) == '3' || s.at(0) == '4' || s.at(0) == '5' ||
	s.at(0) == '6' || s.at(0) == '7' || s.at(0) == '8' || s.at(0) == '9') return true;
	else return false;
}



bool searchstring(string s)
{
	for(int i = 0; i < s.size();i++)
	{
		if(s.at(i) == '.') return true;
	}
	return false;
}

bool checkdouble(string s)
{
	if(s.at(0) == '+' ||  s.at(0) == '-' || s.at(0) == '0' || s.at(0) == '1' || s.at(0) == '2' || s.at(0) == '3' || s.at(0) == '4' || s.at(0) == '5' ||
	s.at(0) == '6' || s.at(0) == '7' || s.at(0) == '8' || s.at(0) == '9') 
	{
		if(searchstring(s) == true) 
		{
			return true;
		}
	}
	return false;
}

// Function to make labels in the quad array
void makeLabels()
{
	int n = 0;
	label l;

	for(int i=0; i< quadArr.arr.size(); i++)
	{
		if( (quadArr.arr.at(i)) -> op == IFGOTO ||
			(quadArr.arr.at(i)) -> op == IFFalseGOTO || 
			(quadArr.arr.at(i)) -> op == OP_GOTO ||			 
			(quadArr.arr.at(i)) -> op == OP_IFLessGOTO ||
			(quadArr.arr.at(i)) -> op == OP_IFGrtGOTO ||
			(quadArr.arr.at(i)) -> op == OP_IFLessEqGOTO ||
			(quadArr.arr.at(i)) -> op == OP_IFGrtEqGOTO ||
			(quadArr.arr.at(i)) -> op == OP_IFLogEqGOTO ||
			(quadArr.arr.at(i)) -> op == OP_IFNotEqGOTO)

			{
				string str = (quadArr.arr.at(i)) -> result;
				char * cstr = new char [str.length()+1];
  				strcpy (cstr, str.c_str());
				l.index = atoi(cstr);
				l.lab = ".L" + conv2string(n);
				ls.addlabel(l);
				n++;
			}
			
	}
}

/*
	Activation Record

	- return value : offset 0
	- parameters    : offset starts from 4
	- temporary variables : starts at an offset after parameters

*/
void ASM()
{
	string buff;

	
	string s = makeConstants();
	//cout << "here I am " << s << endl;
	makeLabels();
	cout << s;

	symbolTable* curr = global_symbol_table;
	int param_size = 0;
	bool checking = false;
	int paramcount = 0;
	int strindex = 0;
	vector<int> par;



	for(int i=0; i < quadArr.arr.size(); i++)
	{
		buff = "";
		int check = 0;
		for(int j = 0; j < ls.labels.size(); j++)
		{
			if((ls.labels.at(j)).index ==  i) 
			{
				check++;
				buff +=  (ls.labels.at(j)).lab+":\n";
				break;
			}
		}

		/* 

		Register Allocations & Assignment : Create memory binding for variables in registers:
		– After a load / store the variable on the activation record and the register have identical values
		– Registers can be used to store temporary computed values
		– Register allocations are often used to pass parameters
		– Register allocations are often used to return values

		*/
		switch((quadArr.arr.at(i)) -> op)
		{
			case OP_add:
				if( (curr-> getType((quadArr.arr.at(i)) -> arg1)).bt == double_type)
				buff += "\tmovsd -"+ conv2string( curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %xmm0\n";
				else	
				buff += "\tmovl -"+ conv2string( curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";

				if(checkconst((quadArr.arr.at(i)) -> arg2)) 
				{
					if(checkdouble((quadArr.arr.at(i)) -> arg2))
					{
						int x = getIndexDouble(conv2double((quadArr.arr.at(i)) -> arg2));
						buff += "\tmovsd .LC" + conv2string(x) + "(%rip), %xmm0\n";
						buff += "\t addsd  %xmm1 , %xmm0\n";
						//buff += "\t"
					}
					else buff += "\taddl $"+ (quadArr.arr.at(i)) -> arg2 + ", %eax\n";
				}

				else
				{
					if( (curr-> getType((quadArr.arr.at(i)) -> arg2)).bt == double_type) 
					buff += "\taddsd -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp), %xmm0\n";
					
					else
					buff += "\taddl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp), %eax\n";	
				} 

				if( (curr-> getType((quadArr.arr.at(i)) -> arg1)).bt == double_type)
					buff += "\tmovsd %xmm0, -"+ conv2string(curr -> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				else
					buff += "\tmovl %eax, -"+ conv2string(curr -> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				break;

			case OP_sub:
				if( (curr-> getType((quadArr.arr.at(i)) -> arg1)).bt == double_type)
				buff += "\tmovsd -"+ conv2string( curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %xmm0\n";
				else	
				buff += "\tmovl -"+ conv2string( curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";

				if(checkconst((quadArr.arr.at(i)) -> arg2)) 
				{
					if(checkdouble((quadArr.arr.at(i)) -> arg2))
					{
						int x = getIndexDouble(conv2double((quadArr.arr.at(i)) -> arg2));
						buff += "\tmovsd .LC" + conv2string(x) + "(%rip), %xmm0\n";
						buff += "\t subsd  %xmm1 , %xmm0\n";
						//buff += "\t"
					}
					else buff += "\tsubl $"+ (quadArr.arr.at(i)) -> arg2 + ", %eax\n";
				}

				else
				{
					if( (curr-> getType((quadArr.arr.at(i)) -> arg2)).bt == double_type) 
					buff += "\tsubsd -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp), %xmm0\n";
					
					else
					buff += "\tsubl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp), %eax\n";	
				} 

				if( (curr-> getType((quadArr.arr.at(i)) -> arg1)).bt == double_type)
					buff += "\tmovsd %xmm0, -"+ conv2string(curr -> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				else
					buff += "\tmovl %eax, -"+ conv2string(curr -> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				break;

			case OP_mul:
				if( (curr-> getType((quadArr.arr.at(i)) -> arg1)).bt == double_type)
				buff += "\tmovsd -"+ conv2string( curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %xmm0\n";
				else	
				buff += "\tmovl -"+ conv2string( curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";

				if(checkconst((quadArr.arr.at(i)) -> arg2)) 
				{
					if(checkdouble((quadArr.arr.at(i)) -> arg2))
					{
						int x = getIndexDouble(conv2double((quadArr.arr.at(i)) -> arg2));
						buff += "\tmovsd .LC" + conv2string(x) + "(%rip), %xmm0\n";
						buff += "\t mulsd  %xmm1 , %xmm0\n";
						//buff += "\t"
					}
					else buff += "\timull $"+ (quadArr.arr.at(i)) -> arg2 + ", %eax\n";
				}

				else
				{
					if( (curr-> getType((quadArr.arr.at(i)) -> arg2)).bt == double_type) 
					buff += "\tmulsd -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp), %xmm0\n";
					
					else
					buff += "\timull -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp), %eax\n";	
				} 

				if( (curr-> getType((quadArr.arr.at(i)) -> arg1)).bt == double_type)
					buff += "\tmovsd %xmm0, -"+ conv2string(curr -> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				else
					buff += "\tmovl %eax, -"+ conv2string(curr -> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				break;

			case OP_div:
				buff += "\tmovl -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1))+"(%rbp), %eax\n";
				buff += "\tcltd\n";
				if(checkconst((quadArr.arr.at(i)) -> arg2)) buff += "\tidivl $"+ (quadArr.arr.at(i)) -> arg2 +"\n";
				else buff += "\tidivl -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2)) +"(%rbp)\n";
				buff += "\tmovl %eax, -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result)) +"(%rbp)\n";
				break;

			case OP_mod:
				buff += "\tmovl -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1))+"(%rbp), %eax\n";
				buff += "\tcltd\n";
				if(checkconst((quadArr.arr.at(i)) -> arg2)) buff += "\tidivl $"+ (quadArr.arr.at(i)) -> arg2 +"\n";
				else buff += "\tidivl -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp)\n";
				buff += "\tmovl %edx, -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				break;

			case OP_uminus:
				buff += "\tmovl -"+ conv2string( curr-> getOffset((quadArr.arr.at(i)) -> arg1))+"(%rbp), %eax\n";
				buff += "\tnegl %eax\n";
				buff += "\tmovl %eax, -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				break;

			case OP_GOTO:
				buff += "\tjmp "+ ls.getlabel(conv2int( (quadArr.arr.at(i)) -> result))+"\n";
				break;

			case IFGOTO:
				buff += "\tcmpl $0, -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp)\n";
				buff += "\tjne "+ ls.getlabel(conv2int((quadArr.arr.at(i)) -> result)) + "\n";
				break;

			case IFFalseGOTO:
				buff += "\tcmpl $0, -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp)\n";
				buff += "\tje "+ ls.getlabel(conv2int((quadArr.arr.at(i)) -> result)) +"\n";
				break;

			case OP_IFLessGOTO:
				buff += "\tmovl -" + conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";
				buff += "\tcmpl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2)) +"(%rbp), %eax\n";
				buff += "\tjl "+ ls.getlabel(conv2int((quadArr.arr.at(i)) -> result)) +"\n";
				break;

			case OP_IFGrtGOTO:
				buff += "\tmovl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";
				buff += "\tcmpl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2)) +"(%rbp), %eax\n";
				buff += "\tjg "+ ls.getlabel(conv2int((quadArr.arr.at(i)) -> result)) +"\n";
				break;

			case OP_IFLessEqGOTO:
				buff += "\tmovl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";
				buff += "\tcmpl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2)) +"(%rbp), %eax\n";
				buff += "\tjle "+ ls.getlabel(conv2int((quadArr.arr.at(i)) -> result)) +"\n";
				break;

			case OP_IFGrtEqGOTO:
				buff += "\tmovl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";
				buff += "\tcmpl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2)) +"(%rbp), %eax\n";
				buff += "\tjge "+ ls.getlabel(conv2int((quadArr.arr.at(i)) -> result)) +"\n";
				break;

			case OP_IFLogEqGOTO:
				buff += "\tmovl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";
				buff += "\tcmpl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2)) +"(%rbp), %eax\n";
				buff += "\tje "+ ls.getlabel(conv2int((quadArr.arr.at(i)) -> result))+"\n";
				break;

			case OP_IFNotEqGOTO:
				buff += "\tmovl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";
				buff += "\tcmpl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2)) +"(%rbp), %eax\n";
				buff += "\tjne "+ ls.getlabel(conv2int((quadArr.arr.at(i)) -> result)) +"\n";
				break;

			case OP_eq:
				if(checkconst((quadArr.arr.at(i)) -> arg1))
				{

					if(checkdouble((quadArr.arr.at(i)) -> arg1))
					{
						int x = getIndexDouble(conv2double((quadArr.arr.at(i)) -> arg1));
						buff += "\tmovsd .LC" + conv2string(x) + "(%rip), %xmm0\n";
						buff += "\t movsd	%xmm0, -" + conv2string( curr-> getOffset((quadArr.arr.at(i)) -> result)) +"(%rbp)\n";
					}
					/*movsd	.LC0(%rip), %xmm0
						  movsd	%xmm0, -24(%rbp)*/
				   else
				   buff += "\tmovl $"+ (quadArr.arr.at(i)) -> arg1 + ", -" + conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				}
				else
				{
					if( (curr-> getType((quadArr.arr.at(i)) -> arg1)).bt == double_type )
					{
						buff += "\tmovsd -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %xmm0\n";
						buff += "\tmovsd %xmm0, -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result)) +"(%rbp)\n";
					}

					else
					{
						buff += "\tmovl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";
						buff += "\tmovl %eax, -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result)) +"(%rbp)\n";
					}
				}
				break;


			case OP_par:
				if(paramcount == 0)
				{
					if( checkconst( (quadArr.arr.at(i)) -> result) ) 
					{
						if(checkdouble( (quadArr.arr.at(i)) -> result))
						{
							int x = getIndexDouble(conv2double((quadArr.arr.at(i)) -> arg1));
							buff += "\tmovsd .LC" + conv2string(x) + "(%rip), %xmm0\n";
						}
						else
						{
							par.push_back(conv2int((quadArr.arr.at(i)) -> result));
							buff += "\tmovq "+ (quadArr.arr.at(i)) -> result +", %rdi\n";
					    }
					}
					else 
					{

						par.push_back( (curr -> lookup((quadArr.arr.at(i)) -> result) -> initial).int_initial);
						//cout << "qwerty " << (curr -> lookup((quadArr.arr.at(i)) -> result)) -> name << "qwerty" << par.at(par.size() - 1) << endl;

						if( (curr -> getType((quadArr.arr.at(i)) -> result)).bt == double_type)
						buff += "\tmovsd -"+conv2string( curr -> getOffset((quadArr.arr.at(i)) -> result) )+"(%rbp), %xmm0\n";
						else
						buff += "\tmovq -"+conv2string( curr -> getOffset((quadArr.arr.at(i)) -> result) )+"(%rbp), %rdi\n";
					}
					paramcount++;
					
				}

				else if(paramcount == 1)
				{
					if( checkconst( (quadArr.arr.at(i)) -> result) ) buff += "\tmovq "+ (quadArr.arr.at(i)) -> result +", %rsi\n";
					else buff += "\tmovq -"+conv2string( curr -> getOffset((quadArr.arr.at(i)) -> result) )+"(%rbp), %rsi\n";
					paramcount++;
				}

				else if(paramcount == 2)
				{
					if( checkconst( (quadArr.arr.at(i)) -> result) ) buff += "\tmovq "+ (quadArr.arr.at(i)) -> result +", %rdx\n";
					else buff += "\tmovq -"+conv2string( curr -> getOffset((quadArr.arr.at(i)) -> result) )+"(%rbp), %rdx\n";
					paramcount++;
				}

				else if(paramcount == 3)
				{
					if( checkconst( (quadArr.arr.at(i)) -> result) ) buff += "\tmovq "+ (quadArr.arr.at(i)) -> result +", %rcx\n";
					else buff += "\tmovq -"+conv2string( curr -> getOffset((quadArr.arr.at(i)) -> result) )+"(%rbp), %rcx\n";
					paramcount++;
				}

				else if(paramcount == 4)
				{
					if( checkconst( (quadArr.arr.at(i)) -> result) ) buff += "\tmovq "+ (quadArr.arr.at(i)) -> result +", %r8\n";
					else buff += "\tmovq -"+conv2string( curr -> getOffset((quadArr.arr.at(i)) -> result) )+"(%rbp), %r8\n";
					paramcount++;
				}

				else if(paramcount == 5)
				{
					if( checkconst( (quadArr.arr.at(i)) -> result) ) buff += "\tmovq "+ (quadArr.arr.at(i)) -> result +", %r9\n";
					else buff += "\tmovq -"+conv2string( curr -> getOffset((quadArr.arr.at(i)) -> result) )+"(%rbp), %r9\n";
					paramcount++;
				}
				
				param_size += 4;
				break;

			case OP_call:
				if(((quadArr.arr.at(i)) -> arg1).compare("printStr") == 0) 
				{
					buff += "\tmovl $.s" + conv2string(strindex) + ", %edi\n";
					buff += "\tcall printStr\n";
					strindex ++;
				}

				else if(((quadArr.arr.at(i)) -> arg1).compare("printDbl") == 0) 
				{
					
					buff += "\tcall printDbl\n";
					
				}

				else
				{
					buff += "\tcall "+ (quadArr.arr.at(i)) -> arg1 +"\n";
					buff += "\tmovl %eax, -"+ conv2string( curr -> getOffset((quadArr.arr.at(i)) -> result) ) +"(%rbp)\n";
					buff += "\taddq $"+ conv2string(param_size)+", %rsp\n";
					param_size = 0;
				}
				paramcount = 0;
				break;

			case OP_LAB:
				if(checking == true) buff+= Epilogue(curr);
				curr = global_symbol_table -> lookup((quadArr.arr.at(i)) -> result) -> nested;
				paramcount = 0;
				buff += Prologue(curr);
				checking = true;
				break;

			case OP_eqmat:
				//t=rs
				//q -> result <<" = "<< q -> arg1 <<"["<< q -> arg2 << "]" <<endl;
			    //cout << "hereeeedude" <<endl;
				buff += "\tmovq $-"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1))+", %rax\n";
				if( checkconst( (quadArr.arr.at(i)) -> arg1) )
					buff += "\tsubq -$"+ (quadArr.arr.at(i)) -> arg2 +", %rax\n";
				else
				 	buff += "\tsubq -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp), %rax\n";
				
				buff += "\taddq %rax, %rbp\n";
				buff += "\tmovss 0(%rbp), %xmm0\n";

				buff += "\tmovss %xmm0, -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result))+"(%rbp)\n";
				break;

			case OP_mateq:
				//q -> result <<"["<< q -> arg1 <<"]"<<" = "<< q -> arg2
				//cout << "hereeee" <<endl;
				buff += "\tmovq $-"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result))+", %rax\n";
				if( checkconst( (quadArr.arr.at(i)) -> arg1) ) 
					buff += "\tsubq $"+ (quadArr.arr.at(i)) -> arg1 +", %rax\n";
				else
					buff += "\tsubq "+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1))+", %rax\n";

				buff += "\tmovss -"+conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2))+"(%rbp), %xmm0\n";
				buff += "\taddq %rax, %rbp\n";
				buff += "\tmovss %xmm0, 0(%rbp)\n";
				break;

			case OP_addr:
				buff += "\tleal -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) + "(%rbp), %eax\n";
				buff += "\tmovl %eax, -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result)) +"(%rbp)\n";
				break;

			// case EQPVAL:
			// 	buff += "\tmovl "+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg1)) +"(%rbp), %eax\n";
			// 	buff += "\tmovl 0(%eax), %rbx\n";
			// 	buff += "\tmovl %rbx, "+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> arg2)) +"(%rbp)\n";
			// 	break;			

			// case PVALEQ:
			// 	buff += "\tmovl "+conv2string(curr->getoffset(quads[i].t))+"(%rbp), %eax\n";
			// 	buff += "\tmovl "+conv2string(curr->getoffset(quads[i].r))+"(%rbp), %rbx\n";
			// 	buff += "\tmovl %rbx, 0(%eax)\n";
			// 	break;	

			case OP_ret:
				if((quadArr.arr.at(i)) -> result != "") buff += "\tmovl -"+ conv2string(curr-> getOffset((quadArr.arr.at(i)) -> result)) +"(%rbp), %eax\n";
				buff += "\tjmp .ret_"+curr -> name+"\n";
				break;
		}

		cout << buff;
		
	}

	cout << Epilogue(curr);
}

int yyparse();

int main()
{
	
	Stables.push(global_symbol_table);

	type typee;
	typee.bt = function_type;
	typee.size = 0;
	typee.actual_type = NULL;
	symbol_entry * temp = new symbol_entry("printInt", typee);
	temp -> nested = new symbolTable("printInt");
	typee.bt = int_type;
	typee.size = 4;
	typee.actual_type = NULL;
	temp -> nested -> lookup(new symbol_entry("val", typee));
	temp -> nested -> f = new function();
	(temp -> nested -> f) -> typelist.push_back(typee);
	(temp -> nested ->f) -> returntype = typee;
	global_symbol_table -> lookup(temp);


	typee.bt = function_type;
	typee.size = 0;
	typee.actual_type = NULL;
	symbol_entry * tempp = new symbol_entry("readInt", typee);
	tempp -> nested = new symbolTable("readInt");
	typee.bt = int_type;
	typee.size = 4;
	typee.actual_type = NULL;
	type typee11;
	typee11.bt = pointer_type;
	typee11.size = 4;
	typee11.actual_type = &typee;
	tempp -> nested -> lookup(new symbol_entry("val", typee11));
	tempp -> nested -> f = new function();
	(tempp -> nested -> f) -> typelist.push_back(typee11);
	(tempp -> nested ->f) -> returntype = typee;
	global_symbol_table -> lookup(tempp);

	
	typee.bt = function_type;
	typee.size = 0;
	typee.actual_type = NULL;
	symbol_entry * temp2 = new symbol_entry("printStr", typee);
	temp2 -> nested = new symbolTable("printStr");
	typee.bt = string_type;
	typee.size = 20;
	typee.actual_type = NULL;
	type typee1;
	typee1.bt = int_type;
	typee1.size = 4;
	typee1.actual_type = NULL;
	temp2 -> nested -> lookup(new symbol_entry("str", typee));
	temp2 -> nested -> f = new function();
	(temp2 -> nested -> f) -> typelist.push_back(typee);
	(temp2 -> nested ->f) -> returntype = typee1;
	global_symbol_table -> lookup(temp2);

	typee.bt = function_type;
	typee.size = 0;
	typee.actual_type = NULL;
	symbol_entry * temp3 = new symbol_entry("printDbl", typee);
	temp3 -> nested = new symbolTable("printDbl");
	typee.bt = double_type;
	typee.size = 8;
	typee.actual_type = NULL;
	typee1.bt = int_type;
	typee1.size = 4;
	typee1.actual_type = NULL;
	temp3 -> nested -> lookup(new symbol_entry("dbl", typee));
	temp3 -> nested -> f = new function();
	(temp3 -> nested -> f) -> typelist.push_back(typee);
	(temp3 -> nested ->f) -> returntype = typee1;
	global_symbol_table -> lookup(temp3);

	while(1){
		yyparse();
	}

	
	return 0;
}