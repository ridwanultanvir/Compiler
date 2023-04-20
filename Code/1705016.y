%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<bits/stdc++.h> 
#include "SymbolTable.h"
//#define YYSTYPE SymbolInfo*
//R016
using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

extern int lineNumber;

SymbolTable *symTable;
FILE* input;
ofstream logFile;
ofstream errorFile;


ofstream assemblyCodeFile; 

ofstream optimizeCodeFile; 


bool isMainFuncDefined = false; 

int semanticErrorCount = 0; 
int errorCount = 0; 
int syntaxErrorCount = 0; 
//bool insideCompound = false; 

bool isFunctionReturning = false; 
string currentFunctionReturnType; 

string currentFunctionName; 


string typeSpecifierYFile; 
vector<SymbolInfo*> parameterListYFile;
vector<SymbolInfo*> argListYFile;
vector<string> parameterNameYFile; 


vector<string> dataVariables;
string dataVariablesCode;

int temporaryVariableTotal = 0; 

int labelTotal = 0; 

void newTemporaryVariableCodeAdd(string fullVarName1)
{
	
	dataVariables.push_back(fullVarName1);

	string varCode1 = "\t" + fullVarName1 + " dw ?" + "\n";  
	/* 
	simply ami ki chai? 
		t1 dw ?
	*/ 
	dataVariablesCode += varCode1; 

}

string assignopArraySizeRemove(string str)
{
	// str = c12[35] hole ami "c12" return korbo 
	// Find first occurrence of "["
	string str1 = "["; 
    size_t found = str.find(str1);
    if (found != string::npos)
    {
		int pos = found; 
		cout<<"pos:"<<pos<<"\n"; 
		string str2 = str.substr(0, pos);
		return str2; 
	}
	return str; 
}


string newTemporaryVariable()
{

	temporaryVariableTotal++; 
	// so t1 theke start hobe 
	string newVar1 = "t"; 
	std::string str = std::to_string(temporaryVariableTotal);

	newVar1 += str; 
	return newVar1; 

}

string newLabelAdd()
{
	labelTotal++; 
	string newLabel1 = "LABEL"; 
	std::string str = std::to_string(labelTotal);
	newLabel1 += str; 
	return newLabel1 ; 


}


int numberOfDigitInFloat(float val)
{
	stringstream ss; 
	ss << abs(val-(int)val); 
	string s; 
	ss >> s; 
	int len = s.length()-2; 
	return len; 	
}

//from src: 
void splitStringFunc(const string &s, const char mydelim,vector<string> &stringTokenized)
{
    std::string::size_type startIdx = 0;
    for (auto endIdx = 0; (endIdx = s.find(mydelim, endIdx)) != std::string::npos; ++endIdx)
    {
        stringTokenized.push_back(s.substr(startIdx, endIdx - startIdx));
        startIdx = endIdx + 1;
    }
 
    stringTokenized.push_back(s.substr(startIdx));
}

bool isMoveInstruction(string str)
{
	if(str.size()!=3){
		return false; 
	}

	if(str=="MOV"|| str=="mov" || str=="Mov"){
		return true; 
	}
}


bool checkBothMoveInstruction(string str1 , string str2)
{
	if(str1.size()>=4  && str2.size()>=4){

		string instructionName1 = str1.substr(1,3); 
			//why (1,3) karon "\tmov" \t diye line shuru 
		string instructionName2 = str2.substr(1,3); 


		bool bothMove = isMoveInstruction(instructionName1) && isMoveInstruction(instructionName2); 

		return bothMove; 

	}
	return false; 
}


bool isSkipCode(string str1, string str2)
{
	//khali "\n" or "\n\t" or "\n\n\t" or "\n\t\t"... thakle ignored ; 
	//MOV ; JE egulao at least 4 length 
	if(str1.length()<=1 || str2.length() <=1){
		return true; 
	}
	return false; 
}
/*
vector<string>& skipCodeVector(vector<string> vec)
{
	vector<string> output ; 
	int n = vec.size(); 

	for(int i=0; i<n-1; i++){
		string str = vec[i]; 

		int len1 = vec[i].length(); 

		if(len1>=4){
			output.push_back(str); 

		}
		else{
			cout<<"line :"<<i+1<<" skipped\n"; 
		}
	}
	return output ;
}
---fault 
*/

void optimizeAsmCode(string asmCode1)
{
	vector <string> listCode1;

    char separator = '\n';
    splitStringFunc(asmCode1, separator, listCode1); 

	cout<<listCode1.size()<<"\n"; 

	vector <string> lineCodeList; 


	int size1 = listCode1.size(); 

	//string after_optimize_code = ""; 

	for(int i=0; i<size1-1; i++) {

		string str = listCode1[i]; 
		int len1 = listCode1[i].length(); 
		if(len1<4){
			//cout<<"\nline skipped: Line:"<<i+1<<"\n"; 
		}
		else{
			lineCodeList.push_back(str); 
		}

	}
	listCode1.clear(); 

	cout<<lineCodeList.size()<<"\n"; 
	int asm_line_number = lineCodeList.size(); 

	//string after_optimize_code = ""; 
	

	//asm_line_number-1 keno? karon ami lineCodeList[i+1] check korsi; so out of bound e jabe 
	for(int i=0; i<asm_line_number-1; i++) {
		
		string instruc1 = lineCodeList[i]; 
		string instruc2 = lineCodeList[i+1]; 



		bool isBothMove = checkBothMoveInstruction(instruc1, instruc2); 


		if(isBothMove){
			//cout<<"\nboth Move instruction for : \tinstruc1:"<<instruc1<<"\n\t\t\t\tinstruc2 :"<<instruc2<<"\n"; 
			/*
			both Move instruction for :     instruc1:       MOV t1, AX
                                			instruc2 :      MOV AX, t1
			*/
			vector <string> vecInst1;//MOV t1, AX
			vector <string> vecInst2; //MOV AX, t1

			char separator = ' ';
			splitStringFunc(instruc1, separator, vecInst1); 
			splitStringFunc(instruc2, separator, vecInst2);

			/*
			vecInst1.size():3
					MOV
			t1,
			AX

			"\tMOV" purata mile vecInst1[0]
			cout<<"vecInst1.size():"<<vecInst1.size()<<"\n"; 
			for(int i=0; i<vecInst1.size();i++){
				cout<<vecInst1[i]<<"\n"; 
			}
			*/

			
			//"\tMOV"
			if(vecInst1.size()>=3 && vecInst2.size()>=3){
			
				int len1 = vecInst1[1].length()- 1; 
				string moveoperator1 = vecInst1[1].substr(0,len1); // comma bad jabe 
				string moveoperator2 = vecInst2[2]; 
				//cout<<"moveoperator1="<<moveoperator1<<"\n"; 
				
				len1 = vecInst2[1].length()- 1; //AX, paitese 
				string moveoperator3 = vecInst2[1].substr(0,len1); // comma bad jabe 
				string moveoperator4 = vecInst1[2]; 
				

				if((moveoperator3==moveoperator4) && (moveoperator1==moveoperator2)){
					
						// MOV t1, AX
						// MOV AX, t1
						// AX e already oi value ase; so ota ignore
					
					//after_optimize_code += instruc1; 
					optimizeCodeFile<< instruc1<<"\n"; 
					i++; 
					cout<<"skipped code:\ninstruc1:"<<instruc1<<"\ninstruc2:"<<instruc2<<"\n"; 
				}
				else{
					optimizeCodeFile<< instruc1<<"\n"; // NO SKIP 
				}

				//after_optimize_code += instruc1; //but kono skip hosse NA; 
			
			}
			else{
				optimizeCodeFile<< instruc1<<"\n";
				cout<<"vecInst1.size()>=3 && vecInst2.size()>=3 failed\t   instruc1:"<<instruc1<<"\tinstruc2:"<<instruc2<<"\n"; 
				//cout<<"vecInst1.size():"<<vecInst1.size()<<"\tvecInst2.size():"<<vecInst2.size()<<"\n"; 
			}
			vecInst1.clear(); 
			vecInst2.clear(); 	
              

		}
		else{
			optimizeCodeFile<< instruc1<<"\n"; //bothMOV na
		}
        
    }


	optimizeCodeFile<< lineCodeList[asm_line_number-1]<<"\n"; 
	//last line ta loop e silo NA 
	lineCodeList.clear(); 

}




void optimizeAsmCode1(string asmCode1)
{
	vector <string> listCode1;

    char separator = '\n';
    splitStringFunc(asmCode1, separator, listCode1); 
	/*
	for(int i=0; i<lineCodeList.size(); i++){
		cout<<lineCodeList[i]<<"\n"; 
	}
	*/ 
	cout<<listCode1.size()<<"\n"; 

	vector <string> lineCodeList; 

	//lineCodeList = skipCodeVector(listCode1); 

	cout<<lineCodeList.size()<<"\n"; 



	int asm_line_number = lineCodeList.size(); 

	string after_optimize_code = ""; 

	for(int i=0; i<asm_line_number-1; i++) {

	}


	//asm_line_number-1 keno? karon ami lineCodeList[i+1] check korsi; so out of bound e jabe 
	for(int i=0; i<asm_line_number-1; i++) {
		
		string instruc1 = lineCodeList[i]; 
		string instruc2 = lineCodeList[i+1]; 



		bool isBothMove = checkBothMoveInstruction(instruc1, instruc2); 


		if(isBothMove){
			cout<<"both Move instruction for : i="<<i<<"\tinstruc1:"<<instruc1<<"\n"; 
		}
		
		

		/*
		Condition1: 
		aim: 
		MOV t1, AX

		MOV AX, t1

		==> 
		MOV t1, AX
		-------
		*/ 
		/*
		1. MOV stmt

		*/ 
		//"\tmov" check korte at least 4 char lage; er cheye kom hole bad 


		








        
    }

}


/*
mov ax, 10
mov a2, ax
*/ 

string simpleVariableAssignCode(string varName, string varValue)
{
    string varCode1 = "\n\tMOV AX, "; 
    varCode1 += varValue; 
    varCode1 += "\n"; 
    varCode1 += "\tMOV ";
    varCode1 += varName;  
    varCode1 += ", AX\n"; 

    return varCode1; 




}



string printLineAssemblyCode()
{
    string printLineAsm1 = "\nPRINTLN PROC\n"; 
    printLineAsm1 += "\tPOP RET_ADDRESS\n\tPOP BX \n"; 

	printLineAsm1 += "\n\tMOV COUNT_DIGIT, 0\n"; 
	string  str1 = "\'0\'";

	//MOV MINUS_KINA, '0' 
	printLineAsm1 += "\n\tMOV MINUS_KINA, "; 
	printLineAsm1 += str1;

    printLineAsm1 += "\n\tCMP\tBX,0\n\tJGE\tDIGIT_PUSH;\n\tMOV MINUS_KINA,"; 

    str1 = "\'1\'"; //'1'

    printLineAsm1 += str1;
    
    printLineAsm1 += "\n\tNEG\tBX; so BX er 2's compl. = +ve\n"; 


	
    printLineAsm1 += "\n\n\tDIGIT_PUSH:\n\tMOV AX, BX\n\tCWD\n\tMOV BX, 10\n\tIDIV BX\n\tPUSH DX\n\tINC COUNT_DIGIT\n\tMOV BX, AX\n"; 

    printLineAsm1 += "\n\tCMP\tBX, 0\n\tJNZ\tDIGIT_PUSH\n\tCMP MINUS_KINA,"; 

    printLineAsm1 += str1;

    printLineAsm1 += "\n\tJNE DIGIT_POP"; 
    
    str1 = "\'-\'"; //'-'
    printLineAsm1 += "\n\tMOV AH, 2\n\tMOV DL, "; 

    printLineAsm1 += str1; 
    printLineAsm1 += "\n\tINT 21H ; - print\n"; 

    printLineAsm1 += "\n\n\tDIGIT_POP:\n\tPOP\tDX\n\tDEC\tCOUNT_DIGIT\n\tMOV AH, 2\n\tADD DL,30H\n\tINT 21H\n"; 


    printLineAsm1 += "\n\tCMP\tCOUNT_DIGIT,0\n\tJNZ DIGIT_POP\n"; 
	
	/// new line print 
	printLineAsm1 += "\n\tMOV AH, 2\n\tMOV DL, 0AH\n\tINT 21H\n\tMOV DL, 0DH\n\tINT 21H\n";

	printLineAsm1 += "\n\tprintln_ret:\n\tPUSH RET_ADDRESS\n\tRET\n"; 

    printLineAsm1 += "\nPRINTLN ENDP\n\n\n"; 

    return printLineAsm1; 


}



string variableNameGenerator(string varName, string scopeId)
{
    //scopeId  = 1.2.5 ashle : 1+2+5 = 8 
    //"a8" show hobe 
    vector <string> listToken;

    char separator = '.';
    splitStringFunc(scopeId, separator, listToken); 
    string newVarName = varName; 
    for(int i=0; i<listToken.size(); i++ )
    {
        newVarName = newVarName + listToken[i]; 
        //cout<<"\n"<<listToken[i]; 
    }
 
    
	//cout<<"\n# new varName: "<<newVarName<<"\n"; 
	return newVarName; 

}

string mainFuncStartAssemblyCode()
{
    string mainFuncStart = "\n\n\nMAIN PROC\n;initialize DS\n"; 

    mainFuncStart += "\tMOV AX, @DATA\n"; 
    mainFuncStart += "\tMOV DS, AX\n\n"; 

    return mainFuncStart; 

}

string mainFuncEndAssemblyCode()
{
	/*
	MOV AH, 4CH
    INT 21H
    MAIN 	ENDP
	*/ 
    // return control 
	string control1 = "\n\tmain_ret:\n\tMOV AH, 4CH\n"; 
	control1 = control1+"\tINT 21H\n"; 
    control1 += "MAIN\tENDP\n"; 
	return control1; 

}


string assemblyCodeStartSame()
{
	//dataVariables = list of variables 

	/*
	.model small
	.stack 100h
	.data
	*/
	string model1 = ".MODEL SMALL\n"; 
	model1 += ".STACK 100H\n"; 

	string fullAsmCode  = model1 ; 
    fullAsmCode += "\n.DATA\n"; 

    fullAsmCode += "\n\tRET_ADDRESS dw 0\n"; 

    //string str1 = "\'-\'"; //'-'
    //fullAsmCode += str1; 

	fullAsmCode += dataVariablesCode; 

    // *** additional           fixed variables             ~~~~~~~~~~//
    /*
        COUNT_DIGIT DB ? 
      
        MINUS_KINA DB '0'	

    .CODE
    */
    fullAsmCode += "\n\tCOUNT_DIGIT DB ?\n\tMINUS_KINA DB '0'\n\n"; 

	fullAsmCode += ".CODE\n"; 

    fullAsmCode += printLineAssemblyCode(); 

	//fullAsmCode += returnControlCode(); 

	return fullAsmCode; 



}

string PrintFloatTwoDecimal(string str)
{
	float val1 = std::stof(str);

	int len = numberOfDigitInFloat(val1); 

	if(len==1){
		str = str+"0"; 
	}
	

	return str; 

}

///simply int a[2], c, d; egulake print korar jonno ** 

void yyerror (char const *s)
{
	string str = s; 
	//errorCount++;  ki hobe?
	syntaxErrorCount++; 
	errorCount++; 

	//str :syntax error
	//Error at line 3: syntax error
	//write your code
	// cout<<"\n\n****************** Line :"<<lineNumber<<" INSIDE yyerror: str ="<<str<<"\n\n"; 
	//logFile<<"\n\n****************** Line :"<<lineNumber<<" INSIDE yyerror: str ="<<str<<"\n\n"; 
	logFile<<"Error at line "<<lineNumber<<": "<<str<<"\n\n"; 
	errorFile<<"Error at line "<<lineNumber<<": "<<str<<"\n\n"; 
}


%}

%union{
	int ival; 
	SymbolInfo* si; 
	vector<SymbolInfo*>* vsi; 
}

/// age token by default int assign hoto 
// %token <ival> SEMICOLON
//**** ADDOP MULOP e <ival> LAGBE 010 mote *********
%token IF ELSE RETURN COMMA SEMICOLON LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD PRINTLN
%token <si> FOR WHILE INT FLOAT VOID ID CONST_INT CONST_FLOAT
%token<si> ADDOP MULOP NOT ASSIGNOP LOGICOP RELOP INCOP DECOP


// id, int ami si pointer return kortesi ; 


///**** terminal %token; non-terminal %type diye 

%type <si> type_specifier declaration_list var_declaration  unit program start

%type <si> func_declaration parameter_list func_definition argument_list arguments

%type <si> compound_statement statements statement expression expression_statement
%type <si> variable factor unary_expression term simple_expression logic_expression rel_expression 
// %left 
// %right

// %nonassoc 
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start: program
	{
		string symbolName = $1->getSymbolName(); 
		string symbolType = "start";
		$$ = new SymbolInfo(symbolName, symbolType);
		//Line 22: start : program
		int totalLine = lineNumber; 
		logFile << "Line " << totalLine << ": start : program\n";  
		symTable->PrintAllScopeTable(logFile); 
		logFile<<"\n\n"; 

		string fullAsmCode1 = assemblyCodeStartSame(); 
        //.CODE porjonto hoyese 
        fullAsmCode1 += $1->getAssemblyCode(); 

        // 	END	MAIN
        fullAsmCode1 += "\tEND	MAIN\n"; 


		$$->setAssemblyCode(fullAsmCode1); 		

		assemblyCodeFile << $$->getAssemblyCode()<<"\n"; 

		optimizeAsmCode(fullAsmCode1); 



		logFile<<"Total lines: "<<totalLine<<"\n"; 
		logFile<<"Total errors: "<<errorCount<<"\n\n"; 
		
	}
	;

