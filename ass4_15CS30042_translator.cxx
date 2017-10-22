
#include <string>
#include <vector>
#include <sstream>
#include <iostream>
#include <fstream>
#include <stack>
#include <stdlib.h>
#include <cstring>

using namespace std;
#include "ass4_15CS30042_translator.h"

stack<symbolTable*> Stables;
quad_array quadArr;
int t_count = 0;

/////////////////Utility functions/////////////////////////////
//converts int to string
string conv2string(int v)
{
	stringstream sbuff;
	sbuff<<v;
	return sbuff.str();
}


//converts double to string
string conv2string(double v)
{
	stringstream sbuff;
	sbuff<<v;
	return sbuff.str();
}

//converts int to string
int conv2int(string s)
{
	return atoi(s.c_str());
}

//if the type is a pointer type, this method returns the base type and null otherwise
type type::getbasetype()
{
	type* ty = actual_type;
	if(actual_type == NULL) return *this;
	while(ty -> actual_type != NULL)
	{
		ty = actual_type;
	}
	return *ty;
}

void func_utility::method(symbol_entry* &s)
{
	
	symbolTable* temp = s -> nested;

	int i = 0;
	/*while(i < l.size())
	{
		update(l.at(i), (temp->f)->typelist.at(i));
		i++;
	}*/

	

	i = l.size() -1;
	while(i>=0)
	{
		quadArr.emit(OP_par,(l.at(i)) -> name);
		i--;
	}

	
	//cout <<"yeah"<<endl;
	//cout << (temp -> f->returntype).size << endl;
	//symbol_entry* t1 = new symbol_entry(temp->f->returntype);
	//cout <<"yes"<<endl;
	//quadArr.emit(OP_call, s -> name,conv2string((int)l.size()),t1-> name);
	//s = t1;
}

//function to calculate size of a matrix

int matrix::size()
{
	return 8*(entries.size() + 1);
}


/////////////////methods for entry of symbol table/////////////////////////////

//constructor
symbol_entry::symbol_entry(type entry_type)
{
	this -> name = "";

	this -> entry_type = entry_type;

	this -> is_initialized = false;
	this -> is_matrix = false;

	(this -> matoffset).assign("");


	this -> size = entry_type.size;

	symbolTable * nested = NULL;
}
//constructor
symbol_entry::symbol_entry(string name)
{
	(this -> name).assign(name);

	this -> is_initialized = false;
	this -> is_matrix = false;

	(this -> matoffset).assign("");


	this -> size = entry_type.size;

	symbolTable * nested = NULL;
}

//constructor
symbol_entry::symbol_entry(string name, type entry_type)
{
	(this -> name).assign(name);

	this -> entry_type = entry_type;

	this -> is_initialized = false;
	this -> is_matrix = false;

	(this -> matoffset).assign("");


	this -> size = entry_type.size;

	symbolTable * nested = NULL;
}
//constructor
symbol_entry::symbol_entry(string name, type entry_type, initial_value initial)
{
	(this -> name).assign(name);

	this -> entry_type = entry_type;

	//this -> initial = initial;

	this -> is_initialized = true;
	this -> is_matrix = false;

	(this -> matoffset).assign("");

	this -> size = entry_type.size;

	symbolTable * nested = NULL;
}
//method to create a nested symbol table
void symbol_entry::createnest()
{
	nested = new symbolTable(name);
	nested-> f = new function();
}

