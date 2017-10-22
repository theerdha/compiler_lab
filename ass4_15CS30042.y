%{

#include <iostream>
#include <fstream>
#include <string>
#include <cstring>
#include <vector>
#include "ass4_15CS30042_translator.h"
int yylex();
void yyerror(const char *s);


typedef struct S
{
	string name;
	type type_f;

}func_details;



//Useful for initialization of matrices
vector<double> mat_init;
bool a_matrix;

//offset is useful for matrices
string offset;
bool is_offset;

//holds a symbol of function type
symbol_entry* currfunc;
func_details if_func;

//Holds current type
type t;


%}

/* The union can store 5 different types:
		1. The pointer to the symbol table
		2. The function_unitility stores argument list for function parameters.
			This is required for recursive functions calls in a way
			that the result of one function is passed as a parameter to the second.
		3. Nextlist for control statements.
		4. Address of the current instruction.
		5. none denotes that the type is unused since many production rules have not been used.

		NOTE: 
		
		If some code which requires the unused rules is compiled, it may result in a SEGMENTATION FAULT,
		as the propagation rules for different types are invalid. Some error codes like operations on
		incompatible dimensions are not handled.
*/

%union{
	class symbol_entry* symbol;
	class func_utility* fu;
	class nextlist* nl;
	int address;
	char none;
}

%token<none> UNSIGNED BREAK RETURN VOID CASE FLOAT SHORT CHAR FOR SIGNED WHILE GOTO BOOL CONTINUE IF DEFAULT DO INT SWITCH DOUBLE ELSE LONG MATRIX ACCESS INCR DECR SHLL SHRL LTE GTE EQ NEQ LOGAND LOGOR ASSNMUL ASSNDIV ASSNMOD ASSNADD ASSNSUB ASSNSHLL ASSNSHRL ASSNBINAND ASSNXOR ASSNBINOR TRANSPOSE ADDR

%token<symbol> IDENTIFIER CONSTANT STRINGLITERAL



%type <symbol> translation_unit external_declaration function_definition declaration_list declaration declaration_specifiers init_declarator_list init_declarator type_specifier declarator direct_declarator gensymT pointer parameter_type_list parameter_list parameter_declaration identifier_list initializer initializer_row_list initializer_row designation designator_list primary_expression postfix_expression unary_expression cast_expression nonbool_cast_expression multiplicative_expression nonbool_multiplicative_expression additive_expression nonbool_additive_expression shift_expression nonbool_shift_expression	
relational_expression nonbool_relational_expression	equality_expression nonbool_equality_expression	AND_expression nonbool_AND_expression exclusive_OR_expression inclusive_OR_expression nonbool_inclusive_OR_expression nonbool_exclusive_OR_expression logical_AND_expression logical_OR_expression bool_inclusive_OR_expression bool_logical_OR_expression bool_logical_AND_expression conditional_expression assignment_expression assignment_operator expression constant_expression bool_exp	
expression_opt bool_expression_opt 

%type <fu> argument_expression_list

%type <address> M

%type <nl> N statement labeled_statement compound_statement block_item_list block_item expression_statement selection_statement iteration_statement jump_statement 



%token-table
%nonassoc "then"
%nonassoc ELSE
%nonassoc "Th"
%start start_state
%define parse.error verbose

%%

M :
	{

		//Augnetation to store next instruction for backpatching
		$$ = currAddr()+1;
	}
;

N : 
	{
		//creates a new lsit and adds the current instruction for backpatching
		quadArr.emit(OP_GOTO,"");
		$$ = new nextlist();
		$$->l = makelist(currAddr());
	}

start_state : translation_unit
			  {
			  	quadArr.print();
			  	//global_symbol_table -> print();

			  	cout << endl;
			  	cout << endl;

			  	exit(-1);
			  }
			;						


translation_unit : external_declaration {

									
									
									
									}
				 | translation_unit external_declaration {}
				 ;

external_declaration : function_definition  {}
					 | declaration {}
					 ;

function_definition : declaration_specifiers declarator declaration_list compound_statement 
					  {
					  	//backpatch
					  	backpatch($4->l, currAddr()+1);

					  	//function definition has ended, so pop it
						Stables.pop();
					  	
					  }

 					| declaration_specifiers declarator compound_statement
 					  {
 					  	//backpatch
 					  	backpatch($3->l, currAddr()+1);

 					  	//function definition has ended, so pop it
						Stables.pop();
 					  	
 					  }
 					;

declaration_list : declaration {}
				 | declaration_list declaration {}
				 ;

/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */



declaration : declaration_specifiers init_declarator_list ';' {}
              | declaration_specifiers ';' {}
              ;

declaration_specifiers : type_specifier declaration_specifiers {}
                       | type_specifier {}
                       ;

init_declarator_list : init_declarator  {}
                     | init_declarator_list ',' init_declarator {}
                     ;

