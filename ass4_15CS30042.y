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

func_details if_func;
type t;

vector<double> mat_init;
bool a_matrix;

string offset;
bool is_offset;

symbol_entry* currfunc;


%}

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

		//Augnetation to store next instruction
		$$ = currAddr()+1;
	}
;

N : 
	{
		//creates a new lsit and adds the current instruction
		quadArr.emit(OP_GOTO,"");
		$$ = new nextlist();
		$$->l = makelist(currAddr());
	}

start_state : translation_unit
			  {
			  	quadArr.print();
			  	global_symbol_table -> print();

			  	cout << endl;
			  	cout << endl;

			  	


			  	exit(-1);
			  }
			;						


translation_unit : external_declaration {

									
									printf("translation_unit => external_declaration\n");
									
									}
				 | translation_unit external_declaration {printf("translation_unit => translation_unit external_declaration\n");}
				 ;

external_declaration : function_definition  {printf("external_declaration => function_definition\n");}
					 | declaration {printf("external_declaration => definition\n");}
					 ;

function_definition : declaration_specifiers declarator declaration_list compound_statement 
					  {
					  	//backpatch
					  	backpatch($4->l, currAddr()+1);

					  	//function definition has ended, so pop it
						Stables.pop();
					  	printf("function_definition => declaration_specifiers declarator declaration_list compound_statement\n");
					  }

 					| declaration_specifiers declarator compound_statement
 					  {
 					  	//backpatch
 					  	backpatch($3->l, currAddr()+1);

 					  	//function definition has ended, so pop it
						Stables.pop();
 					  	printf("function_definition =>declaration_specifiers declarator compound_statement\n");
 					  }
 					;

declaration_list : declaration {printf("declaration_list => declaration\n");}
				 | declaration_list declaration {printf("declaration_list => declaration_list declaration\n");}
				 ;

/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */



declaration : declaration_specifiers init_declarator_list ';' {printf("declaration => declaration_specifiers init_declarator_list ;\n");}
              | declaration_specifiers ';' {printf("declaration => declaration_specifiers ;\n");}
              ;

declaration_specifiers : type_specifier declaration_specifiers {printf("declaration_specifiers => type_specifier declaration_specifiers\n");}
                       | type_specifier {printf("declaration_specifiers => type_specifier\n");}
                       ;

init_declarator_list : init_declarator  {printf("init_declarator_list => init_declarator\n");}
                     | init_declarator_list ',' init_declarator {printf("init_declarator_list => init_declarator_list , init_declarator\n");}
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
				  	//cout << $1 -> size << endl;
				  	printf("init_declarator => declarator\n");
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
                  		//cout << s << endl;
                  		$$ = Stables.top()->lookup($1);
                  		quadArr.emit(OP_eq,s,$1->name);
                  		mat_init.clear();
                  		(($$ -> initial).name).names = new char[s.size()+1];
                  		strcpy ((($$ -> initial).name).names, s.c_str());
                  		(($$ -> initial).name).d = s.size()+1;
                  		
                  	}
                  	$1 -> is_initialized = true;
                  	printf("init_declarator => declarator = initializer\n");
                  }
                ;

type_specifier : VOID 
				 {

				 	//save current type
					t.bt = void_type;
					t.size = 0;
					printf("type_specifier : void\n");
				 }
				| CHAR
				  {
				    //save current type
					t.bt = char_type;
					t.size = 1;
					printf("type_specifier : char\n");
				  }
				| SHORT {printf("type_specifier : short\n");}
				| INT  
				  {
				  	//save current type
				  	t.bt = int_type;
				  	t.size = 4;

					printf("type_specifier : int\n");
				  }
				| LONG  {printf("type_specifier : long\n");}
				| FLOAT  {printf("type_specifier : float\n");}
				| DOUBLE  
				  {
				  	//save current type
				  	t.bt = double_type;
				  	t.size = 8;
				  	printf("type_specifier : double\n");
				  }
				| MATRIX  
				  {
				  	//save current type
				  	t.bt = matrix_type;
				  	t.size = 0;
				  	printf("type_specifier : Matrix\n");
				  }
				| SIGNED  {printf("type_specifier : signed\n");}
				| UNSIGNED {printf("type_specifier : unsigned\n");}
				| BOOL {printf("type_specifier : Bool\n");}
				 ;