program: program unit{
		string symbolName = $1->getSymbolName()+  $2->getSymbolName(); 
		string symbolType = "program";
		$$ = new SymbolInfo(symbolName, symbolType);

        string programAssemblyCode1 = $1->getAssemblyCode() +"\n";
        programAssemblyCode1 += $2->getAssemblyCode(); 

        $$->setAssemblyCode(programAssemblyCode1); 
		
		logFile << "Line "<< lineNumber << ": program : program unit"<< "\n\n" ;
		logFile << $$->getSymbolName() << "\n\n";
	} 
	| unit{
		string symbolName = $1->getSymbolName(); 
		string symbolType = "program"; 
		$$ = new SymbolInfo(symbolName, symbolType);

        string unitAssemblyCode1 = $1->getAssemblyCode(); 
        $$->setAssemblyCode(unitAssemblyCode1); 


		logFile << "Line " << lineNumber << ": program : unit" << "\n\n";
		logFile << $$->getSymbolName() << "\n\n"; 
		}
	;
	
unit: 	error SEMICOLON {
			//cout<<"\n\n******************************************            ##";
			//cout<<"\nLine:"<<lineNumber<<": unit: 	error SEMICOLON"<<"\n\n"; 
			
		}
 		| var_declaration {
		string symbolName = $1->getSymbolName(); 
		string symbolType = "unit"; 
		$$ = new SymbolInfo(symbolName, symbolType);
        logFile<< "Line " << lineNumber << ": unit : var_declaration" << "\n\n" ;
        logFile << $$->getSymbolName() <<"\n\n";
		}
		| func_definition {
			string symbolName = $1->getSymbolName()+"\n"+"\n"; 
			string symbolType = "unit"; 
			$$ = new SymbolInfo(symbolName, symbolType);

            // void foo(){} etar assembly code ekhon propagate korbo ami 
            string funcAssemblyCode1 = $1->getAssemblyCode(); 
            $$->setAssemblyCode(funcAssemblyCode1); 

			logFile<< "Line " << lineNumber << ": unit : func_definition\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n";
		}
		| func_declaration {
			string symbolName = $1->getSymbolName(); 
			string symbolType = "unit"; 
			$$ = new SymbolInfo(symbolName, symbolType);
			logFile<< "Line " << lineNumber << ": unit : func_declaration" << "\n\n" ;
			logFile << $$->getSymbolName() <<"\n\n";
		}
     ;
		

func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
			logFile<<"Line "<<lineNumber<<": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n";
			//Line 3: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
			//$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "( " + $4->getName() + " );\n");
			
			string symbolName = $1->getSymbolName()+ " "+$2->getSymbolName() ; //int foo3
			symbolName = symbolName + "(" + $4->getSymbolName() + ");\n"; //(int a, int b);\n

			string symbolType = "func_declaration";			
			$$ = new SymbolInfo(symbolName, symbolType);

			logFile << $$->getSymbolName()  << "\n\n";

			
			
			//int foo3(int a, int b);
			string key = $2->getSymbolName(); 

			SymbolInfo* insertSym = symTable->InsertPointer(key,"ID"); 


			if(insertSym != NULL){
				
				insertSym->setWhatTypeID("FUNC_DECLARED"); 
				insertSym->paramSymList = parameterListYFile; 
				parameterListYFile.clear(); 
				
				
				// int foo3;  int = return type = $1; 
				string returnType = $1->getWhatTypeSpecifier();
				//cout<<"key="<<key<<"\t returnType ="<<returnType<<"\n"; 
				insertSym->setWhatTypeSpecifier(returnType); 
				insertSym->setWhatTypeReturn(returnType); 
			}
			else if(insertSym == NULL){
				
				//age theke symTable e ase foo
				logFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
				errorFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
				semanticErrorCount++; 
				errorCount++; 
			}			
			
		
		} 
		| type_specifier ID LPAREN parameter_list RPAREN error { 
			errorFile<<"Error at line "<<lineNumber<<": Func Declaration Incomplete "<<"\n\n"; 
			$$ = new SymbolInfo("",""); 
		}
		|type_specifier ID LPAREN RPAREN error{
			errorFile<<"Error at line "<<lineNumber<<": Func Declaration Incomplete "<<"\n\n";
			$$ = new SymbolInfo("",""); 
		}
		|type_specifier ID LPAREN RPAREN SEMICOLON {
			logFile<<"Line "<<lineNumber<<": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n";
			//Line 4: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON
			
			string symbolName = $1->getSymbolName()+ " "+$2->getSymbolName() + "();" +"\n" ; 
			string symbolType = "func_declaration"; 
			//"void foo();\n","func_declaration"
	
			
			$$ = new SymbolInfo(symbolName, symbolType);

			logFile << $$->getSymbolName()  << "\n\n";
			//void foo(); 
			//focus symTable e insert $2 = ID 
			//means: void foo(); so foo as ID insert korbo 
			string key = $2->getSymbolName(); 
			//"ID" = tar type 
			SymbolInfo* insertSym = symTable->InsertPointer(key,"ID"); 

			///simply: (foo, "ID") inserting			
				
			if(insertSym != NULL){

				insertSym->setWhatTypeID("FUNC_DECLARED"); 
				insertSym->paramSymList = parameterListYFile; 
				parameterListYFile.clear(); 

				// void foo(); void = return type = $1; 
				string returnType = $1->getWhatTypeSpecifier();
				//cout<<"key="<<key<<"\t returnType ="<<returnType<<"\n"; 
				insertSym->setWhatTypeSpecifier(returnType); 
				insertSym->setWhatTypeReturn(returnType); 
			}
			else if(insertSym == NULL){				
				//age theke symTable e ase foo
				logFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
				errorFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
				semanticErrorCount++; 
				errorCount++; 
			}			
			
		}
		;

func_definition: type_specifier ID LPAREN parameter_list RPAREN{
			string funcName = $2->getSymbolName() ;
			currentFunctionName = funcName;  // *** eta keno lagbe? karon amar return er LABEL foo_ret: pete 
			//then funcName ke INSERT
			//bool insertSuccess = symTable->Insert(funcName,"ID"); 
			SymbolInfo* insertSym = symTable->InsertPointer(funcName,"ID"); 
			if(insertSym != NULL){
				insertSym->setWhatTypeID("FUNC_DEFINED");  
				insertSym->paramSymList = parameterListYFile; 
				//parameterListYFile.clear(); 			eta pore giye clear korsi 	

				string returnType = $1->getWhatTypeSpecifier();
				// cout<<"****************1. new defined funcName="<<funcName<<"\t returnType ="<<returnType<<"\n"; 
				insertSym->setWhatTypeSpecifier(returnType); 
				insertSym->setWhatTypeReturn(returnType); 
			}
			else if(insertSym == NULL){			
				SymbolInfo* funcSymInfo1 = symTable->LookUpOff1(funcName);

				if(funcSymInfo1 != NULL){
					if(funcSymInfo1->getWhatTypeID() == "FUNC_DECLARED")
					{
						//so no Error ;age theke declared
						//now check # of parameters 
						int prevParameter = funcSymInfo1->paramSymList.size();
						///parameter NAME same NA hoteo pare; but TYPESPECIFIER must be same 
						int ekhonParameter = parameterListYFile.size(); 

						// cout<<"\n***** prevParameter= "<<prevParameter<<"\t ekhonParameter= "<<ekhonParameter<<"\n"; 

						bool parameterMatched = true; 
						if(prevParameter == ekhonParameter)
						{
							for(int i=0; i<ekhonParameter ; i++)
							{
								string paramType1 = funcSymInfo1->paramSymList[i]->getWhatTypeSpecifier(); 
								string paramType2 = parameterListYFile[i]->getWhatTypeSpecifier(); 
								
								string paramID1 = funcSymInfo1->paramSymList[i]->getWhatTypeID(); 
								string paramID2 = parameterListYFile[i]->getWhatTypeID(); 

								// cout<<"\n*************** paramType1 =" <<paramType1<<" paramType2 ="<< paramType2<<"\n"; 
								// cout<<"\n*************** paramID1 =" <<paramID1<<" paramID2 ="<< paramID2<<"\n"; 
								//like ekta ARRAY arekta VARIABLE
								if((paramType1 != paramType2 ) || (paramID1 != paramID2)){
									parameterMatched = false; 
									break; 
								}
							}

						}
						else if(prevParameter != ekhonParameter)
						{
							parameterMatched = false; 
						}

						if(parameterMatched == false){
							semanticErrorCount++; 
							errorCount++; 
							//cout<<"******Line "<< lineNumber<< " parameter list didn't match\n\n"; 
							//Error at line 32: Total number of arguments mismatch with declaration in function var
							logFile<<"Error at line "<<lineNumber<<": Total number of arguments mismatch with declaration in function "; 
							logFile<<funcName<<"\n\n"; 

							errorFile<<"Error at line "<<lineNumber<<": Total number of arguments mismatch with declaration in function "; 
							errorFile<<funcName<<"\n\n"; 


						}
						else if(parameterMatched == true)
						{
							string retType1 = $1->getWhatTypeSpecifier();
							string retType2 = funcSymInfo1->getWhatTypeReturn(); 
							// cout<<"\n******** retType1 ="<<retType1<<"\t retType2 = "<<retType2<<"\n";  
							if(retType1 == retType2)
							{
								funcSymInfo1->setWhatTypeID("FUNC_DEFINED"); 

							}
							else if(retType1 != retType2)
							{

								semanticErrorCount++;
								errorCount++; 
								//cout<<"\n******Line "<<lineNumber<<": RETURN TYPE does not match with declarations\n\n"; 
								//Error at line 24: Return type mismatch with function declaration in function foo3                        

								errorFile<<"Error at line "<<lineNumber<<": Return type mismatch with function declaration in function "<<funcName<<"\n\n"; 
							
								logFile<<"Error at line "<<lineNumber<<": Return type mismatch with function declaration in function "<<funcName<<"\n\n"; 
							
							}

						}

						
					}
					else if(funcSymInfo1->getWhatTypeID() != "FUNC_DECLARED")
					{
						//then age declare hoyese; but FUNC NA; so ERROR
						//Error at line 28: Multiple declaration of z
						logFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<< funcName <<"\n\n"; 
						errorFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<< funcName <<"\n\n"; 
						semanticErrorCount++; 
						errorCount++; 

					}
				}
				
			}	
			
			// cout<<"\n***************type_specifier ID LPAREN parameter_list RPAREN{ rule e\n"; 
			symTable->EnterScope(); 
			// then PARAMETER insert ; tara NOTUN SCOPE e 
			int noParameter = parameterListYFile.size(); 

			for(int i = 0; i< noParameter; i++) 
			{
			
				string key = parameterListYFile[i]->getSymbolName(); 
				string type = parameterListYFile[i]->getSymbolType(); //"ID" i ashbe 

				string paramType = parameterListYFile[i]->getWhatTypeSpecifier(); 
				string paramID = parameterListYFile[i]->getWhatTypeID(); 

				
                string currScopeStr = symTable->getCurrentScopeId(); 
                string newParamName1 = variableNameGenerator(key, currScopeStr); 
         

				dataVariables.push_back(newParamName1);

				string varCode2 = "\t" + newParamName1 + " dw ?" + "\n";  
				/* 
				simply ami ki chai? 
					c11 dw ?
					  
				*/ 
				dataVariablesCode += varCode2; 
				
				

				// cout<<"#************** Param : KEY="<<key<<"\t paramType ="<< paramType<<"\n"; 
				//Error at line 3: 1th parameter's name not given in function definition of var
				if(key=="int" || key=="float" || key=="void"){
					errorCount++; 
					semanticErrorCount++; 
					errorFile<<"Error at line "<<lineNumber<<": "<< (i+1)<<"th parameter's name not given in function definition of var"<<"\n\n"; 
				
					logFile<<"Error at line "<<lineNumber<<": "<< (i+1)<<"th parameter's name not given in function definition of var"<<"\n\n"; 
				}
				else{
					SymbolInfo* paramSymInfo = symTable->InsertPointer(key,type); 
					if(paramSymInfo != NULL){ 
						paramSymInfo->setWhatTypeSpecifier(paramType); 
						paramSymInfo->setWhatTypeID(paramID); 

						///======================>      setAssemblyName : 
						paramSymInfo->setAssemblyName(newParamName1); 
					}
				}
				
				

			}
			
		}	
		compound_statement {
			
			string symbolName = $1->getSymbolName()+ " " + $2->getSymbolName() + "(" + $4->getSymbolName() +")" ;
			symbolName += $7->getSymbolName();  ///*** focus $7 ; NOT $6 

			string symbolType = "func_definition";
			$$ = new SymbolInfo(symbolName, symbolType);

			string funcRetType1 = $1->getWhatTypeSpecifier(); //void kina check 
			//logFile<<"Error at line "<< lineNumber<<": Multiple declaration of "<< parameterName<<" in parameter"<<"\n\n"; 

			//logFile<<"\n\n\n*********************                 #### "<<"\n\n"; 
			//logFile<<"funcRetType1 = "<<funcRetType1<<" isFunctionReturning ="<<isFunctionReturning<<"\n\n"; 

			if(funcRetType1!= "VOID"  && isFunctionReturning==false)
			{
				// semanticErrorCount++; 
				// errorCount++; 
				// logFile<<"Error at line "<< lineNumber<<": missing return statement"<<"\n\n"; 
				// errorFile<<"Error at line "<< lineNumber<<": missing return statement"<<"\n\n"; 

			}
			else if(isFunctionReturning==true && funcRetType1=="VOID"){
				semanticErrorCount++;
				errorCount++; 
				logFile<<"Error at line "<< lineNumber<<": type specifier is of type void, cannot return"<<"\n\n";
				errorFile<<"Error at line "<< lineNumber<<": type specifier is of type void, cannot return"<<"\n\n"; 
			}
			else{
				//RETURN TYPE : 
				//error ONLY when int e float pass; else NO errror  ***** 
				
				//logFile<<"\n currentFunctionReturnType ="<<currentFunctionReturnType<<"\tfuncRetType1 = "<<funcRetType1<<"\n\n"; 
				if((currentFunctionReturnType=="FLOAT") && funcRetType1=="INT")
				{
					errorCount++; 
					semanticErrorCount++; 
					logFile<<"Error at line "<< lineNumber<<": return type do not match"<<"\n\n"; 
					errorFile<<"Error at line "<< lineNumber<<": return type do not match"<<"\n\n"; 
				}
			}

			
			isFunctionReturning =false;
				
			//* focus funcName INSERT er age EXIT **
			

			//"ID" = tar type 
			///simply: (foo3, "ID") inserting 

					
			
			// ***              asm file e main proc e kono parameter thake NA;  ~~~~~~~~~~~~~~~~~~~
			

			string funcAssemblyCode = ""; 

			string funcName2 = $2->getSymbolName(); 				

			if(funcName2 !="main"){   
				//PRINT_ARRAY3 PROC
				funcAssemblyCode += funcName2; 
				funcAssemblyCode += " PROC\n"; 
				funcAssemblyCode += "\tPOP RET_ADDRESS\n"; 
				// ulta dik theke variable pop kortesi variables **** 
				// push (arglist e thik dik theke)
				/*
				int foo(int a, int b){}
				pop b11
				pop a11  keno?
				karon main() theke 

				arglist call:        
				push a11
				push b11
				*/ 
				int lastVarIdx = parameterListYFile.size();
				lastVarIdx--; 

				//vector<SymbolInfo*> parameterListYFile;
				for(int i=lastVarIdx; i>=0; i--){
					string paramVar1 = parameterListYFile[i]->getSymbolName();
					

                	string currScopeStr = symTable->getCurrentScopeId(); 
                	string paramVar2 = variableNameGenerator(paramVar1, currScopeStr); 

					funcAssemblyCode += "\tPOP "; 
					funcAssemblyCode += paramVar2; 
					funcAssemblyCode += "\n"; 
				}

				// $7 ; NOT $6 
				// $7->getAssemblyCode(); mane COMP-STMT er code ta ekhane dhukbe 
                funcAssemblyCode += $7->getAssemblyCode(); 


                //funcAssemblyCode += "\n\tPOPA\n";
				

				// return ER LABEL er jonno 
				string retLabel1 = funcName2 +"_ret:\n"; 
				funcAssemblyCode += "\t"; 
				funcAssemblyCode += retLabel1; 
				funcAssemblyCode += "\n\tPUSH RET_ADDRESS\n"; 

                funcAssemblyCode += "\tRET\n"; 

                //funcAssemblyCode += funcName2; 
                string endLine1 = funcName2 + " ENDP\n"; 
                funcAssemblyCode += endLine1; 
				
			}
			$$->setAssemblyCode(funcAssemblyCode); 


			parameterListYFile.clear(); 
			symTable->PrintAllScopeTable(logFile);
			logFile<<"\n\n"; 
			symTable->ExitScope();
			

			
			logFile<<"Line "<<lineNumber<<": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n";
			logFile<< $$->getSymbolName()<<"\n\n" <<"\n"; 
			

		}
		| type_specifier ID LPAREN RPAREN 
		{
			string funcName = $2->getSymbolName() ;
			currentFunctionName = funcName;  // *** karon amar return er LABEL foo_ret: pete 
			//then funcName ke INSERT
			SymbolInfo* insertSym = symTable->InsertPointer(funcName,"ID"); 
			if(insertSym != NULL){
				insertSym->setWhatTypeID("FUNC_DEFINED");  
				//foo() age declare hoyni ; 
				insertSym->paramSymList = parameterListYFile; 
				parameterListYFile.clear(); 
				//FAKA hobe; karon PARAMETER e keu nei 

				// void foo(); void = return type = $1; 
				string returnType = $1->getWhatTypeSpecifier();
				// cout<<"funcName="<<funcName<<"\t returnType ="<<returnType<<"\n"; 
				insertSym->setWhatTypeSpecifier(returnType); 
				insertSym->setWhatTypeReturn(returnType); 
			}
			else if(insertSym == NULL){	

				//** check koro : foo() ki age theke declare ase?
				SymbolInfo* funcSymInfo1 = symTable->LookUpOff1(funcName);

				if(funcSymInfo1 != NULL){
					if(funcSymInfo1->getWhatTypeID() == "FUNC_DECLARED")
					{
						//so no Error ;age theke declared
						//now check # of parameters 
						int noParameter1 = funcSymInfo1->paramSymList.size(); 
						
						//should be 0
						if(noParameter1>0){
							semanticErrorCount++;
							errorCount++; 
							// cout<<"\n************************Line "<<lineNumber<<": parameter quantity does not match with declarations\n\n"; 
							// cout<<"noParameter1 = "<<noParameter1<<"\n"; 
							logFile<<"\n\nLine "<<lineNumber<<": parameter quantity does not match with declarations\n\n"; 
							errorFile<<"\n\nLine "<<lineNumber<<": parameter quantity does not match with declarations\n\n"; 
							
						}
						else if(noParameter1 == 0)
						{
							string retType1 = $1->getWhatTypeSpecifier();
							string retType2 = funcSymInfo1->getWhatTypeReturn(); 
							// cout<<"\n******** retType1 ="<<retType1<<"\t retType2 = "<<retType2<<"\n";  
							if(retType1 == retType2)
							{
								funcSymInfo1->setWhatTypeID("FUNC_DEFINED"); 

							}
							else if(retType1 != retType2)
							{

								semanticErrorCount++;
								errorCount++; 
								//cout<<"\n******Line "<<lineNumber<<": RETURN TYPE does not match with declarations\n\n"; 
							
								logFile<<"\n\nLine "<<lineNumber<<": RETURN TYPE does not match with declarations\n\n"; 
								errorFile<<"\n\nLine "<<lineNumber<<": RETURN TYPE does not match with declarations\n\n"; 
							}

						}

					}
				}
				//actually funcSymInfo1= NULL howar chance nei; 
				//karon ota to insert kora hoise 

				
				
			}	
			
			symTable->EnterScope(); 	

		}
		compound_statement{

			string symbolName = $1->getSymbolName()+ " " + $2->getSymbolName() + "(" + ")" ;
			symbolName += $6->getSymbolName();  

			string symbolType = "func_definition";
			$$ = new SymbolInfo(symbolName, symbolType);
			
			string funcRetType1 = $1->getWhatTypeSpecifier(); //void kina check 
			//logFile<<"Error at line "<< lineNumber<<": Multiple declaration of "<< parameterName<<" in parameter"<<"\n\n"; 

			//logFile<<"\n\n\n*********************                 #### "<<"\n\n"; 
			//logFile<<"funcRetType1 = "<<funcRetType1<<" isFunctionReturning ="<<isFunctionReturning<<"\n\n"; 

			if(funcRetType1!= "VOID"  && isFunctionReturning==false)
			{
				// semanticErrorCount++; 
				// errorCount++; 
				// logFile<<"Error at line "<< lineNumber<<": missing return statement"<<"\n\n"; 
				// errorFile<<"Error at line "<< lineNumber<<": missing return statement"<<"\n\n"; 

			}
			else if(isFunctionReturning==true && funcRetType1=="VOID"){
				semanticErrorCount++;
				errorCount++; 
				logFile<<"Error at line "<< lineNumber<<": type specifier is of type void, cannot return"<<"\n\n"; 

				errorFile<<"Error at line "<< lineNumber<<": type specifier is of type void, cannot return"<<"\n\n"; 
			}
			else{
				//RETURN TYPE : 
				//error ONLY when int e float pass; else NO errror  ***** 
				
				//logFile<<"\n currentFunctionReturnType ="<<currentFunctionReturnType<<"\tfuncRetType1 = "<<funcRetType1<<"\n\n"; 
				if((currentFunctionReturnType=="FLOAT") && funcRetType1=="INT")
				{
					errorCount++; 
					semanticErrorCount++; 
					logFile<<"Error at line "<< lineNumber<<": return type do not match"<<"\n\n";
					errorFile<<"Error at line "<< lineNumber<<": return type do not match"<<"\n\n";  

				}
			}

			
			isFunctionReturning =false;


            ////                 asm code for parameter SARA function ;                    ~~~~~~~~~~///

  

            string funcAssemblyCode = ""; 

            string funcName2 = $2->getSymbolName(); 
            if(funcName2=="main"){
                 if(isMainFuncDefined==false){

                    isMainFuncDefined = true; 
                    funcAssemblyCode += mainFuncStartAssemblyCode();
                    funcAssemblyCode += $6->getAssemblyCode();  
                    // $6->getCode(); mane COMP-STMT er code ta ekhane dhukbe 
                    funcAssemblyCode += mainFuncEndAssemblyCode();  
                    

                 }
               

            }
            else if(funcName2!="main"){   
                //PRINT_ARRAY3 PROC
                funcAssemblyCode += funcName2; 
                funcAssemblyCode += " PROC\n"; 
                funcAssemblyCode += "\tPOP RET_ADDRESS\n"; 
                // $6->getAssemblyCode(); mane COMP-STMT er code ta ekhane dhukbe 
                funcAssemblyCode += $6->getAssemblyCode(); 

				string retLabel1 = funcName2 +"_ret:\n"; 
				funcAssemblyCode += "\t"; 
				funcAssemblyCode += retLabel1; 

				funcAssemblyCode += "\n\tPUSH RET_ADDRESS\n"; 

                //cout<<"func_defn e  $6->getAssemblyCode()="<< $6->getAssemblyCode()<<"\n"; 

         
                funcAssemblyCode += "\tRET\n"; 

                //funcAssemblyCode += funcName2; 
                string endLine1 = funcName2 + " ENDP\n"; 
                funcAssemblyCode += endLine1; 




            }

            $$->setAssemblyCode(funcAssemblyCode); 
            //cout<<"func defn: $$->getAssemblyCode()="<<$$->getAssemblyCode()<<"\n"; 
            
           


			symTable->PrintAllScopeTable(logFile);
			logFile<<"\n\n"; 
			
			symTable->ExitScope();	
			//Line 12: func_definition : type_specifier ID LPAREN RPAREN compound_statement
			logFile<<"Line "<<lineNumber<<": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n";
			logFile<< $$->getSymbolName()<<"\n\n"<<"\n"; 
		}
		
		; 