init_declarator : declarator 
				  {
				  	//lookup variable in symbol table
				  	if(($1 -> entry_type).bt != function_type) $$ = Stables.top()->lookup($1);
				  	if($1 -> is_matrix)
				  	{
				  		type typee;
                  		typee.bt = matrix_type;
                  		typee.size = 0;
                  		$1 = updatet($1,typee);
				  	}
				  	
				  	
				  }
                | declarator '=' initializer 
                  {
                  	if($1 -> is_matrix == false)
                  	{

                  		//if not a mtrix then lookup the variable and emit
                  		$$ = Stables.top()->lookup($1);
                  		typecheck($3,$$);
           				if(t.bt == int_type) ($$ -> initial).int_initial = ($3 -> initial).int_initial; 
           				if(t.bt == char_type) ($$ -> initial).char_initial = ($3 -> initial).char_initial; 
           				if(t.bt == double_type) ($$ -> initial).double_initial = ($3 -> initial).double_initial; 
                  		quadArr.emit(OP_eq , $3 -> name, $1->name);
                  	}

                  	else
                  	{
                  		type typee;
                  		typee.bt = matrix_type;
                  		typee.size = 0;
                  		$1 = updatet($1,typee);
                  		//store the initial entries in matrix class object's entries
                  		for(int i = 0; i < mat_init.size() ; i++)
                  		{
                  			($1 -> m -> entries).push_back(mat_init.at(i));
                  		}
                  		$1 -> size = $1 -> m -> size();
                  		string s;
                  		s = s + "{";
                  		
                  		for(int i =0 ; i < $1 -> m -> dim1;i++)
                  		{
                  			for(int j =0 ; j < $1 -> m -> dim2 ;j++)
                  			{
                  				s = s + conv2string(mat_init.at(($1 -> m -> dim2 * i + j)));
                  				s = s + ",";
                  			}
                  			s = s.substr(0,s.size()-1);
                  			s = s + ";";
                  		}
                  		s = s.substr(0,s.size()-1);
                  		s = s + "}";
                  		
                  		$$ = Stables.top()->lookup($1);
                  		quadArr.emit(OP_eq,s,$1->name);
                  		mat_init.clear();
                  		(($$ -> initial).name).names = new char[s.size()+1];
                  		strcpy ((($$ -> initial).name).names, s.c_str());
                  		(($$ -> initial).name).d = s.size()+1;
                  		
                  	}
                  	$1 -> is_initialized = true;
                  	
                  }
                ;

type_specifier : VOID 
				 {

				 	//save current type
					t.bt = void_type;
					
				 }
				| CHAR
				  {
				    //save current type
					t.bt = char_type;
					t.size = 1;
					
				  }
				| SHORT {}
				| INT  
				  {
				  	//save current type
				  	t.bt = int_type;
				  	t.size = 4;

					
				  }
				| LONG  {}
				| FLOAT  {}
				| DOUBLE  
				  {
				  	//save current type
				  	t.bt = double_type;
				  	t.size = 8;
				  	
				  }
				| MATRIX  
				  {
				  	//save current type
				  	t.bt = matrix_type;
				  	t.size = 0;
				  	
				  }
				| SIGNED  {}
				| UNSIGNED {}
				| BOOL {}
				 ;

declarator : direct_declarator 
			{

				


			}
		   | pointer direct_declarator 
		   	{
				$$ = $2;
		   		
		   	}
		   ;

direct_declarator : IDENTIFIER 
					{
						//initiate the function class for function type
						$1-> entry_type = t;
						type typee;
						typee.bt = function_type;
						typee.size = 0;
						typee.actual_type = NULL;
						currfunc = new symbol_entry($1->name, typee);
						currfunc -> createnest();
						(currfunc-> nested ->f)->returntype = t;
						$$ = $1;
						
					
					}
				  | '(' declarator ')' {}
				  | IDENTIFIER '[' assignment_expression ']' '[' assignment_expression ']' 
				  	{
				  		//store the initial dimensions
				  		convBool2Int($3);
				  		convBool2Int($6);
				  		a_matrix = true;
				  		$1 -> m = new matrix();
				  		($1 -> m) -> dim1 = ($3 -> initial).int_initial;
				  		($1 -> m) -> dim2 = ($6 -> initial).int_initial;
				  		$1 -> is_matrix = true;
				  		$$ = $1;
				  		
				  		
				  	}
				  | direct_declarator '[' ']' '[' ']'   
				  	{
				  		
				  	}
				  | direct_declarator gensymT '(' parameter_type_list ')' 
				  	{
				  		
				  		$$ = $2;
				  		
				  	}
				  | direct_declarator gensymT '(' identifier_list ')' 
				  	{
				  		$$ = $2;
				  		
				  	}
				  | direct_declarator gensymT '(' ')' 
				  	{
				  		$$ = $2;

				  		

				    }
				  ;

gensymT :	{

				/*
					Augmentation that looks up for the current function
					and adds it to the symbol table, creates new scope for 
					the variables.
				*/

				Stables.top()->lookup(currfunc);
				currfunc -> nested -> lookup("ret",t);
				Stables.push(currfunc -> nested);
				quadArr.emit(OP_LAB,currfunc-> name);
				$$ = currfunc;
				
				/*symbol_entry * s = Stables.top()->lookup(if_func.name);
				
				symbolTable * newST = new symbolTable(if_func.name);
				newST -> lookup("ret",if_func.type_f);
				s -> nested = newST;
				s -> entry_type.bt = function_type;
    			s -> entry_type.size = 0;
				Stables.push(newST);
				quadArr.emit(OP_LAB,if_func.name);
				newST -> f -> returntype = if_func.type_f;
				$$ = s;*/

			}
		;

pointer : '*'  {
					//Updates the type of t to a pointer type
					type tdash;
					tdash = t;
					tdash.bt = pointer_type;
					tdash.size = 4;
					tdash.actual_type = &t;
					t = tdash;

				
			   }
		 | '*' pointer 
		 	{
		 		//Updates the type of t to a pointer type
		 		type tdash;
				tdash = t;
				tdash.bt = pointer_type;
				tdash.size = 4;
				tdash.actual_type = &t;
				t = tdash;
		 	
		 	}
		 ;

parameter_type_list : parameter_list {};

parameter_list : parameter_declaration {}
			   | parameter_list ',' parameter_declaration {}
			   ;

