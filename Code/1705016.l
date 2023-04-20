%{
#include<iostream>
#include<stdlib.h>
#include<string.h>
#include "SymbolTable.h"

// #define YYSTYPE SymbolInfo*
//R016
#include "y.tab.h"


using namespace std;

extern YYSTYPE yylval;
extern SymbolTable *table;
extern int errorCount; 
extern int syntaxErrorCount; 
extern ofstream logFile;
extern ofstream errorFile;

void yyerror(char *);

int lineNumber = 1;

void newLineFound()
{
	lineNumber++; 
}


%}



digit [0-9]
LETTER [A-Za-z]
delim [ \t\r\f\v]

ws [delim]+

integer {digit}+
number {digit}*(\.{digit}+)?(E[+-]?{digit}+)?

WHITESPACE [ \t\f\r\v]+
NEWLINE \r?\n
AlphaNumeric [a-zA-Z0-9]

DIGIT [0-9]



MULTIPLE_DIGITS {DIGIT}+


EXPONENTIAL_FLOAT ([Ee][+-]?{MULTIPLE_DIGITS})

/*  Numbers like 3.14159, 3.14159E-10, .314159 and 314159E10 */ 
/* ? = either 0 or 1 times   */ 

/* 23; 23E11 */ 
FLOAT_TYPE0 ({MULTIPLE_DIGITS})({EXPONENTIAL_FLOAT})?

FLOAT_TYPE1 ({MULTIPLE_DIGITS}\.{MULTIPLE_DIGITS})
FLOAT_TYPE2  ({MULTIPLE_DIGITS}\.{MULTIPLE_DIGITS})({EXPONENTIAL_FLOAT})

FLOAT_TYPE3 (\.{MULTIPLE_DIGITS})
FLOAT_TYPE4 (\.{MULTIPLE_DIGITS})({EXPONENTIAL_FLOAT})
CONSTANT_FLOAT ({FLOAT_TYPE0}|{FLOAT_TYPE1}|{FLOAT_TYPE2}|{FLOAT_TYPE3}|{FLOAT_TYPE4})





/* Too many decimal point : simple FIRST e ekta decimal point er pattern */ 

ONE_DECIMAL_POINT1 ({MULTIPLE_DIGITS}\.{MULTIPLE_DIGITS})
ONE_DECIMAL_POINT2 (\.{MULTIPLE_DIGITS})

/* simply ONE_DECIMAL_POINT 2ta way te hote pare :           23.45     or .45  */ 

ONE_DECIMAL_POINT {ONE_DECIMAL_POINT1}|{ONE_DECIMAL_POINT2}


MORE_THAN_TWO_DECIMAL ({ONE_DECIMAL_POINT})({ONE_DECIMAL_POINT})+

/* ONE_DECIMAL_POINT : 2nd ta + diyesi; NOT *; karon at least ekbar to ghota uchit */ 




/*  1E10.7 Ill formed number */ 

/* simply ILL Formed = E er pore jodi again float ashe */ 

/* 1E10.5     1.2E10.5       .2E10.5  all three are ill formed */ 

/* another thing: E er por +- allow kora jete pare */ 

BEFORE_EXPONEN0  ({MULTIPLE_DIGITS})
BEFORE_EXPONEN1 ({MULTIPLE_DIGITS}\.{MULTIPLE_DIGITS})
BEFORE_EXPONEN2 (\.{MULTIPLE_DIGITS})


BEFORE_EXPONEN {BEFORE_EXPONEN0}|{BEFORE_EXPONEN1}|{BEFORE_EXPONEN2}

/* 1 ; 1.2 ; .2 3ta way te */ 

EXPONEN_PLUS_MINUS ([Ee][+-]?)


/* simply E er pore FLOAT pelei problem */ 


ILL_FORMED_NUMBER_ERROR {BEFORE_EXPONEN}{EXPONEN_PLUS_MINUS}({CONSTANT_FLOAT})

ID_EXCEPT_FIRST_CHAR (_|{LETTER}|{DIGIT})

ID [A-Z_a-z]{ID_EXCEPT_FIRST_CHAR}*


INVALID_SUFFIX_IDENTIFIER {MULTIPLE_DIGITS}[A-Z_a-z0-9]*


