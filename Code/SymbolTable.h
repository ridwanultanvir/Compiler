
/// 12.4.21; OFF3_310

#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <bits/stdc++.h>

#define INF 999999

using namespace std;

class SymbolInfo
{
private:
    string symbol_name;
    string symbol_value;
    SymbolInfo *previous;
    SymbolInfo *next;
    string whatTypeID;
    string whatTypeSpecifier;
    string whatTypeReturn;
    vector<int> intArray;
    vector<float> floatArray;
    int sizeArray;
    string assemblyCode; 
    string assemblyName; 

public:
    vector<SymbolInfo *> paramSymList; //like parameter list er jonno
    void setAssemblyName(string assemblyName1)
    {
        this->assemblyName = assemblyName1; 
    }
    string getAssemblyName()
    {
        return assemblyName; 
    }
    void setAssemblyCode(string assemblyCode1)
    {
        this->assemblyCode = assemblyCode1; 
    }
    string getAssemblyCode()
    {
        return assemblyCode; 
    }
    SymbolInfo()
    {
        ///NULL?
        previous = NULL;
        next = NULL;
        whatTypeID = "";
        whatTypeSpecifier = "";
        whatTypeReturn = "";
        sizeArray = -1;
        assemblyCode = ""; 
    }
    SymbolInfo(string name, string value)
    {
        symbol_name = name;
        symbol_value = value;

        previous = NULL;
        next = NULL;
        whatTypeID = "";
        whatTypeSpecifier = "";
        whatTypeReturn = "";
        sizeArray = -1;
        assemblyCode = ""; 
    }
    int getSizeArray()
    {
        return sizeArray;
    }
    void setSizeArray(int sizeArr)
    {
        this->sizeArray = sizeArr;
    }

    void arrayInitialize(string whatTypeArray)
    {

        //cout << "*****whatTypeArray =" << whatTypeArray << "\n";
        if (whatTypeArray == "INT")
        {
            intArray.resize(sizeArray);
            //cout << "\n#****************************************now intArray size = " << intArray.size() << "\n";
        }
        else if (whatTypeArray == "FLOAT")
        {
            floatArray.resize(sizeArray);
            //cout << "#now floatArray size = " << floatArray.size() << "\n";
        }
    }
    string getSymbolName()
    {
        return symbol_name;
    }

    void setSymbolName(string name)
    {
        symbol_name = name;
    }
    string getWhatTypeID()
    {
        return this->whatTypeID;
    }
    void setWhatTypeID(string idType)
    {
        this->whatTypeID = idType;
        return;
    }
    string getWhatTypeSpecifier()
    {
        return this->whatTypeSpecifier;
    }
    void setWhatTypeSpecifier(string typeSpecifier)
    {
        this->whatTypeSpecifier = typeSpecifier;
        return;
    }
    string getWhatTypeReturn()
    {
        return this->whatTypeReturn;
    }
    void setWhatTypeReturn(string typeReturn)
    {
        this->whatTypeReturn = typeReturn;
        return;
    }

    string getSymbolType()
    {
        return symbol_value;
    }

    void setSymbolType(string value)
    {
        this->symbol_value = value;
        ///this: Each object gets its own copy of the data member.
    }
    SymbolInfo *getPrevious() { return previous; }
    void setPrevious(SymbolInfo *x)
    {
        previous = x;
        return;
    }
    SymbolInfo *getNext() { return next; }
    void setNext(SymbolInfo *x) { next = x; };

    bool compareName(string name)
    {
        if (symbol_name == name)
            return true;
        return false;
    }
    bool compareValue(string value)
    {
        if (symbol_value == value)
            return true;
        return false;
    }
    void Print(ostream &logFile)
    {
        // 0 --> < x , ID >
        logFile << "< " << this->symbol_name << " , " << this->symbol_value << " >";
        return;
    }
    void PrintCommandLine()
    {

        cout << "< " << this->symbol_name << " , " << this->symbol_value << " >";
        return;
    }
    ~SymbolInfo()
    {
    }
};

class ScopeTable
{

private:
    string id;
    int child;

    int bucket_size;
    vector<int> id_vector; ///not necessary

    SymbolInfo **bucketChainList;
    ScopeTable *parentScope;