parameter_declaration : declaration_specifiers declarator 
						{
							//Save the types into symbol tables 
							Stables.top() -> lookup($2);

							(Stables.top()-> f)->typelist.push_back(t);
							
						}
					  | declaration_specifiers {}
					  ;

identifier_list : IDENTIFIER  {}
				| identifier_list ',' IDENTIFIER  {}
				;

initializer : assignment_expression
			  {
			  	//Store the initial values of a matrix in initialization phase
			  	if(a_matrix) mat_init.push_back(($1 -> initial).double_initial);

			  	$$ = $1;
				
			  }
			| '{' initializer_row_list '}' 
			   {
			   		$$ = $2;
			   		
			   }
			;

initializer_row_list : initializer_row  {}
					 | initializer_row_list ';' initializer_row {}
					 ;

initializer_row : initializer  {}
				| designation initializer {}
				| initializer_row ',' initializer 
				  
				;

designation : designator_list '='   {} ;

designator_list : designator  {}
				| designator_list designator {}
				;

designator : '[' constant_expression ']' {}
		   | '.' IDENTIFIER {}
		   ;


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 



primary_expression : IDENTIFIER 
					{
						
						//Lookup for the identifier in top most symbol table
						//i.e in the present scope

						$$ = Stables.top()->lookup($1 -> name);
						$$ = new symbol_entry(*$$);
						
					}
                   	|CONSTANT   {
                   					}
			        |STRINGLITERAL {}
			        |'('expression')' 
			          {
    					$$ = $2;
    					
    				  }
			        ;

postfix_expression : primary_expression  {}
                   	| IDENTIFIER '[' expression ']' '[' expression ']'  
                   	  {

                   	  	type typee;
                   	  	typee.bt = int_type;
                   	  	typee.size = 4;
                   	  	typee.actual_type = NULL;
                   	  	symbol_entry* s1 = Stables.top()->gentemp(typee);
						if(!($3 -> is_initialized)) quadArr.emit(OP_mul,$3 -> name,"8",s1 -> name);
						else  
						{
							//int a = ($3 -> initial).int_initial;
							//a = a* 8;
							//quadArr.emit(OP_eq, conv2string(a),s1->name);
						}
						symbol_entry* s2 = Stables.top()->gentemp(typee);
						quadArr.emit(OP_eqmat, $1 -> name,"4",s2->name);

						symbol_entry* s3 = Stables.top()->gentemp(typee);
						quadArr.emit(OP_sub,s1->name,"8",s3->name);

						symbol_entry* s4 = Stables.top()->gentemp(typee);
						quadArr.emit(OP_mul,s2->name,s3->name,s4->name);

						

						symbol_entry* s5 = Stables.top()->gentemp(typee);
						if(!($6 -> is_initialized)) quadArr.emit(OP_mul,$6 -> name,"8",s5 -> name);
						else  
						{
							//int a = ($6 -> initial).int_initial;
							//a = a* 8;
							//quadArr.emit(OP_eq, conv2string(a),s5->name);
						}

						symbol_entry* s6 = Stables.top()->gentemp(typee);
						quadArr.emit(OP_add,s4->name,s5->name,s6->name);

						symbol_entry* s7 = Stables.top()->gentemp(typee);
						quadArr.emit(OP_add,s6->name,"8",s7->name);

						$$ = $1;
						offset.assign(s7->name);
						($$ -> matoffset).assign(s7->name);
						$$ -> is_matrix = true;
						is_offset = true;

                   	  
                   	  }
			        | postfix_expression '(' argument_expression_list ')' 
			          {
			          	//calls function
			          		
			          	$3 -> method($1);
						$$ = $1;
			          

			          }
			        | postfix_expression '(' ')' {}
			        | postfix_expression '.' IDENTIFIER  {}
			        | postfix_expression ACCESS IDENTIFIER {}
			        | postfix_expression INCR 
			          {
			          		/* Creates a new temporary variable, copies the present value in it
			          		   increment the variable 
			          		*/

			          		$$ = Stables.top()->gentemp(($1-> entry_type));
							type typee;
			        	  	typee.bt = int_type;
			        	  	typee.size = 4;
			        	  	typee.actual_type = NULL;
			        	  	symbol_entry* temp1 = Stables.top() -> gentemp(typee);
							quadArr.emit(OP_eq, "1",temp1->name);
							quadArr.emit(OP_eq, $1 -> name,$$ -> name);
							quadArr.emit(OP_add ,$1 -> name,temp1 -> name,$1 -> name);
			          		
			          }
			        | postfix_expression DECR 
			          {
			          		/* Creates a new temporary variable, copies the present value in it
			          		   decrement the variable 
			          		*/

			          		$$ = Stables.top() -> gentemp(($1-> entry_type));
							type typee;
			        	  	typee.bt = int_type;
			        	  	typee.size = 4;
			        	  	typee.actual_type = NULL;
			        	  	symbol_entry* temp1 = Stables.top() -> gentemp(typee);
							quadArr.emit(OP_eq, "1",temp1->name);
							quadArr.emit(OP_eq, $1 -> name,$$ -> name);
							quadArr.emit(OP_sub ,$1 -> name,temp1 -> name,$1 -> name);
			          		
			          }
			        | postfix_expression TRANSPOSE 
			          {
			          	//adds the transpose to the quad
			          	quadArr.emit(OP_transpose,$1 -> name,$$ -> name);
			          	
			          }
			        ;

