%{
  	#define YYPRINT
    
    #include <iostream>
    #include <vector>
    #include "ass5_15CS30042_translator.h"
    #include "y.tab.h"
    int getTokenTypeCode(char* tbuff);

    using namespace std;

    int count = 0;
    int comment();
    vector<string> StringSet;
    vector<double> doubleSet;
   

%}

%option noyywrap

digit [0-9]
identifier_nondigit [A-Za-z_]
zero_constant [0]
nonzero_digit [1-9]
sign [+-]
escape_sequence \\'|\\\?|\\\\|\\a|\\b|\\f|\\n|\\r|\\t|\\v
any [^\'\\\n]
dot \.
B (({digit}+)?){dot}({digit}+)|({digit}+{dot})
keyword unsigned|break|return|void|case|float|short|char|for|signed|while|goto|Bool|continue|if|default|do|int|switch|double|long|else|Matrix
punc \[|\]|\(|\)|\{|\}|\.|-\>|\+\+|--|&|\*|\+|-|~|!|\/|%|\<\<|\>\>|\<|\>|\<=|\>=|==|!=|\^|\||&&|\|\||\?|:|;|=|\*=|\/=|%=|\+=|-=|\<\<=|\>\>=|&=|\^=|\|=|,|#|\.'
identify {identifier_nondigit}({identifier_nondigit}|{digit})*
integer_constant {nonzero_digit}({digit})*
cchar [^']|{escape_sequence}
schar [^"]|{escape_sequence}
scharsequence {schar}+
ccharsequence {cchar}+
floating_constant ({B}|({digit}+))([eE]({sign}?)({digit}+))|{B}
integer {zero_constant}|{integer_constant}
float {floating_constant}
characterconstant '{ccharsequence}'
stringliteral \"{scharsequence}?\"


%%

[ \t\n]+    {/*whitespace do nothing */}

{keyword}	{
        if(strcmp(yytext,"unsigned") == 0)  return UNSIGNED;
        if(strcmp(yytext,"break") == 0)     return BREAK;
        if(strcmp(yytext,"return") == 0)    return RETURN;
        if(strcmp(yytext,"void") == 0)      return VOID;
        if(strcmp(yytext,"case") == 0)      return CASE;
        if(strcmp(yytext,"float") == 0)     return FLOAT;
        if(strcmp(yytext,"short") == 0)     return SHORT;
        if(strcmp(yytext,"char") == 0)      return CHAR;
        if(strcmp(yytext,"for") == 0)       return FOR;
        if(strcmp(yytext,"signed") == 0)    return SIGNED;
        if(strcmp(yytext,"while") == 0)     return WHILE;
        if(strcmp(yytext,"goto") == 0)      return GOTO;
        if(strcmp(yytext,"Bool") == 0)      return BOOL;
        if(strcmp(yytext,"continue") == 0)  return CONTINUE;
        if(strcmp(yytext,"if") == 0)        return IF;
        if(strcmp(yytext,"default") == 0)   return DEFAULT;
        if(strcmp(yytext,"do") == 0)        return DO;
        if(strcmp(yytext,"int") == 0)       return INT;
        if(strcmp(yytext,"switch") == 0)    return SWITCH;
        if(strcmp(yytext,"double") == 0)    return DOUBLE;
        if(strcmp(yytext,"else") == 0)      return ELSE;
        if(strcmp(yytext,"long") == 0)      return LONG;
        if(strcmp(yytext,"Matrix") == 0)    return MATRIX;
       
}

{identify}  {
                yylval.symbol = new symbol_entry(string(yytext));
                return IDENTIFIER;
            }

{integer} {
            type typee;
            typee.bt = int_type;
            typee.size = 4;
            typee.actual_type = NULL;
            yylval.symbol = Stables.top()->gentemp(typee);
            yylval.symbol -> initial.int_initial = atoi(yytext);
            quadArr.emit(OP_eq, string(yytext),yylval.symbol->name);
            return CONSTANT;
          }

{characterconstant} {
                        type typee;
                        typee.bt = char_type;
                        typee.size = 1;
                        yylval.symbol = Stables.top()->gentemp(typee);
                        quadArr.emit(OP_eq, string(yytext),yylval.symbol->name); 
                        return CONSTANT;
                    }

{float} {
            type typee;
            typee.bt = double_type;
            typee.size = 8;
            typee.actual_type = NULL;
            yylval.symbol = Stables.top()->gentemp(typee);
            yylval.symbol -> initial.double_initial = atof(yytext);
            quadArr.emit(OP_eq, string(yytext),yylval.symbol->name);
            doubleSet.push_back(conv2double(string(yytext))) ;
            return CONSTANT;
        }

{stringliteral}    {StringSet.push_back(string(yytext)) ;return STRINGLITERAL;}

{punc}	{
    if(strcmp(yytext,"->") == 0) return ACCESS;
    if(strcmp(yytext,"++") == 0) return INCR;
    if(strcmp(yytext,"--") == 0) return DECR;
    if(strcmp(yytext,"<<") == 0) return SHLL;
    if(strcmp(yytext,">>") == 0) return SHRL;
    if(strcmp(yytext,"<=") == 0) return LTE;
    if(strcmp(yytext,">=") == 0) return GTE;
    if(strcmp(yytext,"==") == 0) return EQ;
    if(strcmp(yytext,"!=") == 0) return NEQ;
    if(strcmp(yytext,"&&") == 0) return LOGAND;
    if(strcmp(yytext,"||") == 0) return LOGOR;
    if(strcmp(yytext,"*=") == 0) return ASSNMUL;
    if(strcmp(yytext,"/=") == 0) return ASSNDIV;
    if(strcmp(yytext,"%=") == 0) return ASSNMOD;
    if(strcmp(yytext,"+=") == 0) return ASSNADD;
    if(strcmp(yytext,"-=") == 0) return ASSNSUB;
    if(strcmp(yytext,"<<=") == 0) return ASSNSHLL;
    if(strcmp(yytext,">>=") == 0) return ASSNSHRL;
    if(strcmp(yytext,"&=") == 0) return ASSNBINAND;
    if(strcmp(yytext,"^=") == 0) return ASSNXOR;
    if(strcmp(yytext,"|=") == 0) return ASSNBINOR;
    if(strcmp(yytext,".'") == 0) return TRANSPOSE;
    if(strcmp(yytext,"&") == 0) return ADDR;

    return yytext[0];
}

[/][*][^*]*[*]+([^*/][^*]*[*]+)*[/]       { /*printf("\ncomments\n\n");*/ }
[/][*]                                    {/* printf("Unterminated comment\n"); */}

"//"[^\n]*  {/*printf("\ncomments\n\n");*/}


%%