parameter_list: parameter_list error {

				//logFile<<"\n\nLine :"<<lineNumber<<" parameter_list error\n\n"; 

			} 
			| parameter_list COMMA type_specifier ID{

			string symbolName = $1->getSymbolName()+ "," + $3->getSymbolName() + " " + $4->getSymbolName()  ; 
			//int a
			string symbolType = "parameter_list"; 
			$$ = new SymbolInfo(symbolName, symbolType);
			
			string parameterName = $4->getSymbolName();  
			SymbolInfo* paramSymInfo =new SymbolInfo(parameterName,"ID");

			string paramtype1 = $3->getWhatTypeSpecifier(); 
			 

			paramSymInfo->setWhatTypeSpecifier(paramtype1); 
			paramSymInfo->setWhatTypeID("VARIABLE"); 

			// cout<<"\n***************** parameterName= "<<parameterName<<"\n"; 
			//** int count(Iterator first, Iterator last, T &val)
			if (std::count(parameterNameYFile.begin(), parameterNameYFile.end(), parameterName)) {
				// cout<<"*********************** Line: "<<lineNumber<<" : ekadhik PARAMETER SAME NAME (((((((((((((((((((((\n"; 
				//Error at line 20: Multiple declaration of a in parameter
				logFile<<"Error at line "<< lineNumber<<": Multiple declaration of "<< parameterName<<" in parameter"<<"\n\n";
				errorFile<<"Error at line "<< lineNumber<<": Multiple declaration of "<< parameterName<<" in parameter"<<"\n\n";  
				semanticErrorCount++; 
				errorCount++; 
			}
			else{
				// cout<<"\n****Normal parameterName )))))))))\n"; 
				parameterNameYFile.push_back(parameterName); 
				parameterListYFile.push_back(paramSymInfo); 
			}

			
            //int a, float b           ; so "b", "ID" vector e push 

			//Line 3: parameter_list : parameter_list COMMA type_specifier ID
			logFile<<"Line "<<lineNumber<<": parameter_list : parameter_list COMMA type_specifier ID\n\n"; 
			logFile<< $$->getSymbolName()<<"\n\n";
			//******* FOCUS: ekhane vec<string> CLEAR() hoitese;  
			//parameterListYFile.clear() FUNCTION e hobe ***
			parameterNameYFile.clear(); 
			

		}	
		| parameter_list COMMA type_specifier{
			string symbolName = $1->getSymbolName()+ "," + $3->getSymbolName()   ; 
			//int, float 
			string symbolType = "parameter_list"; 
			$$ = new SymbolInfo(symbolName, symbolType);
			
			string parameterName = $3->getSymbolName();  
			SymbolInfo* paramSymInfo =new SymbolInfo(parameterName,"ID");

			string paramtype1 = $3->getWhatTypeSpecifier(); 
			 

			paramSymInfo->setWhatTypeSpecifier(paramtype1); 
			paramSymInfo->setWhatTypeID("VARIABLE"); 


			parameterListYFile.push_back(paramSymInfo); 
            //int ,  b           ; so "float", "ID" vector e push 

			//Line 3: parameter_list : parameter_list COMMA type_specifier
			logFile<<"Line "<<lineNumber<<": parameter_list : parameter_list COMMA type_specifier\n\n"; 
			logFile<< $$->getSymbolName()<<"\n\n"; 
		}
 		| type_specifier ID{
			
			parameterNameYFile.clear(); 
			string symbolName = $1->getSymbolName()+ " "+$2->getSymbolName()  ; 
			//int a
			string symbolType = "parameter_list"; 
			$$ = new SymbolInfo(symbolName, symbolType);
			//Line 3: parameter_list : type_specifier ID
			

			string parameterName = $2->getSymbolName();  
			SymbolInfo* paramSymInfo =new SymbolInfo(parameterName,"ID");
			// cout<<"\n***************** parameterName= "<<parameterName<<"\n"; 
			string paramtype1 = $1->getWhatTypeSpecifier(); 
			//cout<<"\n\n*******************************************************paramtype1 ="<<paramtype1<<"\n"; 

			paramSymInfo->setWhatTypeSpecifier(paramtype1); 
			paramSymInfo->setWhatTypeID("VARIABLE"); 

			parameterListYFile.push_back(paramSymInfo); 
			//simply float abc then "abc","ID" vector e push 

			parameterNameYFile.push_back(parameterName); 


			logFile<<"Line "<<lineNumber<<": parameter_list : type_specifier ID\n\n"; 
			logFile<< $$->getSymbolName()<<"\n\n"; 

			
		 }
		 | type_specifier {
			
			string symbolName = $1->getSymbolName(); 
			//int func(int,float)

			string symbolType = "parameter_list"; 
			$$ = new SymbolInfo(symbolName, symbolType);
			
			

			string parameterName = $1->getSymbolName();  
			SymbolInfo* paramSymInfo =new SymbolInfo(parameterName,"ID");
			
			string paramtype1 = $1->getWhatTypeSpecifier(); 
			//cout<<"\n\n*******************************************************paramtype1 ="<<paramtype1<<"\n"; 

			paramSymInfo->setWhatTypeSpecifier(paramtype1); 
			paramSymInfo->setWhatTypeID("VARIABLE"); 

			parameterListYFile.push_back(paramSymInfo); 
			//simply float abc then "abc","ID" vector e push 

			//Line 3: parameter_list : type_specifier 
			logFile<<"Line "<<lineNumber<<": parameter_list : type_specifier\n\n"; 
			logFile<< $$->getSymbolName()<<"\n\n"; 
		 }
		 ; 

compound_statement: LCURL statements RCURL		
		 	{

				string symbolName = "{\n" + $2->getSymbolName() + "}" ; 
				string symbolType = "compound_statement";
				
				$$ = new SymbolInfo(symbolName, symbolType);

                string comd_code = $2->getAssemblyCode(); 
                //cout<<"comd_code ="<<comd_code<<"\n"; 
                $$->setAssemblyCode(comd_code); 

				logFile<< "Line " << lineNumber << ": compound_statement : LCURL statements RCURL\n\n"; 
				logFile<<symbolName<<"\n\n"; 
				//Line 7: compound_statement : LCURL statements RCURL
				//insideCompound = true; 
					
			}
			| LCURL RCURL
			{
				
				//string symbolName = "{" + "\n" + "\n" + "}" ; 
				//invalid operands of types ‘const char [2]’ and ‘const char [2]’ to binary ‘operator+’
				string symbolName = "{" + (string)"\n" + (string)"\n"; 
				symbolName += "}" ;

				string symbolType = "compound_statement";
				
				// cout<<"\n********************************** INSIDE: compound_statement: LCURL RCURL\n"; 

				$$ = new SymbolInfo(symbolName, symbolType);
				logFile<< "Line " << lineNumber << ": compound_statement : LCURL RCURL\n\n"; 
				logFile<<symbolName<<"\n\n"; 
				//insideCompound = true;             
            	
			}
 		    ;



var_declaration: type_specifier error SEMICOLON {	

			$$ = new SymbolInfo("",""); 

			// cout<<"\n\n******************************************            ##";
			
			// cout<<"\nLine:"<<lineNumber<<": var_declaration: type_specifier error SEMICOLON "<<"\n\n"; 
			// logFile<<"\n\n******************************************            ##";
			// logFile<<"\nLine:"<<lineNumber<<": var_declaration: type_specifier error SEMICOLON "<<"\n\n"; 

		} 
		| type_specifier declaration_list SEMICOLON {
		//ekhane $2 te declaration_list 
		//logFile<<"Vec size: "<<$2->size()<<"\n"; 
		//logFile<<"Last elem: "<<$2->back()->getSymbolName()<<"\n"; 
		string symbolName = $1->getSymbolName()+ " "+$2->getSymbolName() + ";\n" ; //int  x,y,z\n;
		//single space 
		string symbolType = "var_declaration"; 
		$$ = new SymbolInfo(symbolName, symbolType);
		logFile << "Line " << lineNumber << ": var_declaration : type_specifier declaration_list SEMICOLON" << "\n"  << "\n";
        
		if(typeSpecifierYFile == "VOID")
		{
			
			logFile<<"Error at line "<<lineNumber<<": Variable type cannot be void\n\n"; 
			errorFile<<"Error at line "<<lineNumber<<": Variable type cannot be void\n\n"; 
			semanticErrorCount++; 
			errorCount++; 
		}
		
		logFile << $$->getSymbolName()  << "\n";

		

		}
 		;
 		 
type_specifier: INT {
					string symbolName = $1->getSymbolName(); //should be int 
					string symbolType = "type_specifier"; 
					$$ = new SymbolInfo(symbolName, symbolType);
            		
					typeSpecifierYFile = "INT"; 
					$$->setWhatTypeSpecifier("INT"); 
					logFile<<"Line "<<lineNumber<<": type_specifier : INT\n"<<"\n"; 
					logFile<< $$->getSymbolName() << "\n"  << "\n";
					
				}
				| FLOAT {
					string symbolName = $1->getSymbolName(); //should be float 
					string symbolType = "type_specifier"; 
					$$ = new SymbolInfo(symbolName, symbolType);
            		$$->setWhatTypeSpecifier("FLOAT"); 
					typeSpecifierYFile = "FLOAT"; 
					logFile<<"Line "<<lineNumber<<": type_specifier : FLOAT\n"<<"\n"; 
					logFile<< $$->getSymbolName() << "\n"  << "\n";
					
				}
				| VOID{
					string symbolName = $1->getSymbolName(); //should be void  
					string symbolType = "type_specifier"; 
					
					$$ = new SymbolInfo(symbolName, symbolType);
					$$->setWhatTypeSpecifier("VOID"); 
					typeSpecifierYFile = "VOID"; 

					logFile<<"Line "<<lineNumber<<": type_specifier : VOID\n"<<"\n"; 
					logFile<< $$->getSymbolName() << "\n"  << "\n";
				}
 		;
 		