argument_expression_list : assignment_expression  
						   {
						   		//initiates function utitlity
						   		$$ = new func_utility();
								($$ -> l).push_back($1);
						   		
						   }
                         | argument_expression_list ',' assignment_expression  
                           {
                           		//adds the parameters
                           		($1 -> l).push_back($3);
								$$ = $1;
                           		

                           }
                         ;

unary_expression : 	postfix_expression   
					{
						if($1 -> is_matrix) $$ -> is_matrix = true;
						
					}
                 	| INCR unary_expression 
                 	  {
                 	  	//Increments the variable and propogates it
                 	  	type typee;
		        	  	typee.bt = int_type;
		        	  	typee.size = 4;
		        	  	typee.actual_type = NULL;
		        	  	symbol_entry* temp1 = Stables.top() -> gentemp(typee);
						quadArr.emit(OP_eq, "1",temp1 -> name);
						quadArr.emit(OP_add, $2-> name, temp1 -> name,$2 -> name);
						$$ = $2;
                 	  	
                 	  }
		        	| DECR  unary_expression 
		        	  {
		        	  	//decrements the variable and propogates it
		        	  	type typee;
		        	  	typee.bt = int_type;
		        	  	typee.size = 4;
		        	  	typee.actual_type = NULL;
		        	  	symbol_entry* temp1 = Stables.top() -> gentemp(typee);
						quadArr.emit(OP_eq, "1",temp1 -> name);
						quadArr.emit(OP_sub, $2-> name, temp1 -> name,$2 -> name);
						$$ = $2;
		        	  	
		        	  }
		        	| ADDR cast_expression
		        	  {
		        	  	type ty = ($2-> entry_type).getbasetype();
		        	  	type typee;
		        	  	typee.bt = pointer_type;
		        	  	typee.size = 4;
		        	  	typee.actual_type = &ty;
						
						
						$$ = Stables.top() -> gentemp(typee);
						quadArr.emit(OP_addr , $2-> name , $$ -> name);
		        	  	
		        	  }
		        	| '*' cast_expression 
		        	  {
		        	  	
		        	  	type typee;
	              		typee.bt = int_type;
	              		typee.size = 4;
	              		typee.actual_type = NULL;
					
		        	  	symbol_entry* temp = Stables.top() -> gentemp(typee);

		        	  	quadArr.emit(OP_eq, "0",temp -> name);
						quadArr.emit(OP_mul,temp->name, conv2string(($2 -> entry_type).size),temp -> name);
						
		        	  	
		        	  }
		        	| '+' cast_expression 
		        	  {
		        	  	convBool2Int($2);
						$$ = $2;
		        	  	
		        	  }
		        	| '-' cast_expression 
		        	  {
		        	  	convBool2Int($2);
						$$ = Stables.top() -> gentemp($2 -> entry_type);
						quadArr.emit(OP_uminus, $2-> name,$$ -> name);
		        	  	
		        	  }
		        	;

cast_expression :	 unary_expression 
					{
						$$ = $1;
						

					}
				;

nonbool_cast_expression	: 	cast_expression
							{
								/*
									Augmentation that helps to convert bool
									type variable to int type at proper place for
									arithmetic operations
								*/
								convBool2Int($1);
								$$ = $1;
							}
							;

multiplicative_expression : cast_expression {}
							| nonbool_multiplicative_expression '*' nonbool_cast_expression 
							 {
							 	//multiplies
							 	//if it's a matrix entry, the values multiplied are matrix entries
							 	typecheck($1, $3);

							 	string x,y;
		                      	x.assign($1 -> name);
		                      	y.assign($3 -> name);

		                      	if($1 -> is_matrix)
								{
									type typee;
									typee.bt = double_type;
									typee.size = 8;
									typee.actual_type = NULL;

									symbol_entry * s1 = Stables.top() -> gentemp(typee);
									quadArr.emit(OP_eqmat,$1->name,$1 -> matoffset,s1 -> name);
									x.assign(s1 -> name);
								}

								if($3 -> is_matrix)
								{
									type typee;
									typee.bt = double_type;
									typee.size = 8;
									typee.actual_type = NULL;

									symbol_entry * s2 = Stables.top() -> gentemp(typee);
									quadArr.emit(OP_eqmat,$3->name,$3 -> matoffset,s2 -> name);
									y.assign(s2 -> name);
								}
								type typee;
								typee.bt = matrix_type;
								typee.size = 0;
								typee.actual_type = NULL;
								if(!($1 -> is_matrix) && !($3 -> is_matrix)) $$ = Stables.top() -> gentemp($1 -> entry_type);
								else 
								{
									$$ = Stables.top() -> gentemp(typee);
								}
								quadArr.emit(OP_mul, x,y,$$ -> name);
							 	
							 }
							| nonbool_multiplicative_expression '/' nonbool_cast_expression 
							  {
							  	//divides
							  	//if it's a matrix entry, the values divided are matrix entries
							  	typecheck($1, $3);

							 	string x,y;
		                      	x.assign($1 -> name);
		                      	y.assign($3 -> name);

		                      	if($1 -> is_matrix)
								{
									type typee;
									typee.bt = double_type;
									typee.size = 8;
									typee.actual_type = NULL;

									symbol_entry * s1 = Stables.top() -> gentemp(typee);
									quadArr.emit(OP_eqmat,$1->name,$1 -> matoffset,s1 -> name);
									x.assign(s1 -> name);
								}

								if($3 -> is_matrix)
								{
									type typee;
									typee.bt = double_type;
									typee.size = 8;
									typee.actual_type = NULL;

									symbol_entry * s2 = Stables.top() -> gentemp(typee);
									quadArr.emit(OP_eqmat,$3->name,$3 -> matoffset,s2 -> name);
									y.assign(s2 -> name);
								}
								type typee;
								typee.bt = matrix_type;
								typee.size = 0;
								typee.actual_type = NULL;
								if(!($1 -> is_matrix) && !($3 -> is_matrix)) $$ = Stables.top() -> gentemp($1 -> entry_type);
								else 
								{
									$$ = Stables.top() -> gentemp(typee);
								}
								quadArr.emit(OP_div, x,y,$$ -> name);
							  	
							  }
							| nonbool_multiplicative_expression '%' nonbool_cast_expression 
							  {
							  	//calculates mod
							  	//if it's a matrix entry, the values of operands of mod are matrix entries
							  	typecheck($1, $3);

							 	string x,y;
		                      	x.assign($1 -> name);
		                      	y.assign($3 -> name);

		                      	if($1 -> is_matrix)
								{
									type typee;
									typee.bt = double_type;
									typee.size = 8;
									typee.actual_type = NULL;

									symbol_entry * s1 = Stables.top() -> gentemp(typee);
									quadArr.emit(OP_eqmat,$1->name,$1 -> matoffset,s1 -> name);
									x.assign(s1 -> name);
								}

								if($3 -> is_matrix)
								{
									type typee;
									typee.bt = double_type;
									typee.size = 8;
									typee.actual_type = NULL;

									symbol_entry * s2 = Stables.top() -> gentemp(typee);
									quadArr.emit(OP_eqmat,$3->name,$3 -> matoffset,s2 -> name);
									y.assign(s2 -> name);
								}
								type typee;
								typee.bt = matrix_type;
								typee.size = 0;
								typee.actual_type = NULL;
								if(!($1 -> is_matrix) && !($3 -> is_matrix)) $$ = Stables.top() -> gentemp($1 -> entry_type);
								else 
								{
									$$ = Stables.top() -> gentemp(typee);
								}
								quadArr.emit(OP_mod, x,y,$$ -> name);
							  	
							  }
							;