    /// ​sum_ascii % bucket_size
    int hashFunc(string key)
    {
        int bucket_no = 0;

        for (int i = 0; i < key.size(); i++)
        {
            int asci = key[i];
            bucket_no += asci;
        }
        bucket_no = bucket_no % bucket_size;

        return bucket_no;
    }

    int hashFunc2(string s)
    {

        int hash_val = 5381;
        int i = 0;

        for (i = 0; i < s.size(); i++)
        {
            hash_val = ((hash_val << 5) + hash_val) + int(s[i]); //* by 31
            hash_val = hash_val % bucket_size;
        }
        return hash_val;
    }

public:
    ScopeTable()
    {
        parentScope = NULL;
        bucketChainList = NULL;
        child = 0;
    }
    string getScopeId()
    {
        return id; 
    }
    ScopeTable(int n)
    {
        this->parentScope = NULL;

        child = 0;

        id = "1";
        this->bucket_size = n;
        bucketChainList = new SymbolInfo *[bucket_size];

        for (int i = 0; i < bucket_size; i++)
        {
            bucketChainList[i] = NULL;
        }
    }
    ScopeTable(int n, ScopeTable *parentScope)
    {
        this->parentScope = parentScope;

        child = 0;

        this->bucket_size = n;
        bucketChainList = new SymbolInfo *[bucket_size];

        for (int i = 0; i < bucket_size; i++)
        {
            bucketChainList[i] = NULL;
        }

        if (parentScope != NULL)
        {
            int currID = parentScope->getChild() + 1;
            string currentID = to_string(currID);

            id = parentScope->getID() + "." + currentID;
        }
        else
        {
            ///parentScope = Null
            id = "1";
        }

        //cout << "New ScopeTable with id " << id << " created";
    }

    ScopeTable(string id, int size)
    {

        this->id = id;
        bucket_size = size;
        parentScope = NULL; ///parent = NULL hole; etai head howa uchit;
        child = 0;

        bucketChainList = new SymbolInfo *[bucket_size];
        for (int i = 0; i < bucket_size; i++)
        {
            bucketChainList[i] = NULL;
        }
    }

    ScopeTable(vector<int> &vect_id, int size, ScopeTable *parentScope)
    {
        child = 0;

        id_vector = vect_id;
        bucket_size = size;

        this->parentScope = parentScope;

        bucketChainList = new SymbolInfo *[bucket_size];
        for (int i = 0; i < bucket_size; i++)
        {
            bucketChainList[i] = NULL;
        }
    }

    ~ScopeTable()
    {
        delete[] bucketChainList;
    }

    void printScopeId()
    {

        cout << this->getID() << " ";
    }
    int getChild()
    {
        return child;
    }
    void setChild(int number_child)
    {
        child = number_child;
        return;
    }
    void insertChild()
    {
        child++; ///child ek barao
    }

    string getID()
    {
        return id;
    }

    void setID(string id)
    {
        this->id = id;
        return;
    }

    int getBucketSize()
    {
        return bucket_size;
    }

    void setBucketSize(int size)
    {

        this->bucket_size = size;
    }

    ScopeTable *getParentScope()
    {
        return parentScope;
    }
    void setParentScope(ScopeTable *parentScope)
    {
        this->parentScope = parentScope;
    }

    ///SCOPE TABLE er function
    SymbolInfo *LookUp(string name)
    {
        // cout << "\n\n#EI scope ID: " << getID() << "\n looking up name: " << name << "\n";
        int bucket_no = hashFunc(name);

        SymbolInfo *currentPtr = bucketChainList[bucket_no];

        ///cout<<"traversing in chain #"<<bucket_no<<"\n";

        int position_in_bucket = 0;
        while (currentPtr != NULL)
        {

            string name1 = currentPtr->getSymbolName();

            if (name == name1)
            {
                /*
                cout << "Found in ScopeTable# " ;
                printScopeId();
                cout << " at position " << bucket_no << ", " << position_in_bucket << endl;
                */
                return currentPtr;
            }

            position_in_bucket++;
            currentPtr = currentPtr->getNext();
        }

        ///cout << "\t" << "Not found in ScopeTable #" ;
        ///printScopeId();

        currentPtr = NULL;

        return currentPtr; /// paini ; so NULL;
    }