declaration_list: declaration_list error{
				// cout<<"\n\n******************************************            ##";
			
				// cout<<"\nLine:"<<lineNumber<<": declaration_list: declaration_list error"<<"\n\n"; 
				// logFile<<"\n\n******************************************            ##";
				// logFile<<"\nLine:"<<lineNumber<<": declaration_list: declaration_list error"<<"\n\n"; 

			}
			| declaration_list COMMA ID{
				///                       assembly code er jonno                     ~~~~~~~~///

				string currVarName = $3->getSymbolName(); 

                string currScopeStr = symTable->getCurrentScopeId(); 
                string fullVarName1 = variableNameGenerator(currVarName, currScopeStr); 
                //cout<<"# new varName:" << fullVarName1<<"\n"; 

				dataVariables.push_back(fullVarName1);

				string varCode1 = "\t" + fullVarName1 + " dw ?" + "\n";  
				/* 
				simply ami ki chai? 
					a1 dw ?
					b1 dw ?  
				*/ 
				dataVariablesCode += varCode1; 

                //****  a11 erokom variable NAME hobe                  asm Code er jonno  ~~~~~~~~~~~~
                //$3->setSymbol---Name(fullVarName1); ----- bad; pore insertSym e 


				string declaration_list_name = $1->getSymbolName()+ "," + $3->getSymbolName(); 
				$$ = new SymbolInfo(declaration_list_name , "declaration_list"); 
				//new SymbolInfo*() hobe NA; karon ota to constructor ; but ekhane $$ ekta pointer 
				//SymbolInfo(string name, string type)

				

				
				//int y; 
				//int x,y; ei ID = y age ashle Error dekhabe 
				//** focus : key = ID = y (ja comma er por ) = $3 kintu *** 
				string key = $3->getSymbolName(); 
				string type = $3->getSymbolType(); 
				 
				//*** FOCUS : VOID hole: insert hosse NA 
		
				if(typeSpecifierYFile!= "VOID")
				{
					SymbolInfo* insertSym = symTable->InsertPointer(key,type);
					if(insertSym != NULL)
					{
						//so INSERT correctly hoise 
						insertSym->setWhatTypeID("VARIABLE");  

						//--------- a--> a11 
						insertSym->setAssemblyName(fullVarName1); 

						insertSym->setWhatTypeSpecifier(typeSpecifierYFile); 
						insertSym->setSizeArray(-1); 						

					}
					else if(insertSym == NULL){
						logFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
						errorFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
						//Error at line 6: Multiple declaration of c
						////so INSERT correctly hoy NAI  
						semanticErrorCount++; 
						errorCount++; 
					}

				}
				//cout<<"\n##Line "<<lineNumber<<": declaration_list : declaration_list COMMA ID\n\n"; 
				logFile<<"Line "<<lineNumber<<": declaration_list : declaration_list COMMA ID\n\n"; 
				logFile<<$$->getSymbolName()<<"\n\n"; 
				

			}
			| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {

				string currVarName = $3->getSymbolName(); 

				string currScopeStr = symTable->getCurrentScopeId(); 
				string fullVarName1 = variableNameGenerator(currVarName, currScopeStr); 
				// *** now array er code (for declaration insert kori) 

				dataVariables.push_back(fullVarName1);

				
				//string symbolName = fullVarName1 + "[" + $3->getSymbolName() + "]"; 
				//$3->setSymbol---Name(fullVarName1); ---- nope; pore insertSym e 


				string declaration_list_name = $1->getSymbolName()+ "," + $3->getSymbolName() ;
				declaration_list_name = declaration_list_name + "[" + $5->getSymbolName() + "]" ; 
				//int a, b, c[5]
				$$ = new SymbolInfo(declaration_list_name , "declaration_list"); 
				//new SymbolInfo*() hobe NA; karon ota to constructor ; but ekhane $$ ekta pointer 
				//SymbolInfo(string name, string type)

				string key = $3->getSymbolName(); 
				string type = $3->getSymbolType(); 
				
				//*** FOCUS : VOID hole: insert hosse NA 
		
				if(typeSpecifierYFile!= "VOID")
				{
					SymbolInfo* insertSym = symTable->InsertPointer(key,type); 
					if(insertSym != NULL)
					{
						
						insertSym->setWhatTypeSpecifier(typeSpecifierYFile); //mane int naki float ..
							
						insertSym->setWhatTypeID("ARRAY"); 
						
						// asm code er jonno 
						insertSym->setAssemblyName(fullVarName1); 

						string strSizeArr1 = $5->getSymbolName(); 
						int sizeArr = std::stoi(strSizeArr1);
						// cout<<"\n#******arrSymInfo != NULL   : sizeArr =" <<sizeArr<<"\n"; 

						insertSym->setSizeArray(sizeArr); 
						insertSym->arrayInitialize(typeSpecifierYFile); 

					
						string varCode1 = "\t" ; 
						//string strgetSizeArray1 = to_string($1->getSizeArray());
						varCode1 += fullVarName1 + " dw " +  strSizeArr1; 
						varCode1 += " dup (?)"; 
						varCode1 += "\n";  
						dataVariablesCode += varCode1; 

						// c2 dw 3 dup (?)

						

					}
					else if(insertSym == NULL){
						logFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
						errorFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
						//Error at line 6: Multiple declaration of c
						////so INSERT correctly hoy NAI  
						semanticErrorCount++; 
						errorCount++; 
					}

				}
				logFile<<"Line "<<lineNumber<<": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n"; 
				logFile<<$$->getSymbolName()<<"\n\n"; 
			}
			| ID LTHIRD CONST_INT RTHIRD
			 {	

				string currVarName = $1->getSymbolName(); 

				string currScopeStr = symTable->getCurrentScopeId(); 
				string fullVarName1 = variableNameGenerator(currVarName, currScopeStr); 
				// *** now array er code (for declaration insert kori) 

				dataVariables.push_back(fullVarName1);

				
				string symbolName = $1->getSymbolName() + "[" + $3->getSymbolName() + "]"; 
				//$1->setSymbol--Name(fullVarName1); 


				string symbolType = "declaration_list"; 
				$$ = new SymbolInfo(symbolName, symbolType); 
				/* simple array */
			 	// int a[5]; 
				 //$$ = "a[5]","decl_list"

            	string key = $1->getSymbolName(); 
				string type = $1->getSymbolType(); 
				
				//string fullVarName1 = ""; 
				
				if(typeSpecifierYFile != "VOID")
				{
					SymbolInfo* insertSym = symTable->InsertPointer(key,type); 
					if(insertSym != NULL)
					{
							//so INSERT correctly hoise 	arrSymInfo->setWhatTypeID("ARRAY");  
							insertSym->setWhatTypeSpecifier(typeSpecifierYFile); //mane int naki float ..
							
							insertSym->setWhatTypeID("ARRAY");  


							//a[3] ke a11[3] set 
							insertSym->setAssemblyName(fullVarName1); 

							string strsizeArr1 = $3->getSymbolName(); 
							int sizeArr = std::stoi(strsizeArr1);
							// cout<<"\n#******arrSymInfo != NULL   : sizeArr =" <<sizeArr<<"\n"; 

							insertSym->setSizeArray(sizeArr); 
							cout<<"insertSym e: key ="<<key<<" sizeArr="<< sizeArr<<"\n"; 
							insertSym->arrayInitialize(typeSpecifierYFile);

							string varCode1 = "\t" ; 
							//string strgetSizeArray1 = to_string($1->getSizeArray());
							varCode1 += fullVarName1 + " dw " +  strsizeArr1; 
							varCode1 += " dup (?)"; 
							varCode1 += "\n";  
							dataVariablesCode += varCode1; 

							// c2 dw 3 dup (?)


					}
					else if(insertSym == NULL){
						logFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
						errorFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
						semanticErrorCount++; 
						errorCount++; 
					}

				}

				// $1->setSymbol---Name(fullVarName1 + "[" + $3->getSymbolName() + "]"); 

                // $$->setSymbol---Name($1->getSymbolName()); 
				//logFile<< "Line " << lineNumber << ": declaration_list : ID\n\n"; 
            	logFile << "Line "  << lineNumber << ": declaration_list : ID LTHIRD CONST_INT RTHIRD" << "\n\n" ;
				//a[5]
            	logFile << symbolName << "\n\n" ;

				
			} 								
			| ID {

				/*
				in4.txt 
				Line 42: var_declaration : type_specifier declaration_list SEMICOLON

				Error at line 42: Variable type cannot be void

				void e;
				*/

				///                       assembly code er jonno                     ~~~~~~~~///

				string currVarName = $1->getSymbolName(); 

                string currScopeStr = symTable->getCurrentScopeId(); 
                string fullVarName1 = variableNameGenerator(currVarName, currScopeStr); 
                //cout<<"# new varName:" << fullVarName1<<"\n"; 

				dataVariables.push_back(fullVarName1);

				string varCode1 = "\t" + fullVarName1 + " dw ?" + "\n";  
				/* 
				simply ami ki chai? 
					a1 dw ?
					b1 dw ?  
				*/ 
				dataVariablesCode += varCode1; 

                //****  a11= assemblyName                  asm Code er jonno  ~~~~~~~~~~~~
                
				//$1->setSymbol---Name(fullVarName1); 


				string symbolName = $1->getSymbolName(); 
				string symbolType = "ID"; 
				//$$ = $1;///DEFAULT lekha lage NA 
				//*** $$ must be si* karon UPORE defined in %type 
				$$ = new SymbolInfo(symbolName, symbolType);
				
				

		
				string key = $1->getSymbolName(); 
                
				string type = $1->getSymbolType(); 
				
				
				if(typeSpecifierYFile!= "VOID")
				{
					SymbolInfo* insertSym = symTable->InsertPointer(key,type); 
					if(insertSym != NULL)
					{
						//so INSERT correctly hoise 
						insertSym->setWhatTypeID("VARIABLE");  
						insertSym->setWhatTypeSpecifier(typeSpecifierYFile); //mane int naki float ...
						insertSym->setSizeArray(-1); 
						insertSym->setAssemblyName(fullVarName1); 
							
						
					}
					else if(insertSym == NULL){
						logFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
						errorFile<<"Error at line "<<lineNumber<<": Multiple declaration of "<<key<<"\n\n"; 
						semanticErrorCount++; 
						errorCount++; 
					}

				}

				
				logFile<< "Line " << lineNumber << ": declaration_list : ID\n\n"; 
				logFile<<symbolName<<"\n\n";  
				
				

			}
				

 		  ;



statements: statement
		{
			logFile<< "Line " << lineNumber << ": statements : statement\n\n"; 
			//Line 11: statements : statements statement
			string symbolName = $1->getSymbolName() ; 
			string symbolType = "statements";
			
			$$ = new SymbolInfo(symbolName, symbolType);

            string stmt_code = $1->getAssemblyCode(); 
            //cout<<"statements1: code:"<<stmt_code<<"\n"; 
            

            $$->setAssemblyCode(stmt_code); 

			logFile<<$$->getSymbolName()<<"\n\n";
			
			
		}
		| statements statement
	    {
			logFile<< "Line " << lineNumber << ": statements : statements statement\n\n"; 
			//Line 11: statements : statements statement
			string symbolName = $1->getSymbolName() + $2->getSymbolName(); 
			string symbolType = "statements";
			
			$$ = new SymbolInfo(symbolName, symbolType);

            string stmt_code = $1->getAssemblyCode() + "\n" + $2->getAssemblyCode(); 

            //cout<<"statements2: code:"<<stmt_code<<"\n"; 

            $$->setAssemblyCode(stmt_code); 
			logFile<<$$->getSymbolName()<<"\n\n";
			
		}
				
		; 	  