//method to print each entry of symbol table
void symbol_entry::print()
{
	cout << name << "\t\t\t\t\t\t";

	if(entry_type.bt == int_type) cout << "int\t\t\t\t\t";
	if(entry_type.bt == double_type) cout << "double\t\t\t\t";
	if(entry_type.bt == void_type) cout << "void\t\t\t\t";
	if(entry_type.bt == char_type) cout << "char\t\t\t\t";
	if(entry_type.bt == matrix_type) cout << "matrix\t\t\t\t";
	if(entry_type.bt == bool_type) cout << "bool\t\t\t\t\t";
	if(entry_type.bt == function_type) cout << "function\t\t\t";
	if(entry_type.bt == pointer_type) cout << "pointer\t\t\t\t";

	if(is_initialized)
	{

		if(entry_type.bt == int_type) cout << initial.int_initial << "\t\t\t\t\t";
		else if(entry_type.bt == double_type) cout << initial.double_initial << "\t\t\t\t\t";
		else if(entry_type.bt == char_type) cout << initial.char_initial << "\t\t\t\t\t";
		else if(entry_type.bt == matrix_type)
		{
			string str(initial.name.names,initial.name.d - 1);
			cout << str << "\t\t";
		} 
		else cout << "null\t\t\t\t";
	}
	else cout << "null\t\t\t\t";

	cout << size << "\t\t\t\t\t\t";

	cout << offset << "\t\t\t\t\t\t";

	if(nested != NULL) cout << nested -> name;
	else cout << "null";

	cout <<endl;

}
	
/////////////////////////methods for symbol table/////////////////////////////
//constructor
symbolTable::symbolTable() {
    offset = 0;
    f = new function();
}
//constructor
symbolTable::symbolTable(string s) {
    name = s;
    offset = 0;
    f = new function();

}

// Look up that returns a table entry if present otherwise creates a new one
symbol_entry * symbolTable::lookup(string name, type t)
{
	for(int i = 0; i < entries.size(); i++)
	{
		if( entries.at(i) -> name.compare(name) == 0)
		{
			return entries.at(i);
		}
	}
	symbol_entry * s = new symbol_entry(name,t);
	s -> offset = this -> offset;
	entries.push_back(s);
	this -> offset += t.size;
	return s;
}

// Look up that returns a table entry if present otherwise creates a new one
symbol_entry * symbolTable::lookup(string name)
{
	for(int i = 0; i < entries.size(); i++)
	{
		if( entries.at(i) -> name.compare(name) == 0)
		{
			return entries.at(i);
		}
	}
	symbol_entry * s = new symbol_entry(name);
	s -> offset = this -> offset;
	entries.push_back(s);
	this -> offset += 0;
	return s;
}

// Look up that returns a table entry if present otherwise creates a new one
symbol_entry * symbolTable::lookup(symbol_entry* s)
{
	for(int i = 0; i < entries.size(); i++)
	{
		if( entries.at(i) -> name.compare(s -> name) == 0)
		{
			return entries.at(i);
		}
	}
	s -> offset = this -> offset;
	this -> entries.push_back(s);
	this -> offset += s -> size;
	return s;
}

// gentype to genrate a new temporary of a specific type
symbol_entry * symbolTable::gentemp(type t)
{
	stringstream buffer;
	buffer << "t" << t_count;
	t_count ++;
	return lookup(buffer.str() , t);

}

//prints the symbol table ina proper format
void symbolTable::print()
{
	cout << "==========" << name << "==========" <<endl;
	for(int i=0; i < entries.size(); i++)
	{
		entries.at(i) -> print();

	}

	for(int i=0; i < entries.size(); i++)
	{
		if(entries.at(i) -> nested != NULL) 
		{
			//if((entries.at(i) -> nested -> name).at(0) != 't')
			entries.at(i) -> nested -> print();
		}
	}

}



////////////////////////////////methods for each entry of quad array////////////////////////////////////
//constructor
quad_entry::quad_entry(opcodeType op,string arg1,string arg2,string result)
{
	(this -> arg1).assign(arg1);
	(this -> arg2).assign(arg2);
	(this -> result).assign(result);
	this -> op = op;

}
//constructor
quad_entry::quad_entry(opcodeType op,string arg1,string result)
{
	(this -> arg1).assign(arg1);
	(this -> arg2).assign("");
	(this -> result).assign(result);
	this -> op = op;

}
//constructor
quad_entry::quad_entry(opcodeType op,string result)
{
	(this -> arg1).assign("");
	(this -> arg2).assign("");
	(this -> result).assign(result);
	this -> op = op;
}