declarator : direct_declarator 
			{

				printf("declarator => direct_declarator\n");


			}
		   | pointer direct_declarator 
		   	{

				$$ = $2;

		   		printf("declarator => pointer direct_declarator \n");

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
						
						cout << "direct_declarator => IDENTIFIER" <<endl;
					}
				  | '(' declarator ')' {printf("direct_declarator => (declarator)\n");}
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
				  		
				  		printf("direct_declarator => direct_declarator [assignment_expression]\n");
				  	}
				  | direct_declarator '[' ']' '[' ']'   
				  	{
				  		printf("direct_declarator => direct_declarator []\n");
				  	}
				  | direct_declarator gensymT '(' parameter_type_list ')' 
				  	{
				  		$$ = $2;
				  		printf("direct_declarator => direct_declarator (parameter_type_list)\n");
				  	}
				  | direct_declarator gensymT '(' identifier_list ')' 
				  	{
				  		$$ = $2;
				  		printf("direct_declarator => direct_declarator (identifier_list)\n");
				  	}
				  | direct_declarator gensymT '(' ')' 
				  	{
				  		$$ = $2;

				  		printf("direct_declarator => direct_declarator ()\n");

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

					printf("pointer => *\n");
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
		 		printf("pointer => * pointer\n");
		 	}
		 ;

parameter_type_list : parameter_list {printf("parameter_type_list => parameter_list\n");};

parameter_list : parameter_declaration {printf("parameter_list => parameter_declaration\n");}
			   | parameter_list ',' parameter_declaration {printf("parameter_list => parameter_list ',' parameter_declaration\n");}
			   ;

parameter_declaration : declaration_specifiers declarator 
						{
							//Save the types into symbol tables 
							Stables.top() -> lookup($2);

							(Stables.top()-> f)->typelist.push_back(t);
							printf("parameter_declaration => declaration_specifiers declarator\n");
						}
					  | declaration_specifiers {printf("parameter_declaration => declaration_specifiers\n");}
					  ;

identifier_list : IDENTIFIER  {printf("identifier_list => IDENTIFIER \n");}
				| identifier_list ',' IDENTIFIER  {printf("identifier_list => identifier_list , IDENTIFIER \n");}
				;

initializer : assignment_expression
			  {
			  	//Store the initial values of a matrix in initialization phase
			  	if(a_matrix)
			  	{
			  		cout << "here and here " << ($1 -> initial).double_initial <<endl;
			  		mat_init.push_back(($1 -> initial).double_initial);
			  	} 

			  	$$ = $1;
				printf("initializer => assignment_expression\n");
			  }
			| '{' initializer_row_list '}' 
			   {
			   		$$ = $2;
			   		a_matrix = false;
			   		printf("initializer => {initializer_row_list}\n");
			   }
			;

initializer_row_list : initializer_row  {printf("initializer_row_list => initializer_row\n");}
					 | initializer_row_list ';' initializer_row {printf("initializer_row_list => initializer_row_list ; initializer_row\n");}
					 ;

initializer_row : initializer  {printf("initializer_row => initializer\n");}
				| designation initializer {printf("initializer_row => designation initializer\n");}
				| initializer_row ',' initializer 
				  {printf("initializer_row =>  initializer_row , initializer\n");}
				;

designation : designator_list '='   {printf("designation => designator_list =\n");} ;

designator_list : designator  {printf("designator_list => designator\n");}
				| designator_list designator {printf("designator_list => designator_list designator\n");}
				;

designator : '[' constant_expression ']' {printf("designator => [constant_expression]\n");}
		   | '.' IDENTIFIER {printf("designator => . IDENTIFIER\n");}
		   ;


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 



primary_expression : IDENTIFIER 
					{
						//cout <<"here"<<endl;
						//Lookup for the identifier in top most symbol table
						//i.e in the present scope

						$$ = Stables.top()->lookup($1 -> name);
						$$ = new symbol_entry(*$$);
						//($$ -> entry_type).getbasetype();
						printf("primary_expression => IDENTIFIER\n");
					}
                   	|CONSTANT   {cout <<"here"<<endl;
                   					printf("primary_expression => CONSTANT\n");}
			        |STRINGLITERAL {printf("primary_expression => STRINGLITERAL\n");}
			        |'('expression')' 
			          {
    					$$ = $2;
    					printf("primary_expression => (expression)\n");
    				  }
			        ;