/* CHAR 											*/ 
PRINTABLE_CHAR_WITHOUT_SINGLE_QUOTE ([ -~]{-}['\\])
ESCAPE_CHAR_WITHOUT_SINGLE_QUOTE (\\[nt\\afbrv0\"])

CONST_CHAR_WITHOUT_QUOTE  {PRINTABLE_CHAR_WITHOUT_SINGLE_QUOTE}|{ESCAPE_CHAR_WITHOUT_SINGLE_QUOTE}

MULTIPLE_CHARACTER_ERROR '{CONST_CHAR_WITHOUT_QUOTE}{2,}'
 
/* 'a        '\t egula first error ei dhora khabe    */ 

UNTERMINATED_CHAR_WITHOUT_UNFINISHED_SINGLE_QUOTE '({PRINTABLE_CHAR_WITHOUT_SINGLE_QUOTE}|{ESCAPE_CHAR_WITHOUT_SINGLE_QUOTE})*

/* '\' eta single quote likhte giye unterminated */ 

UNFINISHED_SINGLE_QUOTE '[\\]'

UNTERMINATED_CHAR_ERROR {UNTERMINATED_CHAR_WITHOUT_UNFINISHED_SINGLE_QUOTE}|{UNFINISHED_SINGLE_QUOTE}



EMPTY_CHAR_ERROR ''

/* operator  */
ADDOP "+"|"-"
MULOP "*"|"/"|"%"
INCOP "++"
DECOP "--"
RELOP "<"|"<="|">"|">="|"=="|"!="
ASSIGNOP "="
LOGICOP "&&"|"||"
NOT	"!"
/* punctuation */
LPAREN	"("
RPAREN ")"
LCURL "{"
RCURL "}"
LTHIRD "["
RTHIRD "]"
COMMA ","
SEMICOLON ";"


%%

{delim}+	{}
{NEWLINE} {newLineFound();}

{MULTIPLE_DIGITS}	{
    SymbolInfo *s= new SymbolInfo(yytext, "CONST_INT");	
	yylval.si = s;
	return CONST_INT;
}
{CONSTANT_FLOAT} {
	SymbolInfo *s= new SymbolInfo(yytext, "CONST_FLOAT");	
	yylval.si = s;
	return CONST_FLOAT;

	}

"int" {
	SymbolInfo *s= new SymbolInfo(yytext, "INT");	
	yylval.si = s;
	return INT;
	}

"float" {
	SymbolInfo *s= new SymbolInfo(yytext, "FLOAT");	
	yylval.si = s;
	return FLOAT;
	}
"void" {
	SymbolInfo *s= new SymbolInfo(yytext, "VOID");	
	yylval.si = s;
	return VOID;
	}



{ADDOP} {
	SymbolInfo *s= new SymbolInfo(yytext, "ADDOP");	
	yylval.si = s;
	
	return ADDOP;
	}
{MULOP} {
	SymbolInfo *s= new SymbolInfo(yytext, "MULOP");	
	yylval.si = s;
	
	return MULOP;
	}
{LOGICOP} {
	SymbolInfo *s= new SymbolInfo(yytext, "LOGICOP");	
	yylval.si = s;
	
	return LOGICOP;
	}
{RELOP} {
	SymbolInfo *s= new SymbolInfo(yytext, "RELOP");	
	yylval.si = s;
	
	return RELOP;
	}

{ASSIGNOP} {
	SymbolInfo *s= new SymbolInfo(yytext, "ASSIGNOP");	
	yylval.si = s;
	
	return ASSIGNOP;
	
	}
{NOT} {
	SymbolInfo *s= new SymbolInfo(yytext, "NOT");	
	yylval.si = s;
	
	return NOT;
}

{INCOP} {
	SymbolInfo *s= new SymbolInfo(yytext, "INCOP");	
	yylval.si = s;
	
	return INCOP;
	
	}

{DECOP} {
	SymbolInfo *s= new SymbolInfo(yytext, "DECOP");	
	yylval.si = s;
	
	return DECOP;
	
	}


"for" {
	SymbolInfo *s= new SymbolInfo(yytext, "FOR");	
	yylval.si = s;
	
	return FOR;

	}
"while" {
	SymbolInfo *s= new SymbolInfo(yytext, "WHILE");	
	yylval.si = s;
	
	return WHILE;

	}

"if" {return IF;}
"else" {return ELSE;}
";" {return SEMICOLON; }
"," {return COMMA;}


"{" {return LCURL;}
"}" {return RCURL;}

"(" {return LPAREN;}
")" {return RPAREN;}

"[" {return LTHIRD;}
"]" {return RTHIRD;}

"println"|"printf"	{return PRINTLN;}
"return"	{return RETURN;}

{INVALID_SUFFIX_IDENTIFIER} 		{
					logFile << "\nError at line " << lineNumber << ": Invalid prefix on ID or invalid suffix on Number "<< yytext<<"\n";
					errorFile << "\nError at line " << lineNumber << ": Invalid prefix on ID or invalid suffix on Number "<< yytext<<"\n";

					/* Error at line no 2: Invalid prefix on ID or invalid suffix on Number 12abcd */ 
					// errorCount++;
					// syntaxErrorCount++; 
					// SymbolInfo *s= new SymbolInfo(yytext, "INVALID_SUFFIX_IDENTIFIER");	
					// yylval.si = s;
					// return ERRORTOKEN;
					}

{ID} 		{	 
				
								
				SymbolInfo *s= new SymbolInfo(yytext, "ID");
				
				yylval.si = s;
				//si decleared in %union 
							
				return ID;
			}

{MORE_THAN_TWO_DECIMAL} {
						logFile << "\nError at line " << lineNumber << ": Too many decimal points "<< yytext<<"\n";
						/* Error at line no 1: Too many decimal points 1.2.345 */
						errorFile<< "\nError at line " << lineNumber << ": Too many decimal points "<< yytext<<"\n";
						// errorCount++;
						// syntaxErrorCount++; 
						// SymbolInfo *s= new SymbolInfo(yytext, "MORE_THAN_TWO_DECIMAL");	
						// yylval.si = s;
						// return ERRORTOKEN;


						}
{MULTIPLE_CHARACTER_ERROR}	{
					logFile << "\nError at line " << lineNumber << ": Multi character constant error "<< yytext<<"\n";
					errorFile << "\nError at line " << lineNumber << ": Multi character constant error "<< yytext<<"\n";
					/* Error at line no 11: Multi character constant error 'ab' */ 
					// errorCount++;
					// syntaxErrorCount++; 
					// SymbolInfo *s= new SymbolInfo(yytext, "MULTIPLE_CHARACTER_ERROR");	
					// yylval.si = s;
					// return ERRORTOKEN;

}

{UNTERMINATED_CHAR_ERROR} {
					logFile << "\nError at line " << lineNumber << ": Unterminated character "<< yytext<<"\n";
					errorFile<< "\nError at line " << lineNumber << ": Unterminated character "<< yytext<<"\n";
					/* Error at line no 12: Unterminated character 'a; */ 
					// errorCount++;
					// syntaxErrorCount++; 
					// SymbolInfo *s= new SymbolInfo(yytext, "UNTERMINATED_CHAR_ERROR");	
					// yylval.si = s;
					// return ERRORTOKEN;

}
{EMPTY_CHAR_ERROR} {
					logFile << "\nError at line " << lineNumber << ": Empty character constant error "<< yytext<<"\n";
					errorFile<< "\nError at line " << lineNumber << ": Empty character constant error "<< yytext<<"\n";
					/* Error at line no 9: Empty character constant error '' */ 
					
					// errorCount++;
					// syntaxErrorCount++; 
					// SymbolInfo *s= new SymbolInfo(yytext, "EMPTY_CHAR_ERROR");	
					// yylval.si = s;
					// return ERRORTOKEN;

}




{ILL_FORMED_NUMBER_ERROR}	{
							
				logFile << "Error at line " << lineNumber << ": Ill formed number "<< yytext<<"\n";
				errorFile << "Error at line " << lineNumber << ": Ill formed number "<< yytext<<"\n";
				/* Error at line 2: Ill formed number 1E10.7 */ 							

				// errorCount++;
				// syntaxErrorCount++; 
				// SymbolInfo *s= new SymbolInfo(yytext, "ILL_FORMED_NUMBER_ERROR");	
				// yylval.si = s;
				// return ERRORTOKEN;

			}
. 			{
			logFile << "Error at line " << lineNumber << ": Unrecognized character "<< yytext<<"\n";
			//	Error at line 10: Unrecognized character #
			errorFile<< "Error at line " << lineNumber << ": Unrecognized character "<< yytext<<"\n";
			// errorCount++;
			// syntaxErrorCount++; 
			// SymbolInfo *s= new SymbolInfo(yytext, "UNRECOGNIZED");	
			// yylval.si = s;
			// return ERRORTOKEN;

			}

%%

int yywrap(void)
{
	return 1;
}