nonbool_multiplicative_expression	: 	multiplicative_expression
										{
											/*
												Augmentation that helps to convert bool
												type variable to int type at proper place for
												arithmetic operations
											*/
											convBool2Int($1);
											$$ = $1;
										}
										;

additive_expression : multiplicative_expression {}
                    | nonbool_additive_expression '+' nonbool_multiplicative_expression 
                      {
                      	//adds
                      	//if it's a matrix entry, the values added are matrix entries
                      	typecheck($1, $3);

                      	string x,y;
                      	x.assign($1 -> name);
                      	y.assign($3 -> name);

                      	if($1 -> is_matrix)
						{
							type typee;
							typee.bt = double_type;
							typee.size = 8;
							typee.actual_type = NULL;

							symbol_entry * s1 = Stables.top() -> gentemp(typee);
							quadArr.emit(OP_eqmat,$1->name,$1 -> matoffset,s1 -> name);
							x.assign(s1 -> name);
						}

						if($3 -> is_matrix)
						{
							type typee;
							typee.bt = double_type;
							typee.size = 8;
							typee.actual_type = NULL;

							symbol_entry * s2 = Stables.top() -> gentemp(typee);
							quadArr.emit(OP_eqmat,$3->name,$3 -> matoffset,s2 -> name);
							y.assign(s2 -> name);
						}

						type typee;
						typee.bt = matrix_type;
						typee.size = 0;
						typee.actual_type = NULL;
						if(!($1 -> is_matrix) && !($3 -> is_matrix)) $$ = Stables.top() -> gentemp(($1 -> entry_type).getbasetype());
						else 
						{
							$$ = Stables.top() -> gentemp(typee);
						}
						quadArr.emit(OP_add, x,y,$$ -> name);
							
                      	
                      }
        			| nonbool_additive_expression '-' nonbool_multiplicative_expression 
        			  {
        			  	//subtracts
        			  	//if it's a matrix entry, the values subtracted are matrix entries
        			  	typecheck($1, $3);

                      	string x,y;
                      	x.assign($1 -> name);
                      	y.assign($3 -> name);

                      	if($1 -> is_matrix)
						{
							type typee;
							typee.bt = double_type;
							typee.size = 8;
							typee.actual_type = NULL;

							symbol_entry * s1 = Stables.top() -> gentemp(typee);
							quadArr.emit(OP_eqmat,$1->name,$1 -> matoffset,s1 -> name);
							x.assign(s1 -> name);
						}

						if($3 -> is_matrix)
						{
							type typee;
							typee.bt = double_type;
							typee.size = 8;
							typee.actual_type = NULL;

							symbol_entry * s2 = Stables.top() -> gentemp(typee);
							quadArr.emit(OP_eqmat,$3->name,$3 -> matoffset,s2 -> name);
							y.assign(s2 -> name);
						}

						type typee;
						typee.bt = matrix_type;
						typee.size = 0;
						typee.actual_type = NULL;
						if(!($1 -> is_matrix) && !($3 -> is_matrix)) $$ = Stables.top() -> gentemp(($1 -> entry_type).getbasetype());
						else 
						{
							$$ = Stables.top() -> gentemp(typee);
						}
						quadArr.emit(OP_sub, x,y,$$ -> name);
						
        			  	
        			  }
        			;

nonbool_additive_expression	: 	additive_expression
								{
									/*
										Augmentation that helps to convert bool
										type variable to int type at proper place for
										arithmetic operations
									*/	
									convBool2Int($1);
									$$ = $1;
								}
								;