    bool Insert(string name, string value)
    {
        if (LookUp(name) != NULL)
        {
            ///<<=,RELOP> already exists in current ScopeTable
            // cout << "<" << name << "," << value << "> already exists in current ScopeTable"
            //      << "\n";

            return false;
        }

        SymbolInfo *insertSymbol = new SymbolInfo(name, value);
        int bucket_no = hashFunc(name);
        int position_in_bucket = 0;

        ///bucket[5] : free ase; so insert;
        if (bucketChainList[bucket_no] == NULL)
        {
            ///bucket[hash] = newSymbol;
            bucketChainList[bucket_no] = insertSymbol;

            insertSymbol->setNext(NULL); ///etar NEXT = NULL; JATE porer insert shekhane hoy

            ///2---> 3---> 7 --> NULL

            //cout << "Inserted in ScopeTable# ";
            // printScopeId();
            //cout << " at position " << bucket_no << ", " << position_in_bucket << endl;

            return true;
        }

        ///now OI CHAIN e INSERT
        SymbolInfo *currentSymbol = bucketChainList[bucket_no];

        while (currentSymbol->getNext() != NULL)
        {
            currentSymbol = currentSymbol->getNext();
            position_in_bucket++;
        }

        ///2---> 3---> 7 --> NULL ; ekhon ami 7 e asi;
        ///7--->8-->NULL; insert 8;
        currentSymbol->setNext(insertSymbol);
        insertSymbol->setNext(NULL);

        // cout << "Inserted in ScopeTable# ";
        // printScopeId();
        // cout << " at position " << bucket_no << ", " << (position_in_bucket + 1) << endl;

        return true;
    }

    ///return korbe pointer; jate ogula SET kora jay shohoje

    SymbolInfo *InsertPointer(string name, string value)
    {
        SymbolInfo *insertSymbol = NULL;
        if (LookUp(name) != NULL)
        {
            ///<<=,RELOP> already exists in current ScopeTable
            // cout << "<" << name << "," << value << "> already exists in current ScopeTable"
            //      << "\n";

            return insertSymbol;
        }

        insertSymbol = new SymbolInfo(name, value);
        int bucket_no = hashFunc(name);
        int position_in_bucket = 0;

        if (bucketChainList[bucket_no] == NULL)
        {

            bucketChainList[bucket_no] = insertSymbol;

            insertSymbol->setNext(NULL); ///etar NEXT = NULL; JATE porer insert shekhane hoy

            ///2---> 3---> 7 --> NULL

            // cout << "Inserted in ScopeTable# ";
            // printScopeId();
            // cout << " at position " << bucket_no << ", " << position_in_bucket << endl;

            return insertSymbol;
        }

        ///now OI CHAIN e INSERT
        SymbolInfo *currentSymbol = bucketChainList[bucket_no];

        while (currentSymbol->getNext() != NULL)
        {
            currentSymbol = currentSymbol->getNext();
            position_in_bucket++;
        }

        ///2---> 3---> 7 --> NULL ; ekhon ami 7 e asi;
        ///7--->8-->NULL; insert 8;
        currentSymbol->setNext(insertSymbol);
        insertSymbol->setNext(NULL);

        // cout << "Inserted in ScopeTable# ";
        // printScopeId();
        // cout << " at position " << bucket_no << ", " << (position_in_bucket + 1) << endl;

        return insertSymbol;
    }

    void PrintCurrentScope(ostream &logFile)
    {

        ///cout << "\nThis  ScopeTable:";
        logFile << "\n\n\nScopeTable # " << this->getID();
        //printScopeId();
        /*
ScopeTable # 1.1.1
 0 --> < b : ID>

ScopeTable # 1.1
 1 --> < 2 : CONST_INT>
 6 --> < a : ID>

ScopeTable # 1
 1 --> < main : ID>
        */

        logFile << "\n";

        for (int i = 0; i < bucket_size; i++)
        {

            SymbolInfo *currentSymbol = bucketChainList[i];

            if (currentSymbol == NULL)
            {
                // THAT means i = 1 er jonno kono kisui nei; so ignored
                continue;
            }
            // 0 --> < x , ID >
            logFile << " " << i << " --> ";

            while (currentSymbol != NULL)
            {
                ///cout << *currentSymbol; << ke overwrite korle eta thik ase;
                currentSymbol->Print(logFile);

                currentSymbol = currentSymbol->getNext();
                if (currentSymbol)
                {
                    logFile << " ";
                }
            }

            logFile << "\n";
        }

        return;
    }

