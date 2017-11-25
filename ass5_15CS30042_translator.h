#ifndef __TRANSLATOR_H
#define __TRANSLATOR_H

#include <string>
#include <vector>
#include <sstream>
#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <stack>

using namespace std;

#define SIZE_INT 4
#define SIZE_CHAR 1
#define SIZE_PTR 4
#define SIZE_DOUBLE 8

class symbolTable;
class list;
class symbol_entry;
class func_utility;


//enum to stoe all the possible basic types
typedef enum BASIC_TYPE
{
	int_type,
	double_type,
	void_type,
	char_type,
	matrix_type,
	bool_type,
	function_type,
	pointer_type,
	string_type
}basic_type;

//enum to store all the possible optyes
typedef enum OPCODETYPE
{
	OP_leftsqr, OP_rightsqr, OP_leftnorm, OP_rightnorm, OP_leftcurl, OP_rightcurl,
	OP_dot, OP_pointer, OP_incr, OP_decr, 
	OP_add , OP_mul, OP_sub, OP_div, 
	OP_transpose,OP_uminus,
	OP_mod,
	OP_shl, OP_shr,
	IFGOTO, IFFalseGOTO,
	OP_gt, OP_lt, OP_gte, OP_lte,OP_logeq,OP_neq,
	OP_bitxor, OP_bitor,OP_bitand,
	OP_or, OP_and, OP_qn, OP_colon, OP_semicolon, OP_eq,OP_hash,
	null_op,OP_mateq,OP_eqmat,OP_addr,
	OP_IFLessGOTO, OP_IFGrtGOTO, OP_IFLessEqGOTO, OP_IFGrtEqGOTO, OP_IFLogEqGOTO, OP_IFNotEqGOTO,
	OP_call, OP_GOTO, OP_par,OP_LAB,OP_IFFalseGOTO,
	OP_ret,Int2Double, Double2Int, Char2Int, Int2Char,OP_inmat

}opcodeType;

//useful to store initial value of matrix_type 
//since a string type is not allowed in union
typedef struct NAME
{
	char* names;
	int d;
}strmat;

//struct that defines a type .
//Actual type stores base type in case of a pointer and null otherwise
typedef struct TYPE
{
	basic_type bt;
	int size;
	struct TYPE * actual_type;
	struct TYPE getbasetype();
}type;

//union of initial values
union initial_value
{
	int int_initial;
	double double_initial;
	char char_initial;
	strmat name;
};


//class list that is useful for backpatching
class list
{
public:
	//list of vectors
	vector<int> l;
	list();
	list(int index);

	void clear();
};

//class matrix that stores the dimensions and entries
class matrix
{
public:
	double dim1,dim2;
	vector<double> entries;
	int size();
};

class symbol_entry
{
public:
	string name;

	type entry_type;

	initial_value initial;
	//flag to store if it is a matrix
	bool is_matrix;

	matrix* m;
	bool is_initialized;
	int size;

	int offset;

	//useful in case of matrices
	string matoffset;

	symbolTable * nested;

	list truelist;

	list falselist;

	void print();
	void createnest();

	symbol_entry(string name);
	symbol_entry(type entry_type);
	symbol_entry(string name, type entry_type);
	symbol_entry(string name, type entry_type, initial_value initial);

};


//class to store nextlists
class nextlist
{
public:
	list l;
};

list makelist(int index);
list merge(list&, list&);
void backpatch(list& , int);

//Type conversions
void convBool2Int(symbol_entry *);
void convInt2Bool(symbol_entry *);
void convChar2Int(symbol_entry *);
void convDouble2Int(symbol_entry *);
void typecheck(symbol_entry *,symbol_entry *);

//a class that is useful for functions to store parameters and call functions
class func_utility
{
public:
	vector<symbol_entry*> l;
	string s;
	type rett;
	void method(symbol_entry* &);
};

//stores details of function, parameters and return type
class function
{
public:
	vector<type> typelist;
	type returntype;
};

//Symbol table can store many symbols
class symbolTable
{
public:
	string name;
	int index;
	int offset;
	function * f;

	vector<symbol_entry *> entries;

	symbol_entry * lookup(string name);
	symbol_entry * lookup(string name,type t);
	symbol_entry * lookup(symbol_entry*);

	symbolTable(string s);
	symbolTable();


	void print();

	symbol_entry * gentemp(type);

	symbol_entry * update(symbol_entry * s, string name , type entry_type , initial_value initial, int size, int offset);

	void updatesizes();
	void ComputeOffset();
	int getOffset(string s);
    type getType(string s);

};

//stack of symbol tables
extern stack<symbolTable*> Stables;

//maintains count of temporary
extern int t_count;

//class for each quad entry
class quad_entry
{
public:

	//operation code type
	opcodeType op ;
	//arg1 , arg2, result of each quad
	string arg1 , arg2, result ;
	
	quad_entry(opcodeType,string,string,string);
	quad_entry(opcodeType,string,string);
	quad_entry(opcodeType,string);

};

//class for quad array
class quad_array
{
public:
	//vector of quad entry types
	vector<quad_entry *> arr;
	void emit(opcodeType, string, string, string);
	void emit(opcodeType, string, string);
	void emit(opcodeType, string);

	void print();
};

//quad array to store all quads
extern quad_array quadArr;

//unique global symbol table
extern symbolTable* global_symbol_table;
extern vector<string> StringSet;
extern vector<double> doubleSet;
extern ofstream outfile;

symbol_entry * update(symbol_entry* , type t);
symbol_entry * updatet(symbol_entry* a, type t);
symbol_entry * updatein(symbol_entry* a, int t);

//Utitlity functions
int currAddr();
string conv2string(int v);
string conv2string(double v);
int conv2int(string s);
double conv2double(string s);

void ASM();
void printstr();
void printdbl();
#endif