//adds a quad to quad array
void quad_array::emit(opcodeType op,string arg1,string arg2,string result)
{
	quad_entry* q = new quad_entry(op,arg1,arg2,result);
	quadArr.arr.push_back(q);
}
//adds a quad to quad array
void quad_array::emit(opcodeType op,string arg1,string result)
{
	quad_entry* q = new quad_entry(op,arg1,result);
	quadArr.arr.push_back(q);
}
//adds a quad to quad array
void quad_array::emit(opcodeType op,string result)
{
	quad_entry* q = new quad_entry(op,result);
	quadArr.arr.push_back(q);
}

//method to print quad array in proper format
void quad_array::print()
{
	quad_entry * q;
	for(int i = 0; i < arr.size(); i++)
	{
		q = arr.at(i);
		opcodeType op = q -> op;
		if(op == OP_add) cout << i << "\t\t\t" << q -> result <<" = "<< q->arg1<<" + "<< q -> arg2 << endl;
		else if(op == OP_sub) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" - "<< q -> arg2 << endl;
		else if(op == OP_mul) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" * "<< q -> arg2 << endl;
		else if(op == OP_div) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" / "<< q -> arg2 << endl;
		else if(op == OP_mod) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" % "<< q -> arg2 << endl;
		else if(op == OP_shl) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" << "<< q -> arg2 << endl;
		else if(op == OP_shr) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" >> "<< q -> arg2 << endl;
		else if(op == OP_lt) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" < "<< q -> arg2 << endl;
		else if(op == OP_lte) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" <= "<< q -> arg2 << endl;
		else if(op == OP_gt) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" > "<< q -> arg2 << endl;
		else if(op == OP_gte) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" >= "<< q -> arg2 << endl;
		else if(op == OP_and) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" && "<< q -> arg2 << endl;
		else if(op == OP_or) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" || "<< q -> arg2 << endl;
		else if(op == OP_logeq) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" == "<< q -> arg2 << endl;
		else if(op == OP_neq) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" != "<< q -> arg2 << endl;
		else if(op == OP_bitxor) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" ^ "<< q -> arg2 << endl;
		else if(op == OP_bitand) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" & "<< q -> arg2 << endl;
		else if(op == OP_bitor) cout << i << "\t\t\t" << q -> result <<" = "<<q -> arg1<<" | "<< q -> arg2 << endl;
		else if(op == OP_uminus) cout << i << "\t\t\t" << q -> result <<" =  - "<< q -> arg1 << endl;
		else if(op == Int2Double) cout << i << "\t\t\t"<<q -> result<<" = Int2Double "<<q -> arg1<<endl;
		else if(op == Double2Int) cout << i << "\t\t\t"<<q -> result<<" = Double2Int "<<q -> arg1<<endl;
		else if(op == Char2Int) cout << i << "\t\t\t"<<q -> result<<" = char2Int "<<q -> arg1<<endl;
		else if(op == Int2Char) cout << i << "\t\t\t"<<q -> result<<" = Int2Char "<<q -> arg1<<endl;
		else if(op == OP_eq) cout << i << "\t\t\t"<<q -> result <<" = "<< q -> arg1 <<endl;
		else if(op == OP_IFFalseGOTO) cout << i << "\t\t\t"<< "IFFALSE "<< q -> arg1<<" GOTO "<< q -> result <<endl;
		else if(op == OP_IFLessGOTO) cout << i << "\t\t\t"<<"IF "<< q -> arg1 <<" < "<< q -> arg2 <<" GOTO "<< q -> result <<endl;
		else if(op == OP_IFGrtGOTO) cout << i << "\t\t\t"<<"IF "<< q -> arg1 <<" > "<< q -> arg2 <<" GOTO "<< q -> result <<endl;
		else if(op == OP_IFLessEqGOTO) cout << i << "\t\t\t"<<"IF "<< q -> arg1 <<" <= "<< q -> arg2 <<" GOTO "<< q -> result <<endl;
		else if(op == OP_IFGrtEqGOTO) cout << i << "\t\t\t"<<"IF "<< q -> arg1 <<" >= "<< q -> arg2 <<" GOTO "<< q -> result <<endl;
		else if(op == OP_IFNotEqGOTO) cout << i << "\t\t\t"<<"IF "<< q -> arg1 <<" != "<< q -> arg2 <<" GOTO "<< q -> result <<endl;
		else if(op == OP_IFLogEqGOTO) cout << i << "\t\t\t"<<"IF "<< q -> arg1 <<" == "<< q -> arg2 <<" GOTO "<< q -> result <<endl;	
		else if(op == OP_call)	cout << i << "\t\t\t" <<q -> result <<" = CALL "<< q -> arg1 <<", "<< q -> arg2 <<endl;
		else if(op == OP_GOTO) cout << i << "\t\t\t"<<"GOTO "<< q -> result <<endl;
		else if(op == OP_par) cout << i << "\t\t\t"<<"PARAM "<< q -> result <<endl;
		else if(op == OP_ret) cout << i << "\t\t\t"<<"RET "<< q -> result <<endl;
		else if(op == OP_mateq) cout << i << "\t\t\t"<< q -> result <<"["<< q -> arg1 <<"]"<<" = "<< q -> arg2 <<endl;
		else if(op == OP_eqmat) cout << i << "\t\t\t" << q -> result <<" = "<< q -> arg1 <<"["<< q -> arg2 << "]" <<endl;
		else if(op == OP_addr) cout << i << "\t\t\t" << q -> result <<" = &"<< q -> arg1 <<endl;
		else if(op == OP_LAB) cout << i << "\t\t\t" << "LABEL " << q -> result <<endl;
		else if(op == OP_transpose) cout << i << "\t\t\t" << q -> result << " = " << q -> arg1 << ".'"<<endl;

	
	}
}