statement: error{
			// cout<<"\n\n******************************************            ##";
			
			// cout<<"\nLine:"<<lineNumber<<": statement: error"<<"\n\n"; 

			$$ = new SymbolInfo("",""); 
			
		}
		| func_declaration {
			//simply ei func_decl is WRONG ; so bad diye disi 
			$$ = new SymbolInfo("",""); // 
			logFile<<"Error at line "<<lineNumber<<": Function Not Declared in Global scope "<<"\n\n"; 
			errorFile<<"Error at line "<<lineNumber<<": Function Not Declared in Global scope  "<<"\n\n"; 

			semanticErrorCount++; 
			errorCount++; 
			
		}
		| func_definition {
			//simply ei func_decl is WRONG ; so bad diye disi 
			$$ = new SymbolInfo("",""); // 
			logFile<<"Error at line "<<lineNumber<<": Function Not Defined in Global scope "<<"\n\n"; 
			errorFile<<"Error at line "<<lineNumber<<": Function Not Defined in Global scope  "<<"\n\n";
			semanticErrorCount++; 
			errorCount++;

		}
		| var_declaration {
			string symbolName = $1->getSymbolName(); 
			string symbolType = "statement";
			
			$$ = new SymbolInfo(symbolName, symbolType);
            string varCode1 = $1->getAssemblyCode(); 
            $$->setAssemblyCode(varCode1); 

			logFile<< "Line " << lineNumber << ": statement : var_declaration\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n"; 

    	}
		| expression_statement
	  	{
			
			string symbolName = $1->getSymbolName() +"\n"; 
			string symbolType = "statement";
            string stmt_code = $1->getAssemblyCode(); 
            

			
			$$ = new SymbolInfo(symbolName, symbolType);
            //cout<<"stmt_code (expression_statement) = "<<stmt_code<<"\n"; 

            $$->setAssemblyCode(stmt_code); 
			//Line 10: statement : expression_statement
			logFile<< "Line " << lineNumber << ": statement : expression_statement\n\n"; 
            //cout<<"stmt: $$->getAssemblyCode():"<<$$->getAssemblyCode()<<"\n"; 
			logFile<<$$->getSymbolName()<<"\n\n"; 
		}
		| compound_statement{
			symTable->EnterScope();

			symTable->PrintAllScopeTable(logFile);
			logFile<<"\n\n"; 
			symTable->ExitScope(); 
			string symbolName = $1->getSymbolName()+"\n"; 
			string symbolType = "statement";
			
			$$ = new SymbolInfo(symbolName, symbolType);

            string stmt_code = $1->getAssemblyCode(); 
      
            $$->setAssemblyCode(stmt_code); 

			logFile<< "Line " << lineNumber << ": statement : compound_statement\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n"; 
		}
		| FOR LPAREN expression_statement expression_statement expression RPAREN statement
		{
			logFile<<"Line "<<lineNumber<<": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<"\n\n"; 
			string symbolName = $1->getSymbolName() + "(" + $3->getSymbolName() + $4->getSymbolName() + $5->getSymbolName() + ")"; 
			symbolName = symbolName + $7->getSymbolName() ; 
			string symbolType = "statement";
			
			$$ = new SymbolInfo(symbolName, symbolType);

			
			bool forCodeOk = true; 

			if(($3->getSymbolName()==";") || $3->getSymbolName()==";"){
				//ektao ";" hole code ignore
				forCodeOk = false; 

			}

			string forCode1 = ""; 

			if(forCodeOk){

				string labelLoopShuru = newLabelAdd();
                string labelLoopShesh = newLabelAdd();
				// for(i = 0; i<4; i++) { stmt  }
				

				forCode1 += $3->getAssemblyCode(); // i =0 ; er code 
				forCode1 += "\n\t"; 
				forCode1 += labelLoopShuru +":"; 
				forCode1 += $4->getAssemblyCode(); // i<4; er code 
				//forCode1 += "\n\tMOV AX, " + $4->getSymbol--Name(); 
				forCode1 += "\n\tMOV AX, " + $4->getAssemblyName();
				forCode1 += "\n\tCMP AX, 0"; 
				forCode1 += "\n\tJE "+ labelLoopShesh; // *** simply i<4; condition VIOLATE korle CMP e EQUAL to 0 asbe then loop shesh 
				forCode1 += "\n"; 
				forCode1 += $7->getAssemblyCode() ; //stmt er code 
				forCode1 += $5->getAssemblyCode(); // i++ er code  ( focus eta kintu stmt er pore ashtese ; IN ASM code)

				forCode1 += "\tJMP "+ labelLoopShuru ; // loop er shuru te jmp koro 

				forCode1 += "\n\t"; 
				forCode1 += labelLoopShesh + ":"; //for loop er shesh 
				forCode1 += "\n"; 

				// FOR LPAREN expression_statement expression_statement expression RPAREN statement


			}
			$$->setAssemblyCode(forCode1); 


			logFile<<$$->getSymbolName()<<"\n\n"; 



		}
		| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {

			string symbolName = "if (" + $3->getSymbolName() + ")"+$5->getSymbolName(); 
			string symbolType = "statement";
			
			$$ = new SymbolInfo(symbolName, symbolType);

			string labelFalse = newLabelAdd();



			string if_code1 = $3->getAssemblyCode(); 
			//if_code1 += "\n\tMOV AX, "+ $3->getSymbol---Name(); 
			if_code1 += "\n\tMOV AX, "+ $3->getAssemblyName();
			if_code1 += "\n\tCMP AX, 0"; 
			/// 0 hole tahole FALSE e jabe; 
			if_code1 += "\n\tJE " + labelFalse; 
			if_code1 += "\n"; 
			if_code1 += $5->getAssemblyCode(); //stmt er code gula 
			if_code1 += "\n\t"; 
			if_code1 += labelFalse +":"; 
			if_code1 += "\n"; 

			$$->setAssemblyCode(if_code1); 


			//Line 34: statement : IF LPAREN expression RPAREN statement
			logFile<<"Line "<<lineNumber<<": statement : IF LPAREN expression RPAREN statement"<<"\n\n"; 
			
			/*
			if (c<a[0]){
			c=7;
			}
			*/
			logFile<<$$->getSymbolName()<<"\n\n"; 

		}
		| IF LPAREN expression RPAREN statement ELSE statement	{
			
			string symbolName = "if (" + $3->getSymbolName() + ")"+$5->getSymbolName() + "else" +"\n" + $7->getSymbolName();  
			string symbolType = "statement";
			
			$$ = new SymbolInfo(symbolName, symbolType);

			
			string labelFalse = newLabelAdd();
			string labelEnd1 = newLabelAdd();
			

			string if_code1 = $3->getAssemblyCode(); 
			//if_code1 += "\n\tMOV AX, "+ $3->getSymbol--Name(); 
			if_code1 += "\n\tMOV AX, "+ $3->getAssemblyName(); 

			if_code1 += "\n\tCMP AX, 0"; 
			/// 0 hole tahole FALSE e jabe; 
			if_code1 += "\n\tJE " + labelFalse; // karon  labelFALSE e else er code 
			if_code1 += "\n"; 
			if_code1 += $5->getAssemblyCode(); //if er stmt 
			if_code1 += "\n\tJMP "+ labelEnd1; //karon if hoye gele sheshe chole jabe END e 
			if_code1 += "\n\t"; 
			if_code1 += labelFalse +":" + $7->getAssemblyCode(); // labelFALSE e else er code 
			if_code1 += "\n\t"; 
			if_code1 += labelEnd1 + ":"; 
			if_code1 += "\n"; 


			$$->setAssemblyCode(if_code1); 


			logFile<<"Line "<<lineNumber<<": statement : IF LPAREN expression RPAREN statement ELSE statement"<<"\n\n"; 

			logFile<<$$->getSymbolName()<<"\n\n"; 
			
		}
		| WHILE LPAREN expression RPAREN statement{
			
			string symbolName = "while (" + $3->getSymbolName() + ")" + $5->getSymbolName()   ; 
			string symbolType = "statement";
 
			$$ = new SymbolInfo(symbolName, symbolType);
			/*
			i = 0;  
			while(i<4){
				i++; 
			}
			MOV AX, 0
			MOV I2, AX
			; ----------------- while code ------
			L2:
			---- i<4 check 
			MOV AX, I2
			CMP AX, 4
			JL L0
			MOV AX, 0
			MOV T0, AX
			JMP L1
			L0:
			MOV AX, 1
			MOV T0, AX
			L1:
			---------------------------    ei upor tuku     (i<4 er code )
			MOV AX, T0
			CMP AX, 0
			JE L3
			---------
			MOV AX, I2
			MOV T1, AX						ETA i++; statement er code 
			INC I2
			------------------
			JMP L2
			L3:

			*/ 
			string labelShuru = newLabelAdd();
            string labelSheshe = newLabelAdd();
			string while_code1 = "\t"; 
			while_code1 += labelShuru + ":\n"; // L2: ei label ta 
			while_code1 += $3->getAssemblyCode(); 
			// T1 = i<4 true or false ta hold kortese 

			
			//while_code1 += "MOV AX, " + $3->getSymbol--Name(); 
			while_code1 += "\tMOV AX, " + $3->getAssemblyName(); 
			while_code1 += "\n\tCMP AX, 0\n\tJE "+ labelSheshe; 
			while_code1 += "\n"; 
			while_code1 += $5->getAssemblyCode(); 

			while_code1 += "\tJMP " + labelShuru; 
			while_code1 += "\n\t";
			while_code1 += labelSheshe + ":\n"; 

			$$->setAssemblyCode(while_code1); 

			logFile<<"Line "<<lineNumber<<": statement : WHILE LPAREN expression RPAREN statement"<<"\n\n"; 

			logFile<<$$->getSymbolName()<<"\n\n"; 


		}
		|	PRINTLN LPAREN ID RPAREN SEMICOLON	{

			logFile<<"Line "<<lineNumber<<": statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<"\n\n"; 
			//Line 52: statement : PRINTLN LPAREN ID RPAREN SEMICOLON
			//printf(c);
			string symbolName = "printf(" + $3->getSymbolName() + ")"+";\n" ; 
			string symbolType = "statement";

            //cout<<"\n\n\t\t(((( statement : PRINTLN\n\n"; 
 
			$$ = new SymbolInfo(symbolName, symbolType);
      
            

            //cout<<"\n\n*********************stmt: println_code: "<<$$->getAssemblyCode()<<"\n"; 

			string key = $3->getSymbolName(); 
			SymbolInfo* symInfo = symTable->currentScopeLookUp(key); ///println 
		
			if(symInfo==NULL){ 
				symInfo = symTable->LookUpOff1(key); 
			}
			
			if(symInfo==NULL){
				//Error at line 12: Undeclared variable b
				logFile<<"Error at line "<<lineNumber<<": Undeclared variable "<<key<<"\n\n"; 
				errorFile<<"Error at line "<<lineNumber<<": Undeclared variable "<<key<<"\n\n"; 

				semanticErrorCount++; 
				errorCount++; 
			}
			/*
			in assignop: varName1:a1        varValue1:25

			PRINTLN er shomoy a11 toiri hoye jasse;
			# new varName: a11
			*/ 

			//$$->setAssemblyName(symInfo->getAssemblyName()); 
			string printlnVar1 = symInfo->getAssemblyName(); 

            //string currScopeStr = symTable->getCurrentScopeId(); 
            //string fullVarName1 = variableNameGenerator(currVarName, currScopeStr); ---hobe NA 
			//karon ota to already SymTable e inserted asei  ------------------->

			/*
			PUSHA
			PUSH RET_ADDRESS
			PUSH a12
			CALL PRINTLN ; notun kisu pop lagbe na; PRINTLN kisu return kore NA 
			POP RET_ADDRESS
			POPA

			*/
			string println_code = "\n\tPUSHA\n\tPUSH RET_ADDRESS"; 
            println_code += "\n\tPUSH " + printlnVar1; 
            println_code += "\n\tCALL PRINTLN\n\n"; 
			println_code += "\n\tPOP RET_ADDRESS\n\tPOPA\n"; 
            
            $$->setAssemblyCode(println_code); 
			logFile<<$$->getSymbolName()<<"\n\n"; 
			

		}
		|RETURN expression SEMICOLON {
			
			//function er jonno return type checking
			isFunctionReturning = true; 
			string symbolName = "return " + $2->getSymbolName() + ";\n" ; 
			string symbolType = "statement";
			//cout<<"\n\n********statement: RETURN expression SEMICOLON\n"; 
			$$ = new SymbolInfo(symbolName, symbolType);

			currentFunctionReturnType = $2->getWhatTypeSpecifier(); 


			string returnasmcode  = $2->getAssemblyCode(); 
			// then FUNC return er jonno variable push korte hobe ***** 
			
			//returnasmcode += "\n\tPUSH "+ $2->getSymbol--Name(); 
			returnasmcode += "\n\tPUSH "+ $2->getAssemblyName(); 
		
			string retLabel1 = currentFunctionName + "_ret"; 
			returnasmcode += "\n\tJMP "+ retLabel1; 
			returnasmcode += "\n"; 
			//cout<<"returnasmcode :"<<returnasmcode<<"\n"; 
			$$->setAssemblyCode(returnasmcode); 

			logFile<< "Line " << lineNumber << ": statement : RETURN expression SEMICOLON\n\n"; 
			logFile<<symbolName<<"\n\n"; 
		} 
	  	;
expression_statement: expression SEMICOLON
		{
			logFile<<"Line "<<lineNumber<<": expression_statement : expression SEMICOLON\n\n"; 
			//Line 10: expression_statement : expression SEMICOLON

            string exprCode1 = $1->getAssemblyCode(); 
            

			string symbolName = $1->getSymbolName() + ";"  ; 
			string symbolType = "expression_statement";
			$$ = new SymbolInfo(symbolName, symbolType);

            //cout<<"exprCode1="<<exprCode1<<"\n"; 
            $$->setAssemblyCode(exprCode1);
			$$->setAssemblyName($1->getAssemblyName()); 
			
			string expressionDeclaredType = $1->getWhatTypeSpecifier(); 
			$$->setWhatTypeSpecifier(expressionDeclaredType); 
			logFile<<$$->getSymbolName()<<"\n\n";

		} 
		| SEMICOLON	{
			logFile<<"Line "<<lineNumber<<": expression_statement : SEMICOLON\n\n"; 
			//Line 10: expression_statement : expression SEMICOLON

			string symbolName = ";"  ; 
			string symbolType = "expression_statement";
			$$ = new SymbolInfo(symbolName, symbolType);

			
			logFile<<$$->getSymbolName()<<"\n\n";

		}
		;
	 
 expression: logic_expression	 {
			$$ = $1; //default ei ashe 
			$$->setAssemblyCode($1->getAssemblyCode()); 
			$$->setAssemblyName($1->getAssemblyName()); 
			logFile<< "Line " << lineNumber << ": expression : logic expression\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n";
		}
		| variable ASSIGNOP logic_expression 
		{
			string symbolName = $1->getSymbolName() + "=" + $3->getSymbolName()  ; 
			string symbolType = "expression";
			//cout<<"\n##variable ASSIGNOP logic_expression  ami ei rule e\n"; 
			$$ = new SymbolInfo(symbolName, symbolType);
			logFile<<"Line "<<lineNumber<<": expression : variable ASSIGNOP logic_expression\n\n";;
			//Line 10: expression : variable ASSIGNOP logic_expression
			 

			string variableDeclaredType = $1->getWhatTypeSpecifier(); 
			string logic_expression_type = $3->getWhatTypeSpecifier(); 
			// cout<<"\n\n*****Line:"<<lineNumber<<"**variableDeclaredType =" << variableDeclaredType<<" logic_expression_type ="<<logic_expression_type<<"\n"; 
			
			bool typeMismatch = false; 
			//if(variableDeclaredType != logic_expression_type ) typeMismatch = true; 

			if(variableDeclaredType=="INT" && logic_expression_type=="FLOAT"){
				typeMismatch = true; 
			}
			

			// ******************** SPECIAL CASE ************************
			// float d = 5; eta OK;  basically float can be assigned to INT ; log3.txt ****
			// b = 5; b : undeclared												in2.txt
			// dd = foo(c); foo : undeclared     								    in4.txt
			//then ar type mismatch Error dey NA ; 
			
			//if(variableDeclaredType == "" || logic_expression_type == "") typeMismatch = true; PREV SILO  
			if(variableDeclaredType == "" || logic_expression_type == "") typeMismatch = false; 

			if(variableDeclaredType=="FLOAT" && logic_expression_type=="INT"){
				typeMismatch = false; 
			}

			if(typeMismatch==true){
				//"	Error at line 8: Type Mismatch
				logFile<<"Error at line "<<lineNumber<< ": Type Mismatch\n\n"; 
				errorFile<<"Error at line "<<lineNumber<< ": Type Mismatch\n\n";
				semanticErrorCount++; 
				errorCount++; 
			}
			//cout<<"logic_expression_type = "<<logic_expression_type<<" symbolName:"<<symbolName<<"\n"; 

			if(logic_expression_type=="VOID"){
				//eg: c[2]=foo4(c[1]) here : foo4: returns VOID 
				//Error at line 57: Void function used in expression
				logFile<<"Error at line "<<lineNumber<<": Void function used in expression"<<"\n\n"; 
				errorFile<<"Error at line "<<lineNumber<<": Void function used in expression"<<"\n\n"; 
				semanticErrorCount++; 
				errorCount++; 
			}

			bool isVariable = false; 

			string varCode1 = ""; 

			int sizeArr = $1->getSizeArray(); 
			//cout<<"$1="<<$1->getSymbolName()<<"   ; size ="<<sizeArr<<"\n"; 
			if(sizeArr==-1) isVariable = true; 

			if(isVariable){
				// a = 5;            variable (NOT array) er ASSIGN assembly code               ~~~~~~~///
            
				//a = 5;  variable ASSIGNOP logic_expression 
				//variable AND logic_expression  Er code kintu "+" hobe 
				string varValue1 = $3->getAssemblyName(); //5 
				string varName1 = $1->getAssemblyName(); //a 

				//cout<<"in assignop: varName1:"<<varName1<<"\tvarValue1:"<<varValue1<<"\n"; 

				// a= 5+10; 
				// so first e $1 and $3 er code ta add 


				varCode1 += $1->getAssemblyCode() + $3->getAssemblyCode(); 
				varCode1 += simpleVariableAssignCode(varName1, varValue1); 
				//cout<<"\nsimpleVariableAssignCode="<<varCode1<<"\n"; 


				/// ***          a point                   ***
				// a = 5+10; ekhon symbolName kintu "a" i thakbe 
				$$->setAssemblyName($1->getAssemblyName()); 

			}
			else{
				// c[3]  = 15; 
				// array hole EXTRA CASE 

				cout<<"this is array code:**\n"; 
				
				//string varValue1 = $3->getSymbol--Name(); //15 

				string varValue1 = $3->getAssemblyName(); //15 
				//$1->getSymbol--Name(); //c12[3]

				// actually hobe MOV c12[BX], AX but ashtese : MOV c12[3][BX], AX ~~~

				//string varName1 = assignopArraySizeRemove($1->getSymbol--Name()); 

				string varName1 = assignopArraySizeRemove($1->getAssemblyName()); 

				string tempVarName1 = newTemporaryVariable(); 
				newTemporaryVariableCodeAdd(tempVarName1); 

				varCode1 += $3->getAssemblyCode() + $1->getAssemblyCode(); 
				varCode1 += "\n\tMOV AX, " + varValue1; 
				varCode1 += "\n\tMOV " + varName1 + "[BX], AX\n\t"; 
				varCode1 += "MOV "+ tempVarName1 + ", AX\n"; 

				$$->setAssemblyName(tempVarName1); 


				/* 
				MOV BX, 3
				ADD BX, BX
				---- ei part tuku c[3] er shomoy i peye gesi AMI 
				MOV AX, 15
				MOV C2[BX], AX
				MOV T1, AX

				T1 : notun temp variable; 
				*/ 
				

			}


            $$->setAssemblyCode(varCode1); 
			

			// x = 2 ; so x er jei type ei expression ero eki type hobe 
			$$->setWhatTypeSpecifier(variableDeclaredType); 
			logFile<<symbolName<<"\n\n";
				
			

			
		}
	
	   ;
			