shift_expression : additive_expression {}
                 | shift_expression SHLL additive_expression 
                   {
                   		//shifts left
                   		typecheck($1, $3);
						$$ = Stables.top() -> gentemp($1 -> entry_type);
						quadArr.emit(OP_shl, $1 -> name, $3 -> name,$$ -> name);
                   		
                   }
        		 | shift_expression SHRL additive_expression 
        		   {
        		   		//shifts right
        		   		typecheck($1, $3);
						$$ = Stables.top() -> gentemp($1 -> entry_type);
						quadArr.emit(OP_shr, $1 -> name, $3 -> name,$$ -> name);
        		   		
        		   }
        		 ;

nonbool_shift_expression	: 	shift_expression
								{
									/*
										Augmentation that helps to convert bool
										type variable to int type at proper place for
										arithmetic operations
									*/
									convBool2Int($1);
									$$ = $1;
								}
								;

relational_expression : shift_expression {}
                      | nonbool_relational_expression '<' nonbool_shift_expression 
                        {
                        	//does necessary type checkings relop functionality is carried out
                        	typecheck($1, $3);

		                  	type typee;
		              		typee.bt = bool_type;
		              		typee.size = 0;
		              		typee.actual_type = NULL;
							quadArr.emit(OP_IFLessGOTO, $1 -> name , $3 -> name,"");
							$$ = new symbol_entry(typee);
							$$->truelist = makelist(currAddr());
							quadArr.emit(OP_GOTO,"");
							$$->falselist = makelist(currAddr());
							$$ -> entry_type = typee;
                       		
                       	}
			          | nonbool_relational_expression '>' nonbool_shift_expression  
			            {
			            	//does necessary type checkings relop functionality is carried out
			            	typecheck($1, $3);

	                      	type typee;
		              		typee.bt = bool_type;
		              		typee.size = 0;
		              		typee.actual_type = NULL;
							quadArr.emit(OP_IFGrtGOTO, $1 -> name , $3 -> name,"");
							$$ = new symbol_entry(typee);
							$$->truelist = makelist(currAddr());
							quadArr.emit(OP_GOTO,"");
							$$->falselist = makelist(currAddr());
							$$ -> entry_type = typee;
			            	
			            }
			          | nonbool_relational_expression LTE nonbool_shift_expression  
			          	{
			          		//does necessary type checkings relop functionality is carried out
			          		typecheck($1, $3);

	                      	type typee;
		              		typee.bt = bool_type;
		              		typee.size = 0;
		              		typee.actual_type = NULL;
							quadArr.emit(OP_IFLessEqGOTO, $1 -> name , $3 -> name,"");
							$$ = new symbol_entry(typee);
							$$->truelist = makelist(currAddr());
							quadArr.emit(OP_GOTO,"");
							$$->falselist = makelist(currAddr());
							$$ -> entry_type = typee;
			          		
			          	}
			          | nonbool_relational_expression GTE nonbool_shift_expression 
			          	{
			          		//does necessary type checkings relop functionality is carried out
			          		typecheck($1, $3);

	                      	type typee;
		              		typee.bt = bool_type;
		              		typee.size = 0;
		              		typee.actual_type = NULL;
							quadArr.emit(OP_IFGrtEqGOTO, $1 -> name , $3 -> name,"");
							$$ = new symbol_entry(typee);
							$$->truelist = makelist(currAddr());
							quadArr.emit(OP_GOTO,"");
							$$->falselist = makelist(currAddr());
							$$ -> entry_type = typee;
			          		
			          	}
			          ;

nonbool_relational_expression	: 	relational_expression
									{
										/*
											Augmentation that helps to convert bool
											type variable to int type at proper place for
											arithmetic operations
										*/
										convBool2Int($1);
										$$ = $1;
									}
									;

equality_expression : relational_expression {}
                    | nonbool_equality_expression EQ nonbool_relational_expression  
                      {
                      	//goto as required is generated
                      	typecheck($1, $3);

                      	type typee;
	              		typee.bt = bool_type;
	              		typee.size = 0;
	              		typee.actual_type = NULL;
						quadArr.emit(OP_IFLogEqGOTO, $1 -> name , $3 -> name,"");
						$$ = new symbol_entry(typee);
						$$->truelist = makelist(currAddr());
						quadArr.emit(OP_GOTO,"");
						$$->falselist = makelist(currAddr());
						$$ -> entry_type = typee;
                      	
                      }
        			| nonbool_equality_expression NEQ nonbool_relational_expression  
        			  {
        			  	//goto as required is generated
        			  	typecheck($1, $3);

                      	type typee;
	              		typee.bt = bool_type;
	              		typee.size = 0;
	              		typee.actual_type = NULL;
						quadArr.emit(OP_IFNotEqGOTO, $1 -> name , $3 -> name,"");
						$$ = new symbol_entry(typee);
						$$->truelist = makelist(currAddr());
						quadArr.emit(OP_GOTO,"");
						$$->falselist = makelist(currAddr());
						$$ -> entry_type = typee;
        			  	
        			  }
        			;

nonbool_equality_expression	: 	equality_expression
								{
									/*
										Augmentation that helps to convert bool
										type variable to int type at proper place for
										arithmetic operations
									*/
									convBool2Int($1);
									$$ = $1;
								}
								;

AND_expression : equality_expression {}
               | nonbool_AND_expression '&' nonbool_equality_expression 
               	 {
               	    convBool2Int($1);
					convBool2Int($3);
					convDouble2Int($1);
					convDouble2Int($3);
					convChar2Int($1);
					convChar2Int($3);

					type typee;
              		typee.bt = int_type;
              		typee.size = 4;
              		typee.actual_type = NULL;
					$$ = Stables.top() -> gentemp(typee);
					quadArr.emit(OP_bitand,$1 -> name,  $3 -> name,$$ -> name);
               		
               	 }
                 ;