    bool Delete(string name)
    {
        SymbolInfo *foundSymbol = LookUp(name);

        //not found
        if (foundSymbol == NULL)
        {
            ///eta NEI
            return false;
        }

        int bucket_no = hashFunc(name);

        SymbolInfo *previousSymbol = NULL;
        SymbolInfo *currentSymbol = bucketChainList[bucket_no];

        int position_in_bucket = 0;

        /***
        2-->3-->4;
        2 delete; 3--> 4
        3 del   : 2---> 4;
        4       : 2---> 3;
        */

        bool found = false;
        while (currentSymbol != NULL)
        {
            string currentSymbolName = currentSymbol->getSymbolName();
            if (name == currentSymbolName)
            {
                found = true;
                break;
            }

            position_in_bucket++;
            previousSymbol = currentSymbol;
            currentSymbol = currentSymbol->getNext(); ///2-->3---> 4; 3 = curr;
            ///del 3; 3 match korle kintu EGULA konotai hobe NA;
        }

        SymbolInfo *currentNext = currentSymbol->getNext();

        if (previousSymbol)
        {
            ///previous != NULL;
            /***
            2-->3-->4;
            3 del   : 2---> 4;

            ///so pre = 2; curr = 3;
            */
            previousSymbol->setNext(currentNext); ///currentSymbol->getNext()
            ///2---> 4;
        }
        else
        {

            /***
            2-->3-->4;
            2 delete; 3--> 4
            curr = 2; prev = NULL; next = 3;
            */
            bucketChainList[bucket_no] = currentNext; ///currentSymbol->getNext()
        }
        ///	Deleted Entry 3, 0 from current ScopeTable
        // cout << "Deleted Entry " << bucket_no << ", " << position_in_bucket << " from current ScopeTable" << "\n";
        delete currentSymbol; ///delete 2 NODE or pointer ta ERASE

        return true;
    }
};

class SymbolTable
{
    int bucket_size;
    int total_scope;
    ScopeTable *current;
    ScopeTable *parent;
    ScopeTable *head;
    /// parent ; head ; pore IGNORED; bad dileo hobe

public:
    SymbolTable()
    {
        total_scope = 0;
        this->bucket_size = 20;

        current = NULL;
        parent = NULL;
        head = NULL;
    }
    SymbolTable(int n)
    {
        this->bucket_size = n;
        total_scope = 0;
        current = new ScopeTable(n);
        parent = NULL;
        head = NULL;

        ///cout<<"# symbol table construc. n="<<n<<"\n";
    }
    ~SymbolTable()
    {
        ScopeTable *nowScope = current; ///ekhon current jei scope

        while (nowScope != NULL)
        {
            delete nowScope;
            nowScope = nowScope->getParentScope();
        }
    }

    void PrintCurrentScopeId()
    {
        cout << "SyTable Current:";
        current->printScopeId();
        cout << "\n";
    }

    string getCurrentScopeId()
    {
        return (current->getScopeId()); 
    }

    void setNewScopeId(vector<int> &id_vector, ScopeTable *parentScope)
    {
        parentScope->insertChild(); ///notun ekta child ashbe parent er ; ** notun scope
        ScopeTable *tmp = parentScope;

        while (tmp != NULL)
        {
            int child_no = tmp->getChild();
            id_vector.push_back(child_no);
            ///cout<<"# parent_child_no = "<<child_no<<"\n";
            tmp = tmp->getParentScope();
        }
        id_vector.push_back(1); ///1st parent er jonno
        return;
    }