logic_expression: rel_expression {
			$$ = $1; //default ei ashe 

			string logicexp1 = $1->getAssemblyCode(); 
			$$->setAssemblyCode(logicexp1); 
			$$->setAssemblyName($1->getAssemblyName()); 
			//cout<<"logicexp1 code :"<<logicexp1<<"\n"; 
			logFile<< "Line " << lineNumber << ": logic_expression : rel_expression\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n";
		} 
		| rel_expression LOGICOP rel_expression {

            string symbolName = $1->getSymbolName() + $2->getSymbolName()  + $3->getSymbolName(); 
			string symbolType = "logic_expression";
			
			$$ = new SymbolInfo(symbolName, symbolType);
            //Line 19: logic_expression : rel_expression LOGICOP rel_expression

			// cout<<"rel1 : "<<$1->getSymbolName()<<" type:"<<$1->getWhatTypeSpecifier()<<"\n";
			// cout<<"rel2: "<<$3->getSymbolName()<<" type:"<<$3->getWhatTypeSpecifier()<<"\n";

			string typeSpecifier1 = $1->getWhatTypeSpecifier(); 
			string typeSpecifier2 = $3->getWhatTypeSpecifier();


			if(typeSpecifier1=="VOID" || typeSpecifier2 == "VOID")
			{
				logFile<<"Error at line "<<lineNumber<<": Void function used in expression"<<"\n\n"; 
				errorFile<<"Error at line "<<lineNumber<<": Void function used in expression"<<"\n\n"; 
				semanticErrorCount++; 
				errorCount++; 
			}

			/* 
			a = b || foo(); er jonno paitesi: 
			rel1 : b type:INT
			rel2: foo() type:VOID
			*/ 
			$$->setWhatTypeSpecifier("INT"); //5 < 4 && 8 ; return type bool ; so INT sort of  
			//OR: 5&& 8 etao logical expression 
			$$->setWhatTypeID("VARIABLE"); 

			///             asm code for LOGCIOP   ~~~~~~~~~~

			string labelFalse = newLabelAdd();
            string labelSheshe = newLabelAdd();

			string tempVarName1 = newTemporaryVariable(); 

			newTemporaryVariableCodeAdd(tempVarName1); 

			string logicop_code1 = $1->getAssemblyCode() + $3->getAssemblyCode(); 

			string logic_operator = $2->getSymbolName(); 

			/*
			c = 2|| 5;  -- er code 
			MOV AX, 5
			MOV A2, AX
			MOV AX, 2
			MOV B2, AX
			;          || er code 
			MOV AX, A2
			CMP AX, 0
			JNE L0                ; ------- labelTrue 
			MOV AX, B2
			CMP AX, 0
			JNE L0
			MOV AX, 0
			MOV T0, AX
			JMP L1
			L0:							; ---- labelTrue 
			MOV AX, 1
			MOV T0, AX
			L1:							; ---- labelSheshe 
			MOV AX, T0
			MOV C2, AX
			*/ 
			
			// OR means first erta true hole sheshe chole jabo
			// ********          focus: OR er khetre   labelFalse mane ACTUALLY labelTrue

			if(logic_operator=="||"){
				
				// AND MEANS both true hole kebol ok; so first ta false hole end e jao 
				//logicop_code1 += "\n\tMOV AX, " + $1->getSymbol--Name() + "\n\tCMP AX, 0"; 
				logicop_code1 += "\n\tMOV AX, " + $1->getAssemblyName() + "\n\tCMP AX, 0"; 
				logicop_code1 += "\n\tJNE " + labelFalse ; //ACTUALLY labelTrue

				//logicop_code1 += "\n\tMOV AX, " + $3->getSymbol--Name(); 
				logicop_code1 += "\n\tMOV AX, " + $3->getAssemblyName(); 

				logicop_code1 += "\n\tCMP AX, 0" ; 
				logicop_code1 +=  "\n\tJNE " + labelFalse ; //ACTUALLY labelTrue

				logicop_code1 += "\n\tMOV AX, 0\n\tMOV " + tempVarName1 + ", AX" + "\n\tJMP " + labelSheshe; /// *** both false hole 
				
				logicop_code1 += "\n\t"; 

				logicop_code1 += labelFalse + ":"; //ACTUALLY labelTrue

				logicop_code1 += "\n\tMOV AX, 1"; 
				
				logicop_code1 += "\n\tMOV "+ tempVarName1 + ", AX\n\t"; 

				logicop_code1 += labelSheshe + ":"; 

				logicop_code1 += "\n"; 


			} 
			else if(logic_operator=="&&"){
				
				// AND MEANS both true hole kebol ok; so first ta false hole end e jao 
				//logicop_code1 += "\n\tMOV AX, " + $1->getSymbol--Name() + "\n\tCMP AX, 0"; 
				logicop_code1 += "\n\tMOV AX, " + $1->getAssemblyName() + "\n\tCMP AX, 0";
				logicop_code1 += "\n\tJE " + labelFalse ; 

				//logicop_code1 += "\n\tMOV AX, " + $3->getSymbol--Name(); 
				logicop_code1 += "\n\tMOV AX, " + $3->getAssemblyName(); 

				logicop_code1 += "\n\tCMP AX, 0" ; 
				logicop_code1 += "\n\tJE " + labelFalse ; 

				logicop_code1 += "\n\tMOV AX, 1\n\tMOV " + tempVarName1 + ", AX" + "\n\tJMP " + labelSheshe; 
				
				logicop_code1 += "\n\t"; 

				logicop_code1 += labelFalse + ":"; 

				logicop_code1 += "\n\tMOV AX, 0"; 
				
				logicop_code1 += "\n\tMOV "+ tempVarName1 + ", AX\n\t"; 

				logicop_code1 += labelSheshe + ":"; 

				logicop_code1 += "\n"; 


			}
			/*
				a = 5; 
				b = 2; 
				c = a&&b; 

			MOV AX, 5
			MOV A2, AX
			MOV AX, 2
			MOV B2, AX

			;        && er code 
			MOV AX, A2
			CMP AX, 0 ;   first ta ki 0 kina? if 0 then ekdom sheshe jao 
			JE L0
			MOV AX, B2
			CMP AX, 0 ;      second ta ki 0 kina? if 0 then ekdom sheshe jao; 
			JE L0
			MOV AX, 1			; ********** ektao false NA ; so T1 = 1 koro 
			MOV T0, AX
			JMP L1
			L0:         ---        label false 
			MOV AX, 0
			MOV T0, AX    ---           output = temp1 = 0 koro 
			L1:

			;       assign er code 
			MOV AX, T0
			MOV C2, AX
			*/ 
			$$->setAssemblyCode(logicop_code1); 
            
			$$->setAssemblyName(tempVarName1); 
			//$$->setSymbol---Name(tempVarName1);




			logFile<< "Line " << lineNumber << ": logic_expression : rel_expression LOGICOP rel_expression\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n";
           
   		 }
	
		;
			
rel_expression: simple_expression {
			$$ = $1; //default ei ashe 

			$$->setAssemblyCode($1->getAssemblyCode()); 
			$$->setAssemblyName($1->getAssemblyName()); 
			logFile<< "Line " << lineNumber << ": rel_expression : simple_expression\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n";  
		}
		| simple_expression RELOP simple_expression	{

			string symbolName = $1->getSymbolName() + $2->getSymbolName()  + $3->getSymbolName(); 
			string symbolType = "rel_expression";
			
			$$ = new SymbolInfo(symbolName, symbolType);
            //Line 19: rel_expression : simple_expression RELOP simple_expression
	
			$$->setWhatTypeSpecifier("INT"); //5 < 4 ; return type bool ; so INT sort of 
			$$->setWhatTypeID("VARIABLE"); 

			int operationNo1 = 0; 
			if($2->getSymbolName()=="==") operationNo1 = 1; 
			else if($2->getSymbolName()=="<") operationNo1 = 2; 
			else if($2->getSymbolName()=="<=") operationNo1 = 3; 
			else if($2->getSymbolName()==">") operationNo1 = 4; 
			else if($2->getSymbolName()==">=") operationNo1 = 5; 
			else if($2->getSymbolName()=="!=") operationNo1 = 6; 


		
			
			//string oper1 = $1->getSymbol--Name(); 
			string oper1 = $1->getAssemblyName(); 
			//string oper2 = $3->getSymbol--Name(); 
			string oper2 = $3->getAssemblyName(); 

			// shob relop er common code; 
			string relop_code1 = $1->getAssemblyCode() + $3->getAssemblyCode(); 
			relop_code1 += "\n\tMOV AX, "+ oper1 ; 
			relop_code1 += "\n\tCMP AX, " + oper2; 
			relop_code1 += "\n"; 

			string tempVarName1 = newTemporaryVariable(); 

			newTemporaryVariableCodeAdd(tempVarName1); 

			// b= 2<5; 
			// 2<5 ekhane pabo; eta either "1" or "0"; ta thakbe tempVar = t2 te; tai lagbe 

			string labelTrue = newLabelAdd(); 
			string labelFalse = newLabelAdd(); 

			string allSixRelopAssignCode = ""; 

			allSixRelopAssignCode += "\n\tMOV AX, 0"; 
			allSixRelopAssignCode += "\n\tMOV "+ tempVarName1 +", AX"; 
			allSixRelopAssignCode += "\n\tJMP " + labelFalse ; 
			allSixRelopAssignCode += "\n\t"; 
			allSixRelopAssignCode += labelTrue + ":\n\tMOV AX, 1"; 
			allSixRelopAssignCode += "\n\tMOV "+  tempVarName1 + ", AX\n\t"; 
			allSixRelopAssignCode += labelFalse + ":\n"; 


			switch(operationNo1) {
				case 1 :
					//"=="
					relop_code1 += "\n\tJE "+ labelTrue; 
					relop_code1 += allSixRelopAssignCode;

					
					break;

				case 2 :
					cout << "RELOP less than" << endl;
					//JL/JNGE Jump if less than Jump if not greater than or equal to
					relop_code1 += "\n\tJNGE "+ labelTrue; // mane < hole oi label e jump 
					/*
					MOV AX, 22
					CMP AX, 5

					JNGE LABEL1
					MOV AX, 0
					MOV t1, AX
					JMP LABEL2
					LABEL1:
					MOV AX, 1
					MOV t1, AX
					LABEL2:
					*/ 
					relop_code1 += allSixRelopAssignCode; 					
					

					break;
				case 3 :

					//"<="
					//JLE/JNG Jump if less than or equal; Jump if not greater than
					relop_code1 += "\n\tJNG "+ labelTrue; // mane <= hole oi label e jump 
					relop_code1 += allSixRelopAssignCode; 					
					
					break;
				case 4 :
					//">"
					//JG/JNLE Jump if greater than Jump if not less than or equal to

					relop_code1 += "\n\tJNLE "+ labelTrue; 
					relop_code1 += allSixRelopAssignCode;
					break;
				case 5 :
					//">="
					//JGE/JNL Jump if greater than or equal to Jump if not less than
					relop_code1 += "\n\tJNL "+ labelTrue; 
					relop_code1 += allSixRelopAssignCode;
					
					break;
				case 6 :
					//"!="
			
					relop_code1 += "\n\tJNE "+ labelTrue; 
					relop_code1 += allSixRelopAssignCode;
					
					break;
				default :
					cout << "Relop Operation Not found" << endl;
			}
			//==;  < ; <= ; > ; >=      5ta choice er code 
			
			//$$->setSymbol---Name(tempVarName1);
			$$->setAssemblyName(tempVarName1);  
			//simply t1 e "1" or "0" thakbe 
			$$->setAssemblyCode(relop_code1); 

			
			logFile<< "Line " << lineNumber << ": rel_expression : simple_expression RELOP simple_expression\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n";
            
            
  		}
		;
				
simple_expression: term {
			$$ = $1; //default ei ashe 
			
			$$->setAssemblyCode($1->getAssemblyCode()); 
			//cout<<"simple_expression: term: $$->getWhatTypeSpecifier()"<< $$->getWhatTypeSpecifier()<<"\n"; 
			logFile<< "Line " << lineNumber << ": simple_expression : term\n\n"; 
			logFile<<$$->getSymbolName()<<"\n\n";  
		}
		| simple_expression ADDOP term{
			string symbolName = $1->getSymbolName() + $2->getSymbolName()  + $3->getSymbolName(); 
			string symbolType = "simple_expression";
			//simple_expression : simple_expression ADDOP term
			$$ = new SymbolInfo(symbolName, symbolType);
			logFile<< "Line " << lineNumber << ": simple_expression : simple_expression ADDOP term\n\n"; 
			logFile<<symbolName<<"\n\n"; 

			//y = x -5; so x-5 etay simple_expression: x
			//simple_expression basically factor: variable rule thekei ashbe 
			//x - 5; 
			string varType = $1->getWhatTypeSpecifier(); 
			string termType = $3->getWhatTypeSpecifier(); //5--> INT hobe 

			string simpleExprType = ""; 
			if(varType=="FLOAT" || termType=="FLOAT")
			{
				simpleExprType = "FLOAT"; 
				 
			}
			else if(varType=="INT" && termType == "INT"){
				simpleExprType = "INT"; 
			}

			// ***  void kina ektao ***
			if(varType=="VOID" || termType=="VOID"){
				simpleExprType = "VOID"; 
			}
			//cout<<" simple_expression ADDOP term: simpleExprType= "<<simpleExprType<<"\n"; 
			$$->setWhatTypeSpecifier(simpleExprType);
			$$->setWhatTypeID("VARIABLE"); 

			//	newTemporaryVariableCodeAdd add kora lagbe ; 
			// +, - 2tar assembly code different 
			string fullVarName1 = newTemporaryVariable(); 

			newTemporaryVariableCodeAdd(fullVarName1); 

			string addoptype1 = $2->getSymbolName(); 
			bool isPlus = true; // + hole 
			if(addoptype1=="-") isPlus = false; 

			// $1 and $3 te code thakte pare; tao add kori 
			string addopCode1 = $1->getAssemblyCode() + $3->getAssemblyCode(); 

			if(!isPlus){
				/*
				MOV AX, 2
				SUB AX, 20
				MOV T0, AX
				----- a = 2-20; 
				MOV AX, T0
				MOV A2, AX
				*/ 
				addopCode1 += "\tMOV AX, "; 
				//string val1 = $1->getSymbol--Name(); 
				string val1 = $1->getAssemblyName(); //2  = simp-exp theke ja pabo 
				//string val2 = $3->getSymbol---Name(); 
				string val2 = $3->getAssemblyName(); //20 = term theke ja pabo 

				addopCode1 += val1+"\n\tSUB AX, " + val2 + "\n\tMOV " + fullVarName1 + ", AX\n";


			}
			else if(isPlus){
				/*
				simply: 
				MOV AX, 5
				ADD AX, 10
				MOV T1, AX
				--------- (bakita assign er jonno)
				MOV AX, T1
				MOV A11, AX
				*/ 
				addopCode1 += "\tMOV AX, "; 
				string val1 = $1->getAssemblyName(); //5  = simp-exp theke ja pabo 
				string val2 = $3->getAssemblyName(); //10 = term theke ja pabo 
				addopCode1 += val1+"\n\tADD AX, " + val2 + "\n\tMOV " + fullVarName1 + ", AX\n";

			}

			/// forus : a= 5 + 10; t1 = 15 hold kortese ; 
			/// so simp-expr er symbol kintu "t1" hoye jabe (asm code er jonno)

			// eta NA korle asm code hoto : MOV AX, 5+10 
			
			//$$->setSymbol--Name(fullVarName1); 
			$$->setAssemblyName(fullVarName1); 
			$$->setAssemblyCode(addopCode1); 
			

						
		}	
		;
					
term:	unary_expression {
		$$ = $1; //default ei ashe 
		
		$$->setAssemblyCode($1->getAssemblyCode()); 
		$$->setAssemblyName($1->getAssemblyName()); 
		logFile<< "Line " << lineNumber << ": term : unary_expression\n\n"; 
		logFile<<$$->getSymbolName()<<"\n\n";  
	}
	| term MULOP unary_expression
	{
		
		logFile << "Line " << lineNumber << ": term : term MULOP unary_expression" << "\n\n";
		//Line 19: term : term MULOP unary_expression
		
		string symbolName = $1->getSymbolName() + $2->getSymbolName()  + $3->getSymbolName(); 
		//MULOP er yytext = * automatic i thakbe 
		string symbolType = "term";

		$$ = new SymbolInfo(symbolName, symbolType);
		string typeSpecifier1 = $1->getWhatTypeSpecifier();
		string typeSpecifier2 = $3->getWhatTypeSpecifier(); 
		//cout<<"\n****** typeSpecifier1="<<typeSpecifier1<<" typeSpecifier2 = "<<typeSpecifier2<<"\n"; 
		string typeSpecifier3; 
		if(typeSpecifier1=="FLOAT" || typeSpecifier2 == "FLOAT")
		{
			typeSpecifier3 = "FLOAT"; 

		}
		else if(typeSpecifier1=="INT" && typeSpecifier2 == "INT")
		{
			typeSpecifier3 = "INT"; 
		}
		$$->setWhatTypeSpecifier(typeSpecifier3); 
		$$->setWhatTypeID("VARIABLE"); 

		/**
		Line 54: term : term MULOP unary_expression
		Error at line 54: Void function used in expression
		*/
		if(typeSpecifier1=="VOID" || typeSpecifier2 == "VOID")
		{
			logFile<<"Error at line "<<lineNumber<<": Void function used in expression"<<"\n\n"; 
			errorFile<<"Error at line "<<lineNumber<<": Void function used in expression"<<"\n\n"; 
			semanticErrorCount++; 
			errorCount++; 
		}



		//****** NOW FOR THE MULOP "%" or MOD OPERATOR **************
		string operatorName1 = $2->getSymbolName(); 
		// cout<<"**************** operatorName1 = "<<operatorName1<<"\n"; 
		//yytext theke "%" pay
		if(operatorName1=="%")
		{
			if((typeSpecifier1!= "INT") || (typeSpecifier2 != "INT"))
			{
				//	Error at line 9: Non-Integer operand on modulus operator
				//eg : 2%3.50 
				logFile<<"Error at line "<<lineNumber<<": Non-Integer operand on modulus operator"<<"\n\n";
				errorFile<<"Error at line "<<lineNumber<<": Non-Integer operand on modulus operator"<<"\n\n";
				semanticErrorCount++; 
				errorCount++; 
			} 
			$$->setWhatTypeSpecifier("INT"); 
			//why? int i = 2%3.50; technically mod INT i return korbe ; so eta Error jate na dey 

		}
		string str2; 
		if(operatorName1=="%") str2 = "Modulus"; 
		else if(operatorName1=="/") str2 = "Division"; 

		if(operatorName1=="%" || operatorName1=="/")
		{
			//Error at line 59: Modulus by Zero
			string operand2 = $3->getSymbolName(); 
			if(operand2=="0"){
				logFile<<"Error at line "<<lineNumber<<": "<<str2; 

				logFile<<" by Zero"<<"\n\n"; 

				errorFile<<"Error at line "<<lineNumber<<": "<<str2; 

				errorFile<<" by Zero"<<"\n\n"; 
				semanticErrorCount++; 
				errorCount++;
			}
		}
		/// *** asm code           *** / 
		// ekta temp e 10*5  ei value thakbe 

		string tempVarName1 = newTemporaryVariable(); 

		newTemporaryVariableCodeAdd(tempVarName1); 

		/*
		; MOV AX,-1250 ;  CWD ; sign extend; MOV BX,7; IDIV BX                    -1250/7
		; BX has divisor

		MOV AX, NUM1
		CWD ; sign extend;
		MOV BX, NUM2; 
		IDIV BX; 
		;AX qets quotient, DX has remainder 
		 AX ; bhagfol
		*/
		//term MULOP unary_expression
		
		//cout<<"\n\n\n\n\t\t\t******** term MULOP: $1->asmName():"<<$1->getAssemblyName()<<"\n"; 

		//cout<<"\n\n\n\n\t\t\t\t\tterm MULOP: $1->getSymbolName():"<<$1->getSymbolName()<<"\n"; 
		
		string mul_operator1 = $2->getSymbolName(); 
		string mulop_code1 = $1->getAssemblyCode()+ $3->getAssemblyCode();

		if(mul_operator1=="/"){
			//mulop_code1 += "\tMOV AX, " + $1->getSymbol---Name(); 
			mulop_code1 += "\tMOV AX, " + $1->getAssemblyName(); 
			mulop_code1 += "\n\tCWD"; 
			//mulop_code1 += "\n\tMOV BX, " + $3->getSymbol---Name(); 
			mulop_code1 += "\n\tMOV BX, " + $3->getAssemblyName(); 
			mulop_code1 += "\n\tIDIV BX"; 
 
			mulop_code1 += "\n\tMOV " + tempVarName1 + ", AX\n"; //AX ; bhagfol
			
		}
		else if(mul_operator1=="%"){
			//mulop_code1 += "\tMOV AX, " + $1->getSymbol--Name(); 
			mulop_code1 += "\tMOV AX, " + $1->getAssemblyName(); 
			mulop_code1 += "\n\tCWD"; 
			//mulop_code1 += "\n\tMOV BX, " + $3->getSymbol--Name(); 
			mulop_code1 += "\n\tMOV BX, " + $3->getAssemblyName(); 
			mulop_code1 += "\n\tIDIV BX"; 
 
			mulop_code1 += "\n\tMOV " + tempVarName1 + ", DX\n"; //DX has remainder
			
		}
		else if(mul_operator1=="*"){
			mulop_code1 += "\tMOV AX, " + $1->getAssemblyName(); 
			mulop_code1 += "\n\tMOV BX, " + $3->getAssemblyName(); 
			mulop_code1 += "\n\tIMUL BX"; 
 
			mulop_code1 += "\n\tMOV " + tempVarName1 + ", AX\n"; 
			
		}
		//cout<<"\n**mulop_code1 = "<<mulop_code1<<"\n"; 
		$$->setAssemblyCode(mulop_code1); 

		//$$->setSymbol---Name(tempVarName1);  
		$$->setAssemblyName(tempVarName1); 
		
		/// t1 = 2*5 = 10 VALUE hold korbe 
		/*
		DX kintu output ; karon result = gunfol = DX: AX ; dx = OVERFLOW 	
		;Word form  DX:AX=AX*source
		;MOV x, 8000H ;MOV y, FFFFH
		; MOV AX, x
		; MOV BX, y
		; IMUL BX
		*/ 


		
		
        logFile << $$->getSymbolName() << "\n\n";

		
	}
     ;