//keeps track of current address, that present quadarray size
int currAddr()
{
	return quadArr.arr.size()-1;
}

////////////////methods for list//////////////////

//constructor
list::list() {}

//constructor
list::list(int index)
{
	l.push_back(index);
} 

//clears the list
void list::clear() {
    l.clear();
}

//A global function to create a new list containing only i, an index into the array of quad’s, and to return a pointer to the newly created list.

list makelist(int index)
{
	list L = list(index);
	return L;
}
//A global function to concatenate two lists pointed to by p1 and p2 and to return a pointer to the concatenated list.

list merge(list& p1 , list& p2)
{
	list newlist = list();
	for(int i = 0; i < (p1.l).size(); i++) (newlist.l).push_back((p1.l)[i]);
	for(int i = 0; i < (p2.l).size(); i++) (newlist.l).push_back((p2.l)[i]);
	return newlist;
}

//A global function to insert i as the target label for each of the quad’s on the list pointed to by p.
void backpatch(list& p , int index)
{
	int update;
	for(int i=0; i<(p.l).size(); i++)
	{
		update = (p.l)[i];
		(quadArr.arr.at(update)) -> result = conv2string(index);
	}
}

///////////////////////methods for type conversions/////////////////////

//method convert from bool to int
void convBool2Int(symbol_entry * a)
{
	if((a -> entry_type).bt != bool_type) return;

	type typee;
	typee.bt = int_type;
	typee.size = 4;
	typee.actual_type = NULL;
	symbol_entry* t1 = Stables.top() -> gentemp(typee);
	quadArr.emit( OP_eq, "1",t1 -> name);
	backpatch(a->truelist, currAddr());
	quadArr.emit(OP_GOTO,"");
	list l = list(currAddr());
	quadArr.emit( OP_eq, "0",t1 -> name);
	backpatch(a -> falselist, currAddr());
	backpatch(l, currAddr()+1);

	a = t1;
}