    void EnterScope()
    {

        current = new ScopeTable(bucket_size, current); ///Parent ke NEW ENTERSCOPE er?
        ///current nijei

        return;
    }
    ///off1 e ei EnterScope use korsi; now eta lagbe NA
    void EnterScopePrevious()
    {

        vector<int> id_vector;

        if (current != NULL)
        {
            setNewScopeId(id_vector, current); ///current i kintu parent;
        }
        else
        {
            id_vector.push_back(1);
            ///else : id_vector: [1];
            ///simply : first tar id  = 1
        }

        /*
        cout<<"# size of id_vector: "<<id_vector.size()<<"\n";
        for(int i=id_vector.size()-1; i>=0; i--){
            cout<<id_vector[i]<<"    ";
        }
        */
        ScopeTable *newScope = new ScopeTable(id_vector, bucket_size, current);
        ///*** focus: passing current ; not parent; karon newScope er parent = current_je_zse;
        ///2--->3 ; new = 4; so new_parent = 3= current;  .// pore 2-->3-->4; so current = 4;
        current = newScope;

        increaseTotalScope();
        ///shurute head = NULL
        if (head == NULL)
        {
            head = current;
        }
        else
        {
            /*
            cout<<"New ScopeTable with id ";
            current->printScopeId();
            cout<<" created\n";
            */
        }

        ///current->printScopeId(); ///returns void so eta error dibe

        return;
    }
    void ExitScope()
    {
        if (current == NULL)
        {
            //cout <<  "No scopetable" << "\n";
            return;
        }
        ///*** eta destrcutor e LIKHLE mane main() shesh howar por abar print HOTO
        /*
        cout << "ScopeTable with id ";

        current->printScopeId();
        cout<<" removed\n";
        */

        current->getParentScope()->insertChild();
        ///**** insertChild = simply tar arekta CHILD scope table erase hoise ; DeletedScope = +1 hobe

        delete current; ///*** eta age bad gesilo

        current = current->getParentScope();

        /*

        */

        return;
    }
    bool Insert(string name, string value)
    {
        if (current == NULL)
        {
            ///first Insert; notun scope
            EnterScope();
            return current->Insert(name, value);
        }
        else
        {
            bool insertSuccess = current->Insert(name, value);
            //cout<<"\n****After inserting name ="<<name<<" value="<<value<<"\n";
            //PrintAllScopeTable(cout);

            return insertSuccess;
        }
    }
    SymbolInfo *InsertPointer(string name, string value)
    {
        if (current == NULL)
        {
            EnterScope();
            return current->InsertPointer(name, value);
        }
        else
        {
            return current->InsertPointer(name, value);
        }
    }
    bool Remove(string name)
    {
        if (current == NULL)
        {
            cout << "No ScopeTable " << endl;
            return false;
        }
        else
        {
            ///null-> STH ; error dibe; so ==NULL kina check
            bool found = current->Delete(name);
            if (!found){
                // cout << "Not found\n";
            }
            // cout << name << " not found\n";

            return found;
        }
    }
    ///Return a pointer to the SymbolInfo object representing the searched symbol.
    ///this is OFF1 lookUP INTACT
    SymbolInfo *LookUpOff1(string name)
    {

        SymbolInfo *found_symbol_info = NULL;

        ScopeTable *tmpScope = current;

        if (current == NULL)
        {
            ///cout << "\nThere is 0 ScopeTable" << endl;
            return NULL;
        }

        bool found = false;
        while (tmpScope != NULL)
        {

            found_symbol_info = tmpScope->LookUp(name);

            if (found_symbol_info != NULL)
            {
                found = true;
                break;
            }

            tmpScope = tmpScope->getParentScope();
        }
        if (!found)
        {
            // cout << "Not found\n";
            // cout << name << " not found\n";
        }
        return found_symbol_info;
    }
    ///current scope = same scope e lookup
    SymbolInfo *currentScopeLookUp(string key)
    {

        //PrintAllScopeTable(cout);
        //LookUp is a function of scopeTable
        //cout<<"lookup current key = "<<key<<"\n";
        SymbolInfo *symInfo = current->LookUp(key);
        if (symInfo == NULL)
        {
            //cout << "symInfo = null FOUND\n";
        }
        else
        {
            // cout << "symInfo NOT null\n";
        }
        return symInfo;
    }

    void PrintCurrentScopeTable(ostream &logFile)
    {
        if (current)
        {
            ///current != NULL;
            current->PrintCurrentScope(logFile);
        }
    }

    int getTotalScope()
    {
        return total_scope;
    }
    void setTotalScope(int scope_number)
    {
        total_scope = scope_number;
        return;
    }
    void increaseTotalScope()
    {
        total_scope++;
        return;
    }

    void PrintAllScopeTable(ostream &logFile)
    {
        ScopeTable *tempScope = current;

        while (tempScope)
        {
            tempScope->PrintCurrentScope(logFile);
            tempScope = tempScope->getParentScope();
        }
        //logFile<<"\n\n"; 
    }
};

#endif /* SYMBOLTABLE_H */
