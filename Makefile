a.out: fake lex.yy.o y.tab.o ass5_15CS30042_translator.o ass5_15CS30042_target_translator.o
	g++ lex.yy.o y.tab.o ass5_15CS30042_translator.o ass5_15CS30042_target_translator.o -lfl
fake:	ass5_15CS30042.o
	ar -rcs libass5.a ass5_15CS30042.o
ass5_15CS30042.o:	ass5_15CS30042.c myl.h
	gcc -c ass5_15CS30042.c
ass5_15CS30042_target_translator.o: ass5_15CS30042_target_translator.cxx ass5_15CS30042_translator.h
	g++ -c -g ass5_15CS30042_target_translator.cxx
ass5_15CS30042_translator.o: ass5_15CS30042_translator.h ass5_15CS30042_translator.cxx
	g++ -c -g ass5_15CS30042_translator.cxx
lex.yy.o: 	lex.yy.c
	g++ -c -g lex.yy.c
y.tab.o: 	y.tab.c
	g++ -c -g y.tab.c
lex.yy.c: 	ass5_15CS30042.l y.tab.h ass5_15CS30042_translator.h
	flex ass5_15CS30042.l
y.tab.c: 	ass5_15CS30042.y
	yacc -dtv ass5_15CS30042.y
y.tab.h: 	ass5_15CS30042.y ass5_15CS30042_translator.h
	yacc -dtv ass5_15CS30042.y

clean:
	rm lex.yy.c y.tab.h y.tab.c lex.yy.o y.tab.o a.out y.output ass5_15CS30042_translator.o ass5_15CS30042_target_translator.o libass5.a ass5_15CS30042.o