nonbool_AND_expression	: 	AND_expression
							{
								/*
									Augmentation that helps to convert bool
									type variable to int type at proper place for
									arithmetic operations
								*/
								convBool2Int($1);
								$$ = $1;
							}
							;

exclusive_OR_expression : AND_expression  {}
                        | exclusive_OR_expression '^' nonbool_AND_expression  
						  {
						  	convBool2Int($1);
							convBool2Int($3);
							convDouble2Int($1);
							convDouble2Int($3);
							convChar2Int($1);
							convChar2Int($3);

							type typee;
                      		typee.bt = int_type;
                      		typee.size = 4;
                      		typee.actual_type = NULL;
							$$ = Stables.top() -> gentemp(typee);
							quadArr.emit(OP_bitxor,$1 -> name,  $3 -> name,$$ -> name);
						  	
						  }
                        ;

inclusive_OR_expression : exclusive_OR_expression {}
                        | nonbool_inclusive_OR_expression '|' nonbool_exclusive_OR_expression
                          {	
                          	/* For bit wose or, we need int */
                          	convBool2Int($1);
							convBool2Int($3);
							convDouble2Int($1);
							convDouble2Int($3);
							convChar2Int($1);
							convChar2Int($3);

							type typee;
                      		typee.bt = int_type;
                      		typee.size = 4;
                      		typee.actual_type = NULL;
							$$ = Stables.top() -> gentemp(typee);
							quadArr.emit(OP_bitor,$1 -> name,  $3 -> name,$$ -> name);
                          	
                          }
                        ;

nonbool_inclusive_OR_expression	: 	inclusive_OR_expression
								{
									/*
										Augmentation that helps to convert bool
										type variable to int type at proper place for
										arithmetic operations
									*/
									convBool2Int($1);
									$$ = $1;
								}
								;

nonbool_exclusive_OR_expression	: 	exclusive_OR_expression
								{
									/*
										Augmentation that helps to convert bool
										type variable to int type at proper place for
										arithmetic operations
									*/
									convBool2Int($1);
									$$ = $1;
								}
								;



logical_AND_expression : inclusive_OR_expression  {}
                       | bool_logical_AND_expression LOGAND M bool_inclusive_OR_expression 
                       	 {
                       	 	 /*  nonterminal M has been provided to backpatch the truelists
								 and falselists of the boolean expression which stores the address
							*/
                       	 	type typee;
                      		typee.bt = bool_type;
                      		typee.size = 0;
                      		typee.actual_type = NULL;
                      		$$ = new symbol_entry(typee);
                      		backpatch($1 -> truelist, $3);
							$$ -> truelist = $4 -> truelist;
							$$ -> falselist = merge($1 -> falselist, $4 -> falselist);

                       		
                       	 }
                       ;

logical_OR_expression : logical_AND_expression {}
                      | bool_logical_OR_expression LOGOR M bool_logical_AND_expression 
                      	{
                      		/*  nonterminal M has been provided to backpatch the truelists
								 and falselists of the boolean expression which stores the address
							*/
                      		type typee;
                      		typee.bt = bool_type;
                      		typee.size = 0;
                      		typee.actual_type = NULL;
                      		$$ = new symbol_entry(typee);
                      		backpatch($1 -> falselist, $3);
                      		$$ -> truelist = merge($1 -> truelist, $4 -> truelist);
                      		$$ -> falselist = $4 -> falselist;
                      		
                      	}
                      ;

bool_inclusive_OR_expression:	inclusive_OR_expression
								{
									/*
										Augmentation that helps to convert Double type to
										Bool type at proper place for
										arithmetic operations
									*/
									convDouble2Int($1);
									convChar2Int($1);
									convInt2Bool($1);
									$$ = $1;
								}
							;

bool_logical_OR_expression	:	logical_OR_expression
								{
									/*
										Augmentation that helps to convert Double type to
										Bool type at proper place for
										arithmetic operations
									*/
									convDouble2Int($1);
									convChar2Int($1);
									convInt2Bool($1);
									$$ = $1;
								}
							;

bool_logical_AND_expression	:	logical_AND_expression
								{
									/*
										Augmentation that helps to convert Double type to
										Bool type at proper place for
										arithmetic operations
									*/
									convDouble2Int($1);
									convChar2Int($1);
									convInt2Bool($1);
									$$ = $1;
								}
							;

conditional_expression : logical_OR_expression {}
                       | bool_logical_OR_expression '?' M expression N ':' M conditional_expression N
                       	 {
                       	 	/* Suitable non terminals with empty transitions have been put to place jumps at proper
							   places to compute the function */
                       	 	backpatch($1 -> truelist, $3);
							backpatch($1 -> falselist, $7);
						    typecheck($4, $8);
							$$ = Stables.top() -> gentemp($4 -> entry_type);

							quadArr.emit( OP_eq, $4 -> name, $$->name);
							backpatch($5 -> l, currAddr());
							quadArr.emit(OP_GOTO,"");
							list li = list(currAddr());
							quadArr.emit(OP_eq, $8 -> name, $$ -> name);
							backpatch($9 -> l, currAddr());
							backpatch(li, currAddr()+1);
                       	 	
                       	 }
                       	;