postfix_expression : primary_expression  {$$ =  $1;printf("postfix_expression => primary_expression \n");}
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

                   	  	printf("postfix_expression => IDENTIFIER[expression][expression]\n");
                   	  }
			        | postfix_expression '(' argument_expression_list ')' 
			          {
			          	//calls function
			          		cout <<"yes"<<endl;
			          	$3 -> method($1);
						$$ = $1;
			          	printf("postfix_expression => postfix_expression (argument_expression_list) \n");

			          }
			        | postfix_expression '(' ')' {printf("postfix_expression => postfix_expression () \n");}
			        | postfix_expression '.' IDENTIFIER  {printf("postfix_expression => postfix_expression . IDENTIFIER \n");}
			        | postfix_expression ACCESS IDENTIFIER {printf("postfix_expression => postfix_expression -> IDENTIFIER \n");}
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
			          		printf("postfix_expression => postfix_expression ++\n");
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
			          		printf("postfix_expression => postfix_expression --\n");
			          }
			        | postfix_expression TRANSPOSE 
			          {
			          	//adds the transpose to the quad
			          	quadArr.emit(OP_transpose,$1 -> name,$$ -> name);
			          	printf("postfix_expression => postfix_expression .'\n");
			          }
			        ;

argument_expression_list : assignment_expression  
						   {
						   		//initiates function utitlity
						   		$$ = new func_utility();
								($$ -> l).push_back($1);
						   		printf("argument_expression_list => assignment_expression \n");
						   }
                         | argument_expression_list ',' assignment_expression  
                           {
                           		//adds the parameters
                           		($1 -> l).push_back($3);
								$$ = $1;
                           		printf("argument_expression_list => argument_expression_list , assignment_expression\n");

                           }
                         ;

unary_expression : 	postfix_expression   
					{
						if($1 -> is_matrix) $$ -> is_matrix = true;
						printf("unary_expression => postfix_expression  \n");
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
                 	  	printf("unary_expression => ++ unary_expression  \n");
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
		        	  	printf("unary_expression => -- unary_expression \n");
		        	  }
		        	| ADDR cast_expression
		        	  {
		   
		        	  	type ty = ($2-> entry_type);
		        	  	
		        	  	type typee;
		        	  	typee.bt = pointer_type;
		        	  	typee.size = 4;
		        	  	typee.actual_type = &ty;
						
						
						$$ = Stables.top() -> gentemp(typee);
						quadArr.emit(OP_addr , $2-> name , $$ -> name);

		        	  	printf("unary_expression => & cast_expression\n");

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
						
		        	  	printf("unary_expression => * cast_expression\n");
		        	  }
		        	| '+' cast_expression 
		        	  {
		        	  	convBool2Int($2);
						$$ = $2;
		        	  	printf("unary_expression => + cast_expression\n");
		        	  }
		        	| '-' cast_expression 
		        	  {
		        	  	convBool2Int($2);
						$$ = Stables.top() -> gentemp($2 -> entry_type);
						quadArr.emit(OP_uminus, $2-> name,$$ -> name);
		        	  	printf("unary_expression => - cast_expression\n");
		        	  }
		        	;