unary_expression: ADDOP unary_expression {
	
		
		logFile<<"Line "<<lineNumber<<": unary_expression : ADDOP unary_expression"<<"\n\n"; 
		//Line 35: unary_expression : ADDOP unary_expression
		string symbolName = $1->getSymbolName() + $2->getSymbolName() ; 

		string symbolType = "unary_expression";

		$$ = new SymbolInfo(symbolName, symbolType);
		string typeSpecifier2 = $2->getWhatTypeSpecifier();
		$$->setWhatTypeSpecifier(typeSpecifier2); 

		bool isPlus = false; 
		if($1->getSymbolName() == "+") isPlus = true;

		string unary_code1 = $2->getAssemblyCode();  

		if(isPlus){
			// no temp var require 
			$$->setAssemblyCode(unary_code1); 
			//$$->setSymbol---Name($2->getSymbol---Name()); 
			$$->setAssemblyName($2->getAssemblyName()); 
			

		}
		else if(!isPlus){
			//minus; 
			string tempVarName1 = newTemporaryVariable(); 
			newTemporaryVariableCodeAdd(tempVarName1);
			//unary_code1 += "\n\tMOV AX, " + $2->getSymbol---Name();
			unary_code1 += "\n\tMOV AX, " + $2->getAssemblyName();  
			unary_code1 += "\n\tMOV " + tempVarName1 + ", AX";
			unary_code1 += "\n\tNEG " + tempVarName1; 
			unary_code1 += "\n"; 

			$$->setAssemblyCode(unary_code1); 
			//$$->setSymbol---Name(tempVarName1); 
			$$->setAssemblyName(tempVarName1); 

			//cout<<"\n unary_expression : unary_code1:"<<unary_code1<<"\n unary: tempVarName1:"<<tempVarName1<<"\n"; 

			/*
			c = -a;
			MOV AX, A2
			MOV T0, AX
			NEG T0
			*/


		}

		logFile<<$$->getSymbolName()<<"\n\n";  

	}
	| NOT unary_expression {
		logFile<<"Line "<<lineNumber<<": unary_expression : NOT unary expression"<<"\n\n"; 

		string symbolName = $1->getSymbolName() + $2->getSymbolName() ; 

		string symbolType = "unary_expression";

		$$ = new SymbolInfo(symbolName, symbolType);
		
		// int b = !a; NOT always 0 or 1 dey; bool ; so INT 
		$$->setWhatTypeSpecifier("INT"); 

		string labelSetOne = newLabelAdd();
        string labelSheshe = newLabelAdd();
		string tempVarName1 = newTemporaryVariable(); 

		newTemporaryVariableCodeAdd(tempVarName1); 
		string unary_code1 = $2->getAssemblyCode(); 

		// ***                  asm code                       NOT operator 
		/*
		c = !a;  
		!a         -------->
		MOV AX, A2
		CMP AX, 0
		JE L0
		MOV AX, 0
		MOV T0, AX
		JMP L1
		L0: 
		MOV AX, 1
		MOV T0, AX
		L1:		
		 */ 
		//unary_code1 += "\n\tMOV AX, "+ $2->getSymbol--Name(); 

		unary_code1 += "\n\tMOV AX, "+ $2->getAssemblyName(); 

		unary_code1 += "\n\tCMP AX, 0\n\tJE "+ labelSetOne; 
		
		unary_code1 += "\n\tMOV AX, 0\n\tMOV " +tempVarName1 ; 
		unary_code1 += ", AX\n\tJMP " + labelSheshe; 
		
		unary_code1 += "\n\t"; 
		unary_code1 += labelSetOne + ":"; 
		unary_code1 += "\n\t"; 
		unary_code1 += "MOV AX, 1\n\tMOV "+tempVarName1 ; 
		unary_code1 += ", AX\n\t"; 
		unary_code1 += labelSheshe +":"; 
		unary_code1 += "\n\t"; 

		//$$->setSymbol---Name(tempVarName1); 
		$$->setAssemblyName(tempVarName1); 

		$$->setAssemblyCode(unary_code1); 

		logFile<<$$->getSymbolName()<<"\n\n";  

	}
	| factor {
		$$ = $1; //default ei ashe 
		$$->setAssemblyCode($1->getAssemblyCode()); 
		//cout<<"here : $$->getWhatTypeSpecifier():"<<$$->getWhatTypeSpecifier()<<"\n"; 

		//$$->setSymbol---Name($1->getSymbol----Name()); 
		$$->setAssemblyName($1->getAssemblyName()); 
		logFile<< "Line " << lineNumber << ": unary_expression : factor\n\n"; 
		logFile<<$$->getSymbolName()<<"\n\n";  
	}
		 
	;
	
factor: variable {
		$$ = $1; //default ei ashe 

		string factor_code1 = $1->getAssemblyCode(); 


		

		int sizeArr1 = $$->getSizeArray(); 

		bool isVariable = false; 
		if(sizeArr1 == -1){
			isVariable = true; 
		}
		
		$$->setAssemblyName($1->getAssemblyName()); 
		
		if(!isVariable){
			// tahole array eta 
			string tempVarName1 = newTemporaryVariable(); 

			newTemporaryVariableCodeAdd(tempVarName1); 
			
			//string varName1 = assignopArray--SizeRemove($1->getSymbol---Name());
			string varName1 = assignopArraySizeRemove($1->getAssemblyName()); //c11[10] theke c11 pai 

			factor_code1 += "\n\tMOV AX, " + varName1; 
			factor_code1 += "[BX]\n\tMOV " + tempVarName1; 

			factor_code1 += " , AX\n"; 

			cout<<"fac: var :  *************** array er code:factor_code1 = "<<factor_code1<<"\n"; 

			//$$->setSymbol--Name(tempVarName1); ----- NOPE; 
			$$->setAssemblyName(tempVarName1); 




		}


		$$->setAssemblyCode(factor_code1);
		//cout<<"\n\n\n\t*****factor : variable e : $$->asmName: "<<$$->getAssemblyName()<<"\t $$->symName:"<<$$->getSymbolName()<<"\n";  


		logFile<< "Line " << lineNumber << ": factor : variable\n\n"; 
		logFile<<$$->getSymbolName()<<"\n\n";  
	}
	| ID LPAREN argument_list RPAREN {
		
		logFile<<"Line "<< lineNumber<<": factor : ID LPAREN argument_list RPAREN\n\n"; 
		//Line 20: factor : ID LPAREN argument_list RPAREN

		//var(1,2*3)

		string symbolName = $1->getSymbolName() + "(" + $3->getSymbolName() + ")"; 
		string symbolType = "factor";

		$$ = new SymbolInfo(symbolName, symbolType);
		

		//fucntion usually global scope e ; 
		string funcName1 = $1->getSymbolName(); 
		SymbolInfo* funcSymInfo1 = symTable->LookUpOff1(funcName1); 

		if(funcSymInfo1 != NULL){

			if(funcSymInfo1->getWhatTypeID() == "FUNC_DEFINED")
			{
				string retType1 = funcSymInfo1->getWhatTypeReturn(); 

				$$->setWhatTypeSpecifier(retType1); 
				$$->setWhatTypeReturn(retType1); 

				int noParameter1 = funcSymInfo1->paramSymList.size(); 
				int noParameter2 = argListYFile.size(); 
				// cout<<"\n*******(arg) noParameter1= "<<noParameter1<<" noParameter2 = "<<noParameter2 <<"\n"; 
				bool parameterMatched = true; 
				if(noParameter1 ==  noParameter2 )
				{
					
					int ekhonParameter =  argListYFile.size(); 
					for(int i=0; i<ekhonParameter ; i++)
					{
						string paramType1 = funcSymInfo1->paramSymList[i]->getWhatTypeSpecifier(); 
						string paramType2 = argListYFile[i]->getWhatTypeSpecifier(); 
						
						string paramID1 = funcSymInfo1->paramSymList[i]->getWhatTypeID(); 
						string paramID2 = argListYFile[i]->getWhatTypeID(); 

						//cout<<"\n***************Arg: paramType1 =" <<paramType1<<" paramType2 ="<< paramType2<<"\n"; 
						//cout<<"\n*************** paramID1 =" <<paramID1<<" paramID2 ="<< paramID2<<"\n"; 
						//like ekta ARRAY arekta VARIABLE
						//tahole eta variable: ID ei rule er Error e SIR dekhaise; 
						//if((paramType1 != paramType2 ) || (paramID1 != paramID2)){
						//simply: amar function e INT parameter ; shekhane passing float ; SO .error hobe 
						if(paramType1=="INT" && paramType2=="FLOAT" ){
							parameterMatched = false; 
							//Error at line 45: 1th argument mismatch in function func
							// cout<<"\n\n\n((((((((((( Line "<<lineNumber<<": paramType1 ="<<paramType1<<" paramType2="<<paramType2<<"\n";
							// cout<<"Error at line "<<lineNumber<<": "<<(i+1)<<"th argument mismatch in function ";  
							logFile<<"Error at line "<<lineNumber<<": "<<(i+1)<<"th argument mismatch in function "; 
							logFile<<funcName1<<"\n\n"; 

							errorFile<<"Error at line "<<lineNumber<<": "<<(i+1)<<"th argument mismatch in function "; 
							errorFile<<funcName1<<"\n\n";

							semanticErrorCount++; 
							errorCount++; 
							break; 
						}
					}
					

				}
				else if(noParameter1 !=  noParameter2 )
				{
					//Error at line 49: Total number of arguments mismatch in function correct_foo
					//correct_foo(a)
					logFile<<"Error at line "<<lineNumber<<": Total number of arguments mismatch in function "; 
					logFile<<funcName1<<"\n\n"; 

					errorFile<<"Error at line "<<lineNumber<<": Total number of arguments mismatch in function "; 
					errorFile<<funcName1<<"\n\n"; 
					parameterMatched = false; 
					semanticErrorCount++; 
					errorCount++; 
				}




				//cout<<"***************************Line "<< lineNumber<<": factor : ID LPAREN argument_list RPAREN\n\n"; 
				/*
				int foo(int a, int b){} ekhane 
				pop b11 
				pop a11

				foo(a,b);  a12 , b12
				so ekhane : 
				push a12 
				push b12 
				*/ 
				//ID LPAREN argument_list RPAREN 
				// first er argument_list er code ta nei then append the rest 

				// PORE giye c = foo(a,b); hote pare; 

				//** tai temp variable lagbe ; eg t1 => foo(a,b)
				//assign e MOV AX, t1 hobe 

				string newVar1 = newTemporaryVariable(); 
				//void newTemporaryVariableCodeAdd(string fullVarName1); 
				newTemporaryVariableCodeAdd(newVar1); 


				string arguments_code = $3->getAssemblyCode()+ "\n"; 
				/*
				foo(a,b); 
				int main(){ int a; int b; } a12, b12 
				main proc e 

				PUSH A12
				PUSH B12 
				CALL FOO2 
				POP t1 (jodi return type int hoy)
				*/ 
				//vector<SymbolInfo*> argListYFile;
				arguments_code += "\n\tPUSHA\n\tPUSH RET_ADDRESS";

				//cout<<"\n\n\n\t******funcName1: "<<funcName1<<"\t#  no of param: "<<argListYFile.size()<<"\n"; 
				for(int i=0; i<argListYFile.size(); i++){
					
					//string argVarName1 = argListY--File[i]->getSymbol--Name(); 
					string argVarName1 = argListYFile[i]->getAssemblyName(); 
					//cout<<"argVarName1:"<<argVarName1<<"\n"; 
		
					//already a12 ase; 
					
					arguments_code += "\n\tPUSH "; 
					arguments_code += argVarName1; 

				}
				arguments_code += "\n\tCALL "+funcName1 +"\n"; 
				if(retType1=="VOID"){
					cout<<"VOID func in argument list\n"; 
				}
				else{
					//function return kortese 
					arguments_code += "\n\tPOP "+ newVar1+"\n"; 
				}

				arguments_code += "\tPOP RET_ADDRESS\n\tPOPA\n"; 

				//$$->setSymbol---Name(newVar1); ---- NOPE 
				$$->setAssemblyName(newVar1); 
				// t1 => foo(2,3); hole new symbol kintu t1 ; keno?

				// a= foo(2,3); assembly te likbo MOV AX , t1; MOV a1, AX; 

				$$->setAssemblyCode(arguments_code); 

				
				argListYFile.clear(); 

				

			}
			else if(funcSymInfo1->getWhatTypeID() != "FUNC_DEFINED")
			{
				//cout<<"\n************** func "<< funcName1 <<" NOT DEFINED ****\n"; 
				logFile<<"Error at line "<<lineNumber <<": Undefined function "; 
				logFile<<funcName1<<"\n\n";

				errorFile<<"Error at line "<<lineNumber <<": Undefined function "; 
				errorFile<<funcName1<<"\n\n";
				semanticErrorCount++;   
				errorCount++; 

			}
			
		}
		else if(funcSymInfo1 == NULL){

			// cout<<"\n********** func "<< funcName1 <<" NOT DECLARED ****\n";
			//Error at line 62: Undeclared function foo5
			logFile<<"Error at line "<<lineNumber <<": Undeclared function "; 
			logFile<<funcName1<<"\n\n";  

			errorFile<<"Error at line "<<lineNumber <<": Undeclared function "; 
			errorFile<<funcName1<<"\n\n";
			semanticErrorCount++;   
			errorCount++; 
		}
		
		logFile<<$$->getSymbolName()<<"\n\n"; 

	

	}
	| LPAREN expression RPAREN {
            

			string symbolName = "(" + $2->getSymbolName()  + ")"; 
			//(2*3)
			string symbolType = "factor";

			$$ = new SymbolInfo(symbolName, symbolType);

			string exprType1 = $2->getWhatTypeSpecifier(); 
			string exprID1 = $2->getWhatTypeID(); 
			// cout<<"\n*********** LPAREN expression RPAREN: exprType1 ="<< exprType1<<"\n"; 
			$$->setWhatTypeSpecifier(exprType1); 
			$$->setWhatTypeID(exprID1); 
			//Line 19: factor : LPAREN expression RPAREN

			// ****           asm code er jonno               **
			// 2*(5+3) ; so 5+3= t1 so symbolname = t1 i hobe ; NOT (t1)
			
			
			//$$->setSymbol----Name($2->getSymbolName());


			string exprCode1 = $2->getAssemblyCode(); 
			cout<<"\n* (E) rule e: exprCode1 :" <<exprCode1<<"\n"; 

			$$->setAssemblyName($2->getAssemblyName()); 

			$$->setAssemblyCode(exprCode1); 


			logFile << "Line " << lineNumber << ": factor : LPAREN expression RPAREN" << "\n\n";
			logFile << $$->getSymbolName() << "\n\n";

            
    }
	| CONST_INT	{
		logFile<<"Line "<<lineNumber<<": factor : CONST_INT\n\n"; 
		//Line 10: factor : CONST_INT
		$$ = $1;
		// $1-> Type() : const_int ase; 
		string factorTypeSpecifier = "INT"; 
	
		$$->setWhatTypeSpecifier(factorTypeSpecifier); 
		$$->setWhatTypeID("VARIABLE"); 

		string asm_name1 = $1->getSymbolName(); 

		// a = 5; ei 5 pabo factor: INT rule theke ; so ta set kori 
		$$->setAssemblyName(asm_name1); 

		logFile<<$$->getSymbolName()<<"\n\n";

	}
	| CONST_FLOAT{
		logFile<<"Line "<<lineNumber<<": factor : CONST_FLOAT\n\n"; 
		//Line 10: factor : CONST_FLOAT
		//PrintFloatTwoDecimal
		string currentFloatVal = $1->getSymbolName(); 
		string symbolName  =  PrintFloatTwoDecimal(currentFloatVal); 
		string symbolType = "CONST_FLOAT"; 
		$$ = new SymbolInfo(symbolName, symbolType); 
		// $1-> Type() : CONST_FLOAT ase; 
		string factorTypeSpecifier = "FLOAT"; 
	
		$$->setWhatTypeSpecifier(factorTypeSpecifier); 
		$$->setWhatTypeID("VARIABLE"); 
		// ** float amader input e NEI ; so ignored 
		logFile<<$$->getSymbolName()<<"\n\n";
	}
	| variable INCOP {
		logFile<<"Line "<<lineNumber<<": factor : variable INCOP\n\n"; 
		string symbolName = $1->getSymbolName() + "++"; 

		string symbolType = "factor";

		$$ = new SymbolInfo(symbolName, symbolType);

		string variableType1 = $1->getWhatTypeSpecifier(); 
		string variableID1 = $1->getWhatTypeID(); 
			
		$$->setWhatTypeSpecifier(variableType1); 
		$$->setWhatTypeID(variableID1); 

		//     *** asm code (for variable ) in  INCOP 
		
		int arrSize1 = $1->getSizeArray(); 
		bool isVariable = false; 

		if(arrSize1==-1) isVariable = true; 


		string tempVarName1 = newTemporaryVariable(); 

		newTemporaryVariableCodeAdd(tempVarName1); 
		string inc_code1 =  $1->getAssemblyCode();  
		
		//string var_name1 = $1->getSymbol---Name(); 

		string var_name1 = $1->getAssemblyName(); 

		if(isVariable){
			
			/*
			MOV AX, I2
			MOV T1, AX
			INC I2
			*/ 
			inc_code1 += "\n\tMOV AX, "+ var_name1; 
			inc_code1 += "\n\tMOV "+ tempVarName1 + ", AX\n\t"; 
			inc_code1 += "INC "+var_name1 +"\n";  

			

		}
		else{

			// *** c11[5][BX] ASHTESE 
			//assignopArray-SizeRemove(string)
			///var_name1 = assignop---ArraySizeRemove($1->getSymbol---Name()); 
			var_name1 = assignopArraySizeRemove($1->getAssemblyName()); 

			inc_code1 += "\n\tMOV AX, "+ var_name1; 
			inc_code1 += "[BX]"; 

			inc_code1 += "\n\tMOV "+ tempVarName1 + ", AX\n\t"; 
			inc_code1 += "INC "+var_name1; 
			inc_code1 += "[BX]";  
			inc_code1 += "\n"; 
			

			// c[5]++; 
			/*
			MOV BX, 5
			ADD BX, BX
			----- INCOP er code 
			MOV AX, C2[BX]
			MOV T0, AX
			INC C2[BX]
			*/
		}

		$$->setAssemblyCode(inc_code1); 
		

		//$$->setSymbol--Name(tempVarName1); ---- NOPE

		$$->setAssemblyName(tempVarName1); 



		logFile<<$$->getSymbolName()<<"\n\n";

	}
	| variable DECOP {
		logFile<<"Line "<<lineNumber<<": factor : variable DECOP\n\n"; 
		string symbolName = $1->getSymbolName() + "--"; 

		string symbolType = "factor";

		$$ = new SymbolInfo(symbolName, symbolType);

		string variableType1 = $1->getWhatTypeSpecifier(); 
		string variableID1 = $1->getWhatTypeID(); 
			
		$$->setWhatTypeSpecifier(variableType1); 
		$$->setWhatTypeID(variableID1); 


		//     *** asm code (for variable ) in  INCOP 
		
		int arrSize1 = $1->getSizeArray(); 
		bool isVariable = false; 

		if(arrSize1==-1) isVariable = true; 


		string tempVarName1 = newTemporaryVariable(); 

		newTemporaryVariableCodeAdd(tempVarName1); 
		string inc_code1 =  $1->getAssemblyCode();  
		
		//string var_name1 = $1->getSymbol---Name(); 

		string var_name1 = $1->getAssemblyName(); 

		if(isVariable){
			
			inc_code1 += "\n\tMOV AX, "+ var_name1; 
			inc_code1 += "\n\tMOV "+ tempVarName1 + ", AX\n\t"; 
			inc_code1 += "DEC "+var_name1 +"\n";  

			

		}
		else{


			//var_name1 = assignopArraySizeRemove($1->getSymbol---Name()); 

			var_name1 = assignopArraySizeRemove($1->getAssemblyName()); 

			inc_code1 += "\n\tMOV AX, "+ var_name1; 
			inc_code1 += "[BX]"; 

			inc_code1 += "\n\tMOV "+ tempVarName1 + ", AX\n\t"; 
			inc_code1 += "DEC "+var_name1; 
			inc_code1 += "[BX]";  
			inc_code1 += "\n"; 
			


		}

		$$->setAssemblyCode(inc_code1); 
		

		//$$->setSymbol--Name(tempVarName1); ---- NOPE

		$$->setAssemblyName(tempVarName1); 

		logFile<<$$->getSymbolName()<<"\n\n";

	}
	;