assignment_expression : conditional_expression {}
                      | unary_expression assignment_operator assignment_expression 
                      	{
                      		//generates quads corresponding to matix and non matrix operands
                      		
                      		convBool2Int($3);
							typecheck($3,$1);
							if($1 -> is_matrix && is_offset)
							{
								quadArr.emit( OP_mateq,$1 -> matoffset,$3->name, $1 -> name);
							}

							else if($3 -> is_matrix && is_offset)
							{
								quadArr.emit( OP_eqmat,$3 -> name,$3->matoffset, $1 -> name);
							}

							else 
							{
								quadArr.emit( OP_eq , $3 -> name, $1 -> name);
							}
							$$ = $1;
							is_offset = false;
                      		
                      	}
                      ;

assignment_operator : '=' {}
					 | ASSNMUL {} 
					 | ASSNDIV {} 
					 | ASSNMOD {} 
					 | ASSNADD {} 
					 | ASSNSUB {} 
					 | ASSNSHLL {} 
					 | ASSNSHRL {} 
					 | ASSNBINAND {}
					 | ASSNXOR {}
					 | ASSNBINOR {}
					 ;

expression : assignment_expression {}
           | expression ',' assignment_expression {}
           ;

constant_expression : conditional_expression {} ;





/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */



statement : labeled_statement  {}
		  | compound_statement {}
		  | expression_statement {}
		  | selection_statement	{}
		  | iteration_statement	{}
		  | jump_statement	{}
		  ;

labeled_statement : IDENTIFIER ':' statement {}
				  | CASE constant_expression ':' statement {}
				  | DEFAULT ':' statement {}
				  ;

compound_statement : '{' '}'  
					  {
					  	$$ = new nextlist();
					  	
					  }
				   | '{' block_item_list '}'	
				   	  {
				   	  	$$ = $2;
				   	  	
				   	  }
				   ;

block_item_list : block_item  {}
				| block_item_list M block_item 
				  {
				  	//previous block is backpatched to current block
				  	backpatch($1->l, $2);
					$$ = $3;
				  	
				  }
				;

block_item : declaration 
			{
				$$ = new nextlist();
				
			}
		   | statement {}
		   ;

expression_statement : ';' 
						{
							$$ = new nextlist();
							
						}
					 | expression ';' 
					   {
					   		//Backpatcing dangling booleans
					   		if(($1-> entry_type).bt == bool_type)
							{
								backpatch($1->truelist, currAddr()+1);
								backpatch($1->falselist, currAddr()+1);
							}
							$$ = new nextlist();
							
					   }
					 ;

selection_statement : IF '(' bool_exp ')' M statement N    %prec "then" 
					  {
					  	// N has instruction number of next goto
					  	// M has number of next instruction
					  	backpatch($3 -> truelist, $5);
						$$ = new nextlist();
						$$->l = $3->falselist;
						$$->l = merge($$->l, $6->l);
						$$->l = merge($$->l, $7->l);
					  	
					  }
					| IF '(' bool_exp ')' M statement N ELSE M statement 
					  {
					  	// N has instruction number of next goto
					  	// M has number of next instruction
					  	backpatch($3 -> truelist, $5);
					  	backpatch($3 -> falselist, $9);
					  	$$ = new nextlist();
					  	$$ -> l = merge($6 -> l, $7 -> l);
					  	$$ -> l = merge($$ -> l, $10 -> l);

					  	
					  }
					| SWITCH '(' bool_exp ')' statement {}
					;

bool_exp			: 	expression
					{
						/* This augmentation has been provided to convert ints to bool 
						   at corect place
						*/
						convDouble2Int($1);
						convInt2Bool($1);
						$$ = $1;
					}

expression_opt : expression {}
			   | {
			   		$$ = NULL;
			   		
			   	 }
			   ;
bool_expression_opt : bool_exp
			   | {}
			   ;

iteration_statement : WHILE M '(' bool_exp ')' M statement  
					  {
					  	// N has instruction number of next goto
					  	// M has number of next instruction
					  	backpatch($7 -> l, $2);
					  	backpatch($4 -> truelist , $6);
					  	$$ = new nextlist();
					  	$$ -> l = $4 -> falselist;
					  	quadArr.emit(OP_GOTO,conv2string($2));

					  	
					  }
					| DO M statement WHILE '(' M bool_exp ')' ';' 
					{
						// N has instruction number of next goto
					  	// M has number of next instruction
						backpatch($7 -> truelist, $2);
						backpatch($3 -> l , $6);
						$$ = new nextlist();
						$$ -> l = $7 -> falselist;
						
					}
					| FOR '(' expression_opt ';'  M bool_expression_opt ';' M expression_opt N ')' M statement 
					  {
					  	// N has instruction number of next goto
					  	// M has number of next instruction
					    backpatch($6 -> truelist, $12 );
						backpatch($10 -> l, $5 );
						backpatch($13 -> l, $8);
						quadArr.emit(OP_GOTO,conv2string($8));

						$$ = new nextlist();
						$$ -> l = $6 -> falselist;

					  	
					  }
					| FOR '(' declaration expression_opt';' expression_opt ')' statement 
					  {}
					;

jump_statement : GOTO IDENTIFIER ';' {}
			   | CONTINUE ';' {}
			   | BREAK ';' {}
			   | RETURN expression_opt ';'
			     {
			     	//If there is nothing just emit return
			     	if($2 == 0)
					{
						quadArr.emit(OP_ret,"");
					}
					//otherwise emit return label
					else
					{
						type ty = (Stables.top() -> f)->returntype;
						update($2, ty);
						quadArr.emit(OP_ret,$2 -> name);
					}
					$$ = new nextlist();

			     	
			     }
			   ;


/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */





%%

void yyerror (char const *s) {
   fprintf (stdout, "%s\n", s);
 }