cast_expression :	 unary_expression 
					{
						$$ = $1;
						printf("cast_expression => unary_expression\n");

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

multiplicative_expression : cast_expression {printf("multiplicative_expression => cast_expression\n");}
							| nonbool_multiplicative_expression '*' nonbool_cast_expression 
							 {
							 	//multiplies
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
							 	printf("multiplicative_expression => multiplicative_expression * cast_expression \n");
							 }
							| nonbool_multiplicative_expression '/' nonbool_cast_expression 
							  {
							  	//divides
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
							  	printf("multiplicative_expression => multiplicative_expression / cast_expression\n");
							  }
							| nonbool_multiplicative_expression '%' nonbool_cast_expression 
							  {
							  	//calculates mod
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
							  	printf("multiplicative_expression => multiplicative_expression %% cast_expression\n");
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

additive_expression : multiplicative_expression {printf("additive_expression => multiplicative_expression\n");}
                    | nonbool_additive_expression '+' nonbool_multiplicative_expression 
                      {
                      	//adds
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
							
                      	printf("additive_expression => additive_expression + multiplicative_expression\n");
                      }
        			| nonbool_additive_expression '-' nonbool_multiplicative_expression 
        			  {
        			  	//subtracts
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
						
        			  	printf("additive_expression => additive_expression - multiplicative_expression\n");
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

shift_expression : additive_expression {printf("shift_expression => additive_expression\n");}
                 | shift_expression SHLL additive_expression 
                   {
                   		//shifts left
                   		typecheck($1, $3);
						$$ = Stables.top() -> gentemp($1 -> entry_type);
						quadArr.emit(OP_shl, $1 -> name, $3 -> name,$$ -> name);
                   		printf("shift_expression => shift_expression << additive_expression\n");
                   }
        		 | shift_expression SHRL additive_expression 
        		   {
        		   		//shifts right
        		   		typecheck($1, $3);
						$$ = Stables.top() -> gentemp($1 -> entry_type);
						quadArr.emit(OP_shr, $1 -> name, $3 -> name,$$ -> name);
        		   		printf("shift_expression => shift_expression >> additive_expression\n");
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

relational_expression : shift_expression {printf("relational_expression => shift_expression\n");}
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
                       		printf("relational_expression => relational_expression < shift_expression\n");
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
			            	printf("relational_expression => relational_expression > shift_expression\n");
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
			          		printf("relational_expression => relational_expression <= shift_expression\n");
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
			          		printf("relational_expression => relational_expression >= shift_expression\n");
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

equality_expression : relational_expression {printf("equality_expression => relational_expression\n");}
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
                      	printf("equality_expression => equality_expression == relational_expression\n");
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
        			  	printf("equality_expression => equality_expression != relational_expression\n");
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

AND_expression : equality_expression {printf("AND_expression => equality_expression\n");}
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
               		printf("AND_expression => AND_expression & equality_expression\n");
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

exclusive_OR_expression : AND_expression  {printf("exclusive_OR_expression => AND_expression\n");}
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
						  	printf("exclusive_OR_expression => exclusive_OR_expression ^ AND_expression\n");
						  }
                        ;

inclusive_OR_expression : exclusive_OR_expression {printf("inclusive_OR_expression => exclusive_OR_expression\n");}
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
                          	printf("inclusive_OR_expression => inclusive_OR_expression | exclusive_OR_expression \n");
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



logical_AND_expression : inclusive_OR_expression  {printf("logical_AND_expression => inclusive_OR_expression\n");}
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

                       		printf("logical_AND_expression => logical_AND_expression && inclusive_OR_expression\n");
                       	 }
                       ;

logical_OR_expression : logical_AND_expression {printf("logical_OR_expression => logical_AND_expression\n");}
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
                      		printf("logical_OR_expression => logical_OR_expression || logical_AND_expression\n");
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

conditional_expression : logical_OR_expression {printf("conditional_expression => logical_OR_expression\n");}
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
                       	 	printf("conditional_expression => logical_OR_expression ? expression : conditional_expression\n");
                       	 }
                       	;

assignment_expression : conditional_expression {printf("assignment_expression => conditional_expression\n");}
                      | unary_expression assignment_operator assignment_expression 
                      	{
                      		convBool2Int($3);
							typecheck($3,$1);
							if($1 -> is_matrix && is_offset)
							{
								quadArr.emit( OP_mateq,$1 -> matoffset,$3->name, $1 -> name);
							}

							if($3 -> is_matrix && is_offset)
							{
								quadArr.emit( OP_eqmat,$3 -> name,$3->matoffset, $1 -> name);
							}

							else 
							{
								quadArr.emit( OP_eq , $3 -> name, $1 -> name);
							}
							$$ = $1;
							is_offset = false;
                      		printf("assignment_expression => unary_expression assignment_operator assignment_expression \n");
                      	}
                      ;

assignment_operator : '=' {printf("assignment_operator => =\n");}
					 | ASSNMUL {printf("assignment_operator => *=\n");} 
					 | ASSNDIV {printf("assignment_operator => /=\n");} 
					 | ASSNMOD {printf("assignment_operator => %%=\n");} 
					 | ASSNADD {printf("assignment_operator => +=\n");} 
					 | ASSNSUB {printf("assignment_operator => -=\n");} 
					 | ASSNSHLL {printf("assignment_operator => <<=\n");} 
					 | ASSNSHRL {printf("assignment_operator => >>=\n");} 
					 | ASSNBINAND {printf("assignment_operator => &=\n");}
					 | ASSNXOR {printf("assignment_operator => ^=\n");}
					 | ASSNBINOR {printf("assignment_operator => |=\n");}
					 ;

expression : assignment_expression {printf("expression => assignment_expression\n");}
           | expression ',' assignment_expression {printf("expression => expression , assignment_expression\n");}
           ;

constant_expression : conditional_expression {printf("constant_expression => conditional_expression\n");} ;





/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */



statement : labeled_statement  {printf("statement => labeled_statement\n");}
		  | compound_statement {printf("statement => compound_statement\n");}
		  | expression_statement {printf("statement => expression_statement\n");}
		  | selection_statement	{printf("statement => selection_statement\n");}
		  | iteration_statement	{printf("statement => iteration_statement\n");}
		  | jump_statement	{printf("statement => jump_statement\n");}
		  ;

labeled_statement : IDENTIFIER ':' statement {printf("labeled_statement => IDENTIFIER : statement\n");}
				  | CASE constant_expression ':' statement {printf("labeled_statement => case constant_expression : statement\n");}
				  | DEFAULT ':' statement {printf("labeled_statement => default statement\n");}
				  ;

compound_statement : '{' '}'  
					  {
					  	$$ = new nextlist();
					  	printf("compound_statement : {}\n");
					  }
				   | '{' block_item_list '}'	
				   	  {
				   	  	$$ = $2;
				   	  	printf("compound_statement : {block_item_list}\n");
				   	  }
				   ;

block_item_list : block_item  {printf("block_item_list => block_item\n");}
				| block_item_list M block_item 
				  {
				  	//previous block is backpatched to current block
				  	backpatch($1->l, $2);
					$$ = $3;
				  	printf("block_item_list => block_item_list block_item\n");
				  }
				;

block_item : declaration 
			{
				$$ = new nextlist();
				printf("block_item => declaration\n");
			}
		   | statement {printf("block_item => statement\n");}
		   ;

expression_statement : ';' 
						{
							$$ = new nextlist();
							printf("expression_statement => ;\n");
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
							printf("expression_statement => expression ;\n");
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
					  	printf("selection_statement => if (bool_exp) statement\n");
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

					  	printf("selection_statement => if (bool_exp) statement else statement\n");
					  }
					| SWITCH '(' bool_exp ')' statement {printf("selection_statement => switch (expression) statement\n");}
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

expression_opt : expression {printf("expression_opt => expression\n");}
			   | {
			   		$$ = NULL;
			   		printf("expression_opt => epsilon\n");
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

					  	printf("iteration_statement => while (expression) statement \n");
					  }
					| DO M statement WHILE '(' M bool_exp ')' ';' 
					{
						// N has instruction number of next goto
					  	// M has number of next instruction
						backpatch($7 -> truelist, $2);
						backpatch($3 -> l , $6);
						$$ = new nextlist();
						$$ -> l = $7 -> falselist;
						printf("iteration_statement => do statement while (expression);\n");
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

					  	printf("iteration_statement => for (expression_opt ; expression_opt ; expression_opt) statement\n");
					  }
					| FOR '(' declaration expression_opt';' expression_opt ')' statement 
					  {printf("iteration_statement => for(declaration expression_opt; expression_opt) statement\n");}
					;

jump_statement : GOTO IDENTIFIER ';' {printf("jump_statement => goto IDENTIFIER ;\n");}
			   | CONTINUE ';' {printf("jump_statement => continue;\n");}
			   | BREAK ';' {printf("jump_statement => break;\n");}
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

			     	printf("jump_statement => return expression_opt ;\n");
			     }
			   ;


/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */





%%

void yyerror (char const *s) {
   fprintf (stdout, "%s\n", s);
 }