variable: ID {

		$$ = $1; //default ei ashe 
		logFile<< "Line " << lineNumber << ": variable : ID\n\n"; 
		
		
		$$->setWhatTypeID("VARIABLE"); 
		
        string currVarName = $1->getSymbolName(); 

        string currScopeStr = symTable->getCurrentScopeId(); 
        string fullVarName1 = variableNameGenerator(currVarName, currScopeStr); 

        //$1->setSymbol---Name(fullVarName1); 
        //$$->setSymbol---Name(fullVarName1); 


		string key = $1->getSymbolName(); 
		//int x,y,z; x = 2; 
		//so  ei ID age theke defined thaka lagbe ***********
		SymbolInfo* symInfo = symTable->currentScopeLookUp(key); 
		
		if(symInfo==NULL){ 
			symInfo = symTable->LookUpOff1(key); 
		}

		if(symInfo==NULL){
			//Error at line 12: Undeclared variable b
			logFile<<"Error at line "<<lineNumber<<": Undeclared variable "<<key<<"\n\n"; 

			errorFile<<"Error at line "<<lineNumber<<": Undeclared variable "<<key<<"\n\n"; 

			semanticErrorCount++; 
			errorCount++; 
		}
		else if(symInfo != NULL)
		{
			//int x; symInfo te already inserted
			string typeSpecifier = symInfo->getWhatTypeSpecifier();
			//cout<<"\n variable: ID key="<<key<<"  typeSpecifier ="<<typeSpecifier<<"\n";  
			$$->setWhatTypeSpecifier(typeSpecifier); 

			//**          a11         set kori *****

			//cout<<"variable: ID te symInfo->getAssemblyName():"<<symInfo->getAssemblyName()<<"\tsym Name:"<<symInfo->getSymbolName()<<"\n"; 

			$$->setAssemblyName(symInfo->getAssemblyName());  

			//eg: int a[2]; 
			//a = 4; 
			//Error ; a is ARRAY 
			//	Error at line 10: Type mismatch, a is an array
			//cout<<"\n\n*************variable: ID  CHECK array: key="<<key<<" TYPEID ="<<symInfo->getWhatTypeID()<<"\n"; 
			if(symInfo->getWhatTypeID()=="ARRAY"){
			 	logFile<<"Error at line "<<lineNumber << ": Type mismatch, "<< key<<" is an array"<<"\n\n";
				 
				errorFile<<"Error at line "<<lineNumber << ": Type mismatch, "<< key<<" is an array"<<"\n\n";
				semanticErrorCount++; 
				errorCount++;  
			}

		}
		logFile<<$$->getSymbolName()<<"\n\n"; 


	}
	| ID LTHIRD expression RTHIRD 
	{
		// *** asm code lagbe ;                   keno?
		/*
		MOV BX, 3
		ADD BX, BX
		---- ei part tuku c[3] er shomoy i peye gesi AMI 
		MOV AX, 15
		MOV C12[BX], AX
		*/ 
		// c[3] --> c11[3] 

		string currVarName = $1->getSymbolName(); 

        string currScopeStr = symTable->getCurrentScopeId(); 
        string fullVarName1 = variableNameGenerator(currVarName, currScopeStr);

	

		string arrCode1 = $3->getAssemblyCode(); 
		//arrCode1 += "\n\tMOV BX, " + $3->getSymbol--Name(); 

		arrCode1 += "\n\tMOV BX, " + $3->getAssemblyName(); 

		arrCode1 += "\n\tADD BX, BX\n"; 

		
		//$1->setSymbol---Name(fullVarName1); --- $$->setAssemblyName(symInfo->getAssemblyName())

		
		string symbolName = $1->getSymbolName(); 
		string symbolType = "variable";
		symbolName = symbolName + "[" + $3->getSymbolName() + "]"; 
		$$ = new SymbolInfo(symbolName, symbolType);

		logFile<< $$->getSymbolName() <<"\n\n"; 

		$$->setAssemblyCode(arrCode1); 

		//$$->setSymbol---Name(symbolName); /// *** jate c11[10] na hoye symbolName e c11 thake khali 

		
		
		
		//a[0]
		//Line 16: variable : ID LTHIRD expression RTHIRD
		logFile<< "Line " << lineNumber << ": variable : ID LTHIRD expression RTHIRD\n\n"; 

		
		string key = $1->getSymbolName(); 
		//int x,y,z; x = 2; 
		//so  ei ID age theke defined thaka lagbe ***********
		SymbolInfo* symInfo = symTable->currentScopeLookUp(key); 
		
		if(symInfo==NULL){ 
			symInfo = symTable->LookUpOff1(key); 
		}
		
		if(symInfo==NULL){
			logFile<<"Error at Line "<<lineNumber<<" : Undeclared Variable "<<key<<"\n\n"; 
			errorFile<<"Error at Line "<<lineNumber<<" : Undeclared Variable "<<key<<"\n\n"; 

			semanticErrorCount++; 
			errorCount++; 
		}
		else if(symInfo != NULL)
		{
			/// **************                  array er size ta fix kora lagbe 
			int sizeArr1 = symInfo->getSizeArray(); 
			$$->setSizeArray(sizeArr1); 
			cout<<"variable: ID[]: sizeArr1="<<sizeArr1<<"\n"; 

			//-----
			$$->setAssemblyName(symInfo->getAssemblyName()); 


			//int x; symInfo te already inserted
			string typeId1 = symInfo->getWhatTypeID(); 
			if(typeId1!= "ARRAY"){
				//Error at line 52: b not an array
				logFile<<"Error at line "<<lineNumber<<": "<<key<<" not an array"<<"\n\n"; 
				errorFile<<"Error at line "<<lineNumber<<": "<<key<<" not an array"<<"\n\n"; 
				semanticErrorCount++; 
				errorCount++; 
			}
			string typeSpecifier = symInfo->getWhatTypeSpecifier();
			// cout<<"\n variable ARRAY: ID key="<<key<<"  typeSpecifier ="<<typeSpecifier<<"\n";  
			$$->setWhatTypeSpecifier(typeSpecifier); 

		}
		string idxVariable = $3->getWhatTypeSpecifier(); 
		// cout<<"****************Line :"<<lineNumber<<"\t idxVariable="<<idxVariable<<"\n"; 
		if(idxVariable != "INT")
		{
			logFile<<"Error at line "<< lineNumber<<": Expression inside third brackets not an integer"<<"\n\n"; 
			errorFile<<"Error at line "<< lineNumber<<": Expression inside third brackets not an integer"<<"\n\n"; 
			semanticErrorCount++; 
			errorCount++; 
		}
		$$->setWhatTypeID("ARRAY");

		

		


	}

	;

argument_list: error{
		// cout<<"\n\n******************************************            ##";
		// logFile<<"\n\n******************************************            ##";
			
		// cout<<"\nLine:"<<lineNumber<<": argument_list: error"<<"\n\n"; 
		// logFile<<"\nLine:"<<lineNumber<<": argument_list: error"<<"\n\n"; 
	}
	| arguments {
		logFile<<"Line "<< lineNumber<<": argument_list : arguments\n\n"; 
	

		string symbolName = $1->getSymbolName() ; 
		string symbolType = "argument_list";

		$$ = new SymbolInfo(symbolName, symbolType);
		logFile<<$$->getSymbolName()<<"\n\n"; 
		string arguments_code = $1->getAssemblyCode(); 
		$$->setAssemblyCode(arguments_code); 

	}
	|{
		logFile<<"Line "<< lineNumber<<": argument_list: Empty\n\n"; 
		/*
		suppose int foo() { return 5; }
		now d = foo(); so arg list empty 
		*/
		string symbolName = ""; 
		string symbolType = "argument_list";

		$$ = new SymbolInfo(symbolName, symbolType);
		logFile<<$$->getSymbolName()<<"\n"; 
	 }

	
	;
	
arguments: arguments COMMA logic_expression {
		logFile<<"Line "<< lineNumber<<": arguments : arguments COMMA logic_expression\n\n"; 
		//Line 20: arguments : arguments COMMA logic_expression
		//1,2*3
		string symbolName = $1->getSymbolName() + "," + $3->getSymbolName(); 
		string symbolType = "arguments";

		$$ = new SymbolInfo(symbolName, symbolType);
		logFile<<$$->getSymbolName()<<"\n\n"; 

		// cout<<"\n\n**********1. logic_expression ="<<$3->getSymbolName()<<" type ="<<$3->getWhatTypeSpecifier()<<" ";
		// cout<<"ID: "<<$3->getWhatTypeID()<<"\n";  
		SymbolInfo* myArg = $3; 

		//cout<<"\n\t\t*****argListYFile e PUSH e : $3->getSymbolName():"<<$3->getSymbolName()<<"\t$3->getAssemblyName()"<<$3->getAssemblyName()<<"\n"; 

		argListYFile.push_back(myArg); 

		

		string arguments_code = $1->getAssemblyCode()+$3->getAssemblyCode(); 
		$$->setAssemblyCode(arguments_code); 

		}
		| error logic_expression {
			// cout<<"\n\n******************************************            ##";
			// logFile<<"\n\n******************************************            ##";
			
			// cout<<"\nLine:"<<lineNumber<<": arguments: 	error logic_expression"<<"\n\n"; 
			// logFile<<"\nLine:"<<lineNumber<<": arguments: 	error logic_expression"<<"\n\n"; 
		}
	    | logic_expression
		{
			logFile<<"Line "<< lineNumber<<": arguments : logic_expression\n\n"; 
			//Line 20: arguments : logic_expression
			string symbolName = $1->getSymbolName(); 
			string symbolType = "arguments";
			$$ = new SymbolInfo(symbolName, symbolType);
			logFile<<$$->getSymbolName()<<"\n\n"; 

			
			// cout<<"\n\n**********2. logic_expression ="<<$1->getSymbolName()<<"\t type ="<<$1->getWhatTypeSpecifier()<<" "; 
			// cout<<"ID: "<<$1->getWhatTypeID()<<"\n";
			SymbolInfo* myArg = $1; 

			//cout<<"\n\t\t*****argListYFile e PUSH e : $1->getSymbolName():"<<$1->getSymbolName()<<"\t$1->getAssemblyName()"<<$1->getAssemblyName()<<"\n"; 

			argListYFile.push_back(myArg); 

			string arguments_code = $1->getAssemblyCode(); 
			$$->setAssemblyCode(arguments_code); 
		}
	      ;

%%
int main(int argc, char* argv[]) {
	if(argc != 2) {
		cout << "input file name not provided, terminating program..." << "\n";
		return 0;
	}

    input = fopen(argv[1], "r");

    if(input == NULL) {
		cout << "input file not opened properly, terminating program..." << "\n";
		exit(EXIT_FAILURE);
	}

	logFile.open("log.txt", ios::out);
	errorFile.open("error.txt", ios::out);

	assemblyCodeFile.open("code.asm", ios::out);

	optimizeCodeFile.open("optimized_code.asm", ios::out);


	symTable = new SymbolTable(30); 
	
	if(logFile.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << "\n";
		fclose(input);
		
		exit(EXIT_FAILURE);
	}


	
	
	yyin = input;
    yyparse();  // processing starts

    //logFile <<"Ending"<<"\n";

	
	fclose(yyin);
	logFile.close();

	return 0;
} 