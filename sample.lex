digit [0-9] 
keyword     [unsigned|break|return|void|case|float|short|char|for|signed|while|goto|Bool|continue|if|default|do|int|switch|double|long|else|Matrix]
identifier-nondigit [A-Za-z]
zero-constant [0]
nonzero-digit [1-9]
sign ["+"|"-"]
escape-sequence [\'|\"|\?|\\|\a|\b|\f|\n|\r|\t|\v]
any [^(\'|\\|\n)]
dot ["\."]
B (({digit}+)?){dot}({digit}+)|({digit}+{dot})


%{ 
    
    #define KEYWORD 1;
    #define IDENTIFIER 2;
    #define CONSTANT 3;
    #define STRINGLITERAL 4;
    #define PUNCTUATOR 5; 

    int count = 0;
    int comment();
%} 

%% 


unsigned|break|return|void|case|float|short|char|for|signed|while|goto|Bool|continue|if|default|do|int|switch|double|long|else|Matrix   printf("%d ",1);//return KEYWORD;
"\"(({any}{escape-sequence})+)?\""    printf("%d ",4);//return STRINGLITERAL;
{identifier-nondigit}({identifier-nondigit}|{digit})* printf("%d ",2);//return IDENTIFIER;
{zero-constant}|({nonzero-digit}({digit})*)|('(({any}{escape-sequence})+)')|(({B}|({digit}+))(('e'|'E')({sign}+)({digit}+))|{B}) printf("%d ",3);//return CONSTANT;
"[]"|"()"|"."|"->"|"++"|"+"|"--"|"-"|"&"|"*"|"~"|"!"|"/"|"%"|"<<"|"<"|">>"|">"|"<="|">="|"=="|"="|"!="|"^"|"|"|"&&"|"||"|"?"|":"|";"|"*="|"\="|"%="|"+="|"-="|"<<="|">>="|"&="|"^="|"|="|","|"#"|"'" printf("%d ",5);//return PUNCTUATOR;
"\/\*"         {comment();}
"//"[^\n]*  /*return COMMENTS;*/

%% 

int main(void)
{ 
    yylex();  
    return 0; 
} 

int comment()
{
    char c, prev = 0;
  
    while ((c = input()) != 0)      /* (EOF maps to 0) */
    {
        if (c == '/' && prev == '*') printf("comments");
            //return COMMENTS;
        prev = c;
    }
    printf("unterminated comment ");
}