//method convert from int to bool
void convInt2Bool(symbol_entry * a)
{
	if((a-> entry_type).bt != int_type && (a-> entry_type).actual_type == NULL) return;

	type typee;
	typee.bt = bool_type;
	typee.size = 0;
	typee.actual_type = NULL;
	symbol_entry* t1 = new symbol_entry(typee);
	quadArr.emit(IFFalseGOTO, a->name,"0","");
	t1 -> falselist = makelist(currAddr());
	quadArr.emit(OP_GOTO,"");
	t1 -> truelist = makelist(currAddr());

	a = t1;
}

//method convert from char to int
void convChar2Int(symbol_entry * a)
{
	if((a-> entry_type).bt != char_type) return;

	type typee;
	typee.bt = int_type;
	typee.size = 4;
	typee.actual_type = NULL;
	symbol_entry* t1 = Stables.top() -> gentemp(typee);
	quadArr.emit(Char2Int, a -> name,t1 -> name);

	a = t1;
}

//method convert from int to char
void convInt2Char(symbol_entry * a)
{
	if((a-> entry_type).bt != int_type) return;

	type typee;
	typee.bt = char_type;
	typee.size = 1;
	typee.actual_type = NULL;
	symbol_entry* t1 = Stables.top() -> gentemp(typee);
	quadArr.emit(Int2Char, a -> name,t1 -> name);

	a = t1;
}

//method convert from double to int
void convDouble2Int(symbol_entry * a)
{
	if((a-> entry_type).bt != double_type) return;

	type typee;
	typee.bt = int_type;
	typee.size = 4;
	typee.actual_type = NULL;
	symbol_entry* t1 = Stables.top() -> gentemp(typee);
	quadArr.emit( Double2Int, a -> name,t1 -> name);

	a = t1;
}

//method convert from int to double
void convInt2Double(symbol_entry * a)
{
	if((a-> entry_type).bt != int_type) return;

	type typee;
	typee.bt = double_type;
	typee.size = 8;
	typee.actual_type = NULL;
	symbol_entry* t1 = Stables.top() -> gentemp(typee);
	quadArr.emit(Int2Double, a -> name,t1 -> name);

	a = t1;
}

//checks if a & b are of same type and calls appropriate conversion functions

void typecheck(symbol_entry * a,symbol_entry * b)
{
	basic_type from = (a -> entry_type).bt;
	basic_type to = (b -> entry_type).bt;
	if(from == double_type && to == int_type)
	{
		convDouble2Int(a);
		return;
	}
	else if(to == double_type && from == int_type)
	{
		convInt2Double(a);
		return;
	}
	else if(from == to)
	{
		return;
	}
	else if(from == double_type && to == char_type)
	{
		convDouble2Int(a);
		convInt2Char(a);
		return;
	}
	else if(to == double_type && from == char_type)
	{
		convChar2Int(a);
		convInt2Double(a);
		return;
	}
	
	else if(from == int_type && to == char_type)
	{
		convInt2Char(a);
		return;
	}
	else if(to == int_type && from == char_type)
	{
		convChar2Int(a);
		return;
	}
	
}

//A method to update different fields of an existing entry.

symbol_entry * update(symbol_entry* a, type t)
{
	symbol_entry * b = new symbol_entry(t);
	typecheck(a,b);
	return a;
}

//A method to update different fields of an existing entry.
symbol_entry * updatet(symbol_entry* a, type t)
{
	(a -> entry_type).bt = t.bt; 
	(a -> entry_type).size = t.size; 
	return a;
}

//The unique global symbol table
symbolTable* global_symbol_table = new symbolTable("Global"); 

int yyparse();

int main()
{
	
	Stables.push(global_symbol_table);
	while(1){
		yyparse();
	}
	return 0;
}


