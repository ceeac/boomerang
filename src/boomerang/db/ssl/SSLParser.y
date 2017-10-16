/*
 * This file is part of the Boomerang Decompiler.
 *
 * See the file "LICENSE.TERMS" for information on usage and
 * redistribution of this file, and for a DISCLAIMER OF ALL
 * WARRANTIES.
 */

/**
 * Updates:
 * Shane Sendall (original C version) Dec 1997
 * Doug Simon (C++ version) Jan 1998
 * 29 Apr 02 - Mike: Mods for boomerang
 * 03 May 02 - Mike: Commented
 * 08 May 02 - Mike: ParamMap -> ParamSet
 * 15 May 02 - Mike: Fixed strToOper: *f was coming out as /f, << as =
 * 16 Jul 02 - Mike: Fixed code in expandTables processing opOpTables: was
 *                doing replacements on results of searchAll
 * 09 Dec 02 - Mike: Added succ() syntax (for SPARC LDD and STD)
 * 29 Sep 03 - Mike: Parse %DF correctly
 * 22 Jun 04 - Mike: TEMP can be a location now (location was var_op)
 * 31 Oct 04 - Mike: srchExpr and srchOp are statics now; saves creating and deleting these expressions for every
 *                opcode. Seems to prevent a lot of memory churn, and may prevent (for now) the mystery
 *                test/sparc/switch_gcc problem (which goes away when you try to gdb it)
 * 30 Aug 04 - Mike: added init_sslparser() for garbage collection safety
 */

/* options */
//%debug
//%print-tokens
%error-verbose

%class-name SSLParser
%baseclass-header SSLParserBase.h
%parsefun-source SSLParser.cpp
%namespace ssl
%scanner SSLScanner.h

// Required include files
%baseclass-preinclude "sslparser_support.h"


// type declarations
%polymorphic
    exp         : SharedExp;
    str         : QString;
    num         : int;
    dbl         : double;
    regtransfer : Statement *;
    typ         : SharedType;
    tab         : std::shared_ptr<Table>;
    insel       : std::shared_ptr<InsNameElem>;
    strlist     : std::list<QString>;
    explist     : std::deque<SharedExp>;
    namelist    : std::deque<QString>;
    rtlist      : SharedRTL;
    opTable     : std::shared_ptr<OpTable>;
    expTable    : std::shared_ptr<ExprTable>;
    asgn        : std::shared_ptr<Assign>;
    aConst      : std::shared_ptr<Const>;
    loc         : std::shared_ptr<Location>;
    bin         : std::shared_ptr<Binary>;
    tern        : std::shared_ptr<Ternary>;
    sizeTy      : std::shared_ptr<SizeType>;
    intTy       : std::shared_ptr<IntegerType>;
    floatTy     : std::shared_ptr<FloatType>;
    charTy      : std::shared_ptr<CharType>;

/*==============================================================================
 * Declaration of token types, associativity and precedence
 *============================================================================*/

%token <str> NAME ASSIGNTYPE
%token <str> REG_ID REG_NUM DECOR
%token <str> FPUSH FPOP
%token <str> TEMP SHARES CONV_FUNC TRUNC_FUNC TRANSCEND FABS_FUNC
%token <str> NAME_CALL NAME_LOOKUP

%token         ENDIANNESS BIG LITTLE
%token         COVERS INDEX
%token         FNEG THEN
%token         TO COLON ADDR REG_IDX DEFINE
%token         MEM_IDX TOK_INTEGER TOK_FLOAT FAST OPERAND
%token         FETCHEXEC FLAGMACRO SUCCESSOR

%token <num> NUM
%token <dbl> FLOATNUM       /**< I'd prefer type double here! */

%left  <str> LOG_OP         /**< Logical operation */
%right <str> COND_OP        /**< Conditional operation */
%left  <str> BIT_OP         /**< Bit operation */
%left  <str> ARITH_OP       /**< Arithmetic operation */
%left  <str> FARITH_OP
%right NOT LNOT
%left <str> CAST_OP
%left LOOKUP_RDC
%left S_E       // Sign extend. Note it effectively has low precedence, because being a post operator,
                // the whole expression is already parsed, and hence is sign extended.
                // Another reason why ! is deprecated!
%nonassoc AT

%type <exp> exp location exp_term
%type <str> bin_oper param
%type <regtransfer> regtransfer assign_regtransfer
%type <typ> assigntype
%type <num> cast
%type <tab> table_expr
%type <insel> name_contract instr_name instr_elem
%type <strlist> reg_table
%type <strlist> list_parameter func_parameter
%type <namelist> str_term str_expr str_array name_expand opstr_expr opstr_array
%type <explist> flag_list
%type <explist> exprstr_expr exprstr_array
%type <explist> list_actualparameter
%type <rtlist> rt_list

%%

spec_or_assign:
        assign_regtransfer {
            the_asgn = dynamic_cast<Assign *>($1);
            assert(the_asgn);
        }
    |   exp {
            the_asgn = new Assign(Terminal::get(opNil), $1);
        }
    |   specification
    ;

specification:
        specification parts ';'
    |   parts ';'
    ;

parts:
        instr
    |   FETCHEXEC rt_list {
            Dict.fetchExecCycle = $2;
        }
    |   constants       ///< Name := value
    |   table_assign

        // Optional one-line section declaring endianness
    |   endianness

        // Optional section describing faster versions of instructions (e.g. that don't inplement the full
        // specifications, but if they work, will be much faster)
    |   fastlist

        // Definitions of registers (with overlaps, etc)
    |   reglist

        // Declaration of "flag functions". These describe the detailed flag setting semantics for insructions
    |   flag_fnc

        // Addressing modes (or instruction operands) (optional)
    |   OPERAND operandlist { Dict.fixupParams(); }
    ;

operandlist:
        operandlist ',' operand
    |   operand
    ;

operand:
        // In the .tex documentation, this is the first, or variant kind
        // Example: reg_or_imm := { imode, rmode };
        //$1    $2    $3      $4        $5
        param DEFINE '{' list_parameter '}' {
            // Note: the below copies the list of strings!
                Dict.DetParamMap[$1].m_params = $4;
                Dict.DetParamMap[$1].m_kind = PARAM_VARIANT;
            }

        // In the documentation, these are the second and third kinds
        // The third kind is described as the functional, or lambda, form
        // In terms of DetParamMap[].kind, they are PARAM_EXP unless there
        // actually are parameters in square brackets, in which case it is
        // PARAM_LAMBDA
        // Example: indexA    rs1, rs2 *i32* r[rs1] + r[rs2]
        //$1       $2             $3           $4      $5
    |   param list_parameter func_parameter assigntype exp {
            ParamEntry &param = Dict.DetParamMap[$1];
            // Note: The below 2 copy lists of strings
            param.m_params = $2;
            param.m_funcParams = $3;
            param.m_asgn = std::make_shared<Assign>($4, Terminal::get(opNil), $5);
            param.m_kind = PARAM_ASGN;

            if(!param.m_funcParams.empty()) {
                param.m_kind = PARAM_LAMBDA;
            }
        }
    ;

func_parameter:
        '[' list_parameter ']' { $$($2); }
    |   { $$(); }
    ;

reglist:
        TOK_INTEGER { bFloat = false; } a_reglists
    |   TOK_FLOAT   { bFloat = true;  } a_reglists
    ;

a_reglists:
        a_reglists ',' a_reglist
    |   a_reglist
    ;

a_reglist:
        REG_ID INDEX NUM {
            if (Dict.RegMap.find($1) != Dict.RegMap.end()) {
                error();
            }
            Dict.RegMap[$1] = $3;
        }
    |   REG_ID '[' NUM ']' INDEX NUM {
            if (Dict.RegMap.find($1) != Dict.RegMap.end()) {
                error();
            }
            Dict.addRegister( $1, $6, $3, bFloat);
        }
    |   REG_ID '[' NUM ']' INDEX NUM COVERS REG_ID TO REG_ID {
            if (Dict.RegMap.find($1) != Dict.RegMap.end()) {
                error();
            }

            Dict.RegMap[$1] = $6;
            // Now for detailed Reg information
            if (Dict.DetRegMap.find($6) != Dict.DetRegMap.end()) {
                error();
            }

            Dict.DetRegMap[$6].setName($1);
            Dict.DetRegMap[$6].setSize($3);

            // check range is legitimate for size. 8,10
            if ((Dict.RegMap.find($8) == Dict.RegMap.end()) || (Dict.RegMap.find($10) == Dict.RegMap.end())) {
                error();
            }
            else {
                int bitsize = Dict.DetRegMap[Dict.RegMap[$10]].getSize();
                for (int i = Dict.RegMap[$8]; i != Dict.RegMap[$10]; i++) {
                    if (Dict.DetRegMap.find(i) == Dict.DetRegMap.end()) {
                        error();
                        break;
                    }
                    bitsize += Dict.DetRegMap[i].getSize();
                    if (bitsize > $3) {
                        error();
                        break;
                    }
                }

                if (bitsize < $3) {
                    error();
                    // TODO copy information
                }
            }
            Dict.DetRegMap[$6].setMappedIndex(Dict.RegMap[$8]);
            Dict.DetRegMap[$6].setMappedOffset(0);
            Dict.DetRegMap[$6].setIsFloat(bFloat);
        }
    |   REG_ID '[' NUM ']' INDEX NUM SHARES REG_ID AT '[' NUM TO NUM ']' {
            if (Dict.RegMap.find($1) != Dict.RegMap.end()) {
                error();
            }

            Dict.RegMap[$1] = $6;

            // Now for detailed Reg information
            if (Dict.DetRegMap.find($6) != Dict.DetRegMap.end()) {
                error();
            }

            Dict.DetRegMap[$6].setName($1);
            Dict.DetRegMap[$6].setSize($3);

            // Do checks
            if ($3 != ($13 - $11) + 1) {
                error();
            }

            if (Dict.RegMap.find($8) != Dict.RegMap.end()) {
                if ($13 >= Dict.DetRegMap[Dict.RegMap[$8]].getSize()) {
                    error();
                }
            }
            else {
                error();
            }

            Dict.DetRegMap[$6].setMappedIndex(Dict.RegMap[$8]);
            Dict.DetRegMap[$6].setMappedOffset($11);
            Dict.DetRegMap[$6].setIsFloat(bFloat);
        }
    |   '[' reg_table ']' '[' NUM ']' INDEX NUM TO NUM {
            if ((int)($2.size()) != ($10 - $8 + 1)) {
                error();
            }
            else {
                std::list<QString>::iterator loc = $2.begin();
                for (int x = $8; x <= $10; x++, loc++) {
                    if (Dict.RegMap.find(*loc) != Dict.RegMap.end()) {
                        error();
                    }
                    Dict.addRegister(*loc, x, $5, bFloat);
                }
            }
        }
    |   '[' reg_table ']' '[' NUM ']' INDEX NUM {
            std::list<QString>::iterator loc = $2.begin();
            for (; loc != $2.end(); loc++) {
                if (Dict.RegMap.find(*loc) != Dict.RegMap.end()) {
                    error();
                }
                Dict.addRegister(*loc, $8, $5, bFloat);
            }
        }
    ;

reg_table:
        reg_table ',' REG_ID {
            $1.push_back($3);
            $$($1);
        }
    |   REG_ID {
            $$();
            $$.push_back($1);
        }
    ;

// Flag definitions
flag_fnc:
        // $1           $2       $3  $4    $5    $6
        NAME_CALL list_parameter ')' '{' rt_list '}' {
            // Note: $2 is a list of strings
            Dict.FlagFuncs[$1] = std::make_shared<FlagDef>(listStrToExp($2), $5);
        }
    ;

constants:
        NAME DEFINE NUM {
            if (ConstTable.find($1) != ConstTable.end()) {
                error();
            }
            ConstTable[QString($1)] = $3;
        }

    |   NAME DEFINE NUM ARITH_OP NUM {
            if (ConstTable.find($1) != ConstTable.end()) {
                error();
            }
            else if (QString($4) == "-") {
                ConstTable[$1] = $3 - $5;
            }
            else if (QString($4) == "+") {
                ConstTable[$1] = $3 + $5;
            }
            else {
                error();
            }
        }
    ;

table_assign:
        NAME DEFINE table_expr {
            const QString name($1);
            TableDict[name] = $3;
        }
    ;

table_expr:
        str_expr {
            $$(std::make_shared<Table>($1));
        }
        // Example: OP2 := { "<<",    ">>",  ">>A" };
    |   opstr_expr {
            $$(std::make_shared<OpTable>($1));
        }
    |   exprstr_expr {
            $$(std::make_shared<ExprTable>($1));
        }
    ;

str_expr:
        str_expr str_term {
            // cross-product of two str_expr's
            $$(std::deque<QString>());

            for (auto i = $1.begin(); i != $1.end(); i++) {
                for (auto j = $2.begin(); j != $2.end(); j++) {
                    $$.push_back((*i) + (*j));
                }
            }
        }
    |   str_term {
            $$($1);
        }
    ;

str_array:
        str_array ',' str_expr {
            // want to append $3 to $1
            // The following causes a massive warning message about mixing signed and unsigned
            $1.insert($1.end(), $3.begin(), $3.end());
            $$($1);
        }
    |   str_array ',' '"' '"' {
            $1.push_back("");
            $$($1);
        }
    |   str_expr {
            $$($1);
        }
    ;

str_term:
        '{' str_array '}' {
            $$($2);
        }
    |   name_expand {
            $$($1);
        }
    ;

name_expand:
        '\'' NAME '\'' {
            $$();
            $$.push_back("");
            $$.push_back($2);
        }
    |   '"' NAME '"' {
            $$(1, $2);
        }
    |   '$' NAME {
            // expand $2 from table of names
            if (TableDict.find($2) != TableDict.end()) {
                if (TableDict[$2]->getType() == NAMETABLE)
                    $$(TableDict[$2]->Records);
                else {
                    error();
                }
            }
            else {
                error();
            }
        }
    |   NAME {
            // try and expand $1 from table of names.
            // if fail, expand using '"' NAME '"' rule
            if (TableDict.find($1) != TableDict.end()) {
                if (TableDict[$1]->getType() == NAMETABLE) {
                    $$(TableDict[$1]->Records);
                }
                else {
                    error();
                }
            }
            else {
                $$();
                $$.push_back($1);
            }
        }
    ;

bin_oper:
        BIT_OP    { $$($1); }
    |   ARITH_OP  { $$($1); }
    |   FARITH_OP { $$($1); }
    ;

    // Example: OP2 := { "<<",    ">>",  ">>A" };
opstr_expr:
        '{' opstr_array '}' { $$($2); }
    ;

opstr_array:
        //    $1    $2  $3    $4     $5
        opstr_array ',' '"' bin_oper '"' {
            $$($1);
            $$.push_back($4);
        }
    |   '"' bin_oper '"' {
            $$();
            $$.push_back($2);
        }
    ;

    // Example: COND1_C := { "~%ZF", "%ZF", "~(%ZF | (%NF ^ %OF))", ...
exprstr_expr:
        '{' exprstr_array '}' {
            $$($2);
        }
    ;

exprstr_array:
        // $1         $2  $3  $4  $5
        exprstr_array ',' '"' exp '"' {
            $$($1);
            $$.push_back($4);
        }
    |   '"' exp '"' {
            $$();
            $$.push_back($2);
        }
    ;

instr:
        //  $1
        instr_name {
            $1->getRefMap(indexrefmap);
        }
        //   $3           $4
        list_parameter rt_list {
            // This function expands the tables and saves the expanded RTLs to the dictionary
            expandTables($1, $3, $4, Dict);
        }
    ;

instr_name:
        instr_elem { $$($1); }
    |   instr_name DECOR {
            std::shared_ptr<InsNameElem> temp(new InsNameElem(QString($2)));
            $$($1);
            $$->append(temp);
        }
    ;

instr_elem:
        NAME { $$(std::make_shared<InsNameElem>($1)); }
    |   name_contract { $$($1); }
    |   instr_elem name_contract {
            $$($1);
            $$->append($2);
        }
    ;

name_contract:
        '\'' NAME '\'' {
            $$(std::make_shared<InsOptionElem>($2));
        }
    |   NAME_LOOKUP NUM ']' {
            if (TableDict.find($1) == TableDict.end()) {
                LOG_ERROR("Table '%1' has not been declared.", $1);
                error();
            }
            else if (($2 < 0) || ($2 >= (int)TableDict[$1]->Records.size())) {
                LOG_ERROR("Can't get element %1 of table %2.", $2, $1);
                error();
            }
            else {
                $$(std::make_shared<InsNameElem>(TableDict[$1]->Records[$2]));
            }
        }

            // Example: ARITH[IDX]    where ARITH := { "ADD", "SUB", ...};
    |   NAME_LOOKUP NAME ']' {
            if (TableDict.find($1) == TableDict.end()) {
                LOG_ERROR("Table '%1' has not been declared.", $1);
                error();
            }
            else {
                $$(std::make_shared<InsListElem>($1, TableDict[$1], $2));
            }
        }

    |   '$' NAME_LOOKUP NUM ']' {
            if (TableDict.find($2) == TableDict.end()) {
                LOG_ERROR("Table %1 has not been declared.", $2);
                error();
            }
            else if (($3 < 0) || ($3 >= (int)TableDict[$2]->Records.size())) {
                LOG_ERROR("Can't get element %1 of table '%2'.", $3, $2);
                error();
            }
            else {
                $$(std::make_shared<InsNameElem>(TableDict[$2]->Records[$3]));
            }
        }
    |   '$' NAME_LOOKUP NAME ']' {
            if (TableDict.find($2) == TableDict.end()) {
                LOG_ERROR("Table '%1' has not been declared.", $2);
                error();
            }
            else {
                $$(std::make_shared<InsListElem>($2, TableDict[$2], $3));
            }
        }
    |   '"' NAME '"' {
            $$(std::make_shared<InsNameElem>($2));
        }
    ;

rt_list:
        rt_list regtransfer {
            // append any automatically generated register transfers and clear the list they were stored in.
            // Do nothing for a NOP (i.e. $2 = 0)
            if ($2 != NULL) {
                $1->append($2);
            }
            $$($1);
        }
    |   regtransfer {
            // WARN: the code here was RTL(StmtType::Assign), which is not right, since RTL parameter is an address
            $$(std::make_shared<RTL>(Address::ZERO));
            if ($1 != NULL) {
                $$->append($1);
            }
        }
    ;

regtransfer:
        assign_regtransfer { $$($1); }

        // Example: ADDFLAGS(r[tmp], reg_or_imm, r[rd])
        // $1              $2          $3
    |   NAME_CALL list_actualparameter ')' {
            if (Dict.FlagFuncs.find($1) != Dict.FlagFuncs.end()) {
                // Note: SETFFLAGS assigns to the floating point flags. All others to the integer flags
                const bool bFloat = (QString($1) == "SETFFLAGS");
                const OPER op = bFloat ? opFflags : opFlags;

                $$(new Assign(Terminal::get(op),
                        Binary::get(opFlagCall, Const::get($1), listExpToExp($2))));
            }
            else {
                LOG_ERROR("'%1' is not declared as a flag function.", $1);
                error();
            }
        }
    |   FLAGMACRO flag_list ')' {
            $$(nullptr);
        }
            // E.g. undefineflags() (but we don't handle this yet... flags are changed, but not in a way we support)
    |   FLAGMACRO ')' { $$(nullptr); }
    |   '_'           { $$(nullptr); }
    ;

flag_list:
        flag_list ',' REG_ID {
            // Not sure why the below is commented out (MVE)
//            Location* pFlag = Location::regOf(Dict.RegMap[$3]);
//            $1->push_back(pFlag);
//            $$ = $1;
            $$ = 0;
        }
    |   REG_ID {
//            std::list<Exp*>* tmp = new std::list<Exp*>;
//            Unary* pFlag = new Unary(opIdRegOf, Dict.RegMap[$1]);
//            tmp->push_back(pFlag);
//            $$ = tmp;
            $$ = 0;
        }
    ;

    // Note: this list is a list of strings (other code needs this)
list_parameter:
        list_parameter ',' param {
            assert($3 != 0);
            $1.push_back($3);
            $$ = $1;
        }
    |   param {
            $$();
            $$.push_back($1);
        }
    |   { $$(); }
    ;

param:
        NAME {
            // MVE: Likely wrong. Likely supposed to be OPERAND params only
            Dict.ParamSet.insert($1);
            $$($1);
        }
    ;

list_actualparameter:
        list_actualparameter ',' exp {
            $$($1);
            $$.push_back($3);
        }
    |   exp {
            $$();
            $$.push_back($1);
        }
    |   {   $$(); }
    ;

assign_regtransfer:
        // Size   guard =>     lhs    :=    rhs
        //  $1      $2         $4           $6
        assigntype exp THEN location DEFINE exp {
            Assign *a(new Assign($1, $4, $6));
            a->setGuard($2);
            $$(a);
        }
    // Size        lhs        :=     rhs
        // $1        $2        $3     $4
    |   assigntype location DEFINE exp {
            // update the size of any generated RT's
            $$(new Assign($1, $2, $4));
        }

    // FPUSH and FPOP are special "transfers" with just a Terminal
    |   FPUSH {
            $$(new Assign(Terminal::get(opNil), Terminal::get(opFpush)));
        }
    |   FPOP {
            $$(new Assign(Terminal::get(opNil), Terminal::get(opFpop)));
        }
    // Just a RHS? Is this used? Note: flag calls are handled at the rt: level
        // $1       $2
    |   assigntype exp {
            $$(new Assign($1, nullptr, $2));
        }
    ;

exp_term:
        NUM         { $$(Const::get($1)); }
    |   FLOATNUM    { $$(Const::get($1)); }
    |   '(' exp ')' { $$($2); }
    |   location    { $$($1); }
    |   '[' exp '?' exp COLON exp ']' { $$(Ternary::get(opTern, $2, $4, $6)); }
        // Address-of, for LEA type instructions
    |   ADDR exp ')' { $$(Unary::get(opAddrOf, $2)); }

        // Conversion functions, e.g. fsize(32, 80, modrm). Args are FROMsize, TOsize, EXPression
    |   CONV_FUNC NUM ',' NUM ',' exp ')' {
            $$(Ternary::get(strToOper($1), Const::get($2), Const::get($4), $6));
        }

        // Truncation function: ftrunc(3.01) == 3.00
    |   TRUNC_FUNC exp ')' { $$(Unary::get(opFtrunc, $2)); }

        // fabs function: fabs(-3.01) == 3.01
    |   FABS_FUNC exp ')' {  $$ = (SharedExp)Unary::get(opFabs, $2); }

        // FPUSH and FPOP
    |   FPUSH { $$(Terminal::get(opFpush)); }
    |   FPOP  { $$(Terminal::get(opFpop));  }
        // Transcendental functions
    |   TRANSCEND exp ')' { $$(Unary::get(strToOper($1), $2)); }

        // Example: *Use* of COND[idx]
        //  $1       $2
    |   NAME_LOOKUP NAME ']' {
            if (indexrefmap.find($2) == indexrefmap.end()) {
                LOG_ERROR("Index '%1' not declared for use.", $2);
                error();
            }
            else if (TableDict.find($1) == TableDict.end()) {
                LOG_ERROR("Table '%1 not declared for use.", $1);
                error();
            }
            else if (TableDict[$1]->getType() != EXPRTABLE) {
                LOG_ERROR("Table %1 is not an expression table "
                            "but appears to be used as one.", $1);
                error();
            }
            else  {
                auto exprTable = std::dynamic_pointer_cast<ExprTable>(TableDict[$1]);
                assert(exprTable != nullptr);

                if (exprTable->expressions.size() < indexrefmap[$2]->getNumTokens()) {
                    LOG_ERROR("Table '%1' (size %2) is too small to use '%3' (size %4) as an index",
                        ($1), exprTable->expressions.size(),
                        ($2), indexrefmap[$2]->getNumTokens());
                    error();
                }
            }
            // $1 is a map from string to Table*; $2 is a map from string to InsNameElem*
            $$(Binary::get(opExpTable, Const::get($1), Const::get($2)));
        }

        // This is a "lambda" function-like parameter
        // $1 is the "function" name, and $2 is a list of Exp* for the actual params.
        // I believe only PA/RISC uses these so far.
    |   NAME_CALL list_actualparameter ')' {
            if (Dict.ParamSet.find($1) != Dict.ParamSet.end() ) {
                if (Dict.DetParamMap.find($1) != Dict.DetParamMap.end()) {
                    ParamEntry& param = Dict.DetParamMap[$1];
                    if ($2.size() != param.m_funcParams.size() ) {
                        error();
                    }
                    else {
                        // Everything checks out. *phew*
                        // Note: the below may not be right! (MVE)
                        $$(Binary::get(opFlagDef, Const::get($1), listExpToExp($2)));
                    }
                }
                else {
                    error();
                }
            }
            else {
                error();
            }
        }

    |   SUCCESSOR exp ')' {
            $$(makeSuccessor($2));
        }
    ;

exp:
        exp S_E {
            $$(Unary::get(opSignExt, $1));
        }

        // "%prec CAST_OP" just says that this operator has the precedence of the dummy terminal CAST_OP
        // It's a "precedence modifier" (see "Context-Dependent Precedence" in the Bison documentation)
    //  $1   $2
    |   exp cast %prec CAST_OP {
            // size casts and the opSize operator were generally deprecated, but now opSize is used to transmit
            // the size of operands that could be memOfs from the decoder to type analysis
            if (static_cast<int>($2) == (int)STD_SIZE) {
                $$($1);
            }
            else {
                $$(Binary::get(opSize, Const::get($2), $1));
            }
        }

    |   NOT exp  { $$(Unary::get(opNot, $2));  }
    |   LNOT exp { $$(Unary::get(opLNot, $2)); }
    |   FNEG exp { $$(Unary::get(opFNeg, $2)); }
    |   exp FARITH_OP exp { $$(Binary::get(strToOper($2), $1, $3)); }
    |   exp ARITH_OP exp  { $$(Binary::get(strToOper($2), $1, $3)); }
    |   exp BIT_OP exp    { $$(Binary::get(strToOper($2), $1, $3)); }
    |   exp COND_OP exp   { $$(Binary::get(strToOper($2), $1, $3)); }
    |   exp LOG_OP exp    { $$(Binary::get(strToOper($2), $1, $3)); }

        // See comment above re "%prec LOOKUP_RDC"
        // Example: OP1[IDX] where OP1 := {     "&",  "|", "^", ...};
        //$1     $2      $3  $4   $5
    |   exp NAME_LOOKUP NAME ']' exp_term %prec LOOKUP_RDC {
            if (indexrefmap.find($3) == indexrefmap.end()) {
                error();
            }
            else if (TableDict.find($2) == TableDict.end()) {
                error();
            }
            else if (TableDict[$2]->getType() != OPTABLE) {
                error();
            }
            else if (TableDict[$2]->Records.size() < indexrefmap[$3]->getNumTokens()) {
                error();
            }

            $$(Ternary::get(opOpTable, Const::get($2), Const::get($3),
                    Binary::get(opList,
                            $1,
                            Binary::get(opList,
                                    $5,
                                    Terminal::get(opNil)))));
        }

    |   exp_term { $$($1); }
    ;

location:
        // This is for constant register numbers. Often, these are special, in the sense that the register mapping
        // is -1. If so, the equivalent of a special register is generated, i.e. a Terminal or opMachFtr
        // (machine specific feature) representing that register.
        REG_ID {
            const bool isFlag = QString($1).contains("flags");
            std::map<QString, int>::const_iterator it = Dict.RegMap.find($1);
            if (it == Dict.RegMap.end() && !isFlag) {
                error();
            }
            else if (isFlag || it->second == -1) {
                // A special register, e.g. %npc or %CF. Return a Terminal for it
                OPER op = strToTerm($1);
                if (op) {
                    $$(Terminal::get(op));
                }
                else {
                    // Machine specific feature
                    $$(Unary::get(opMachFtr, Const::get($1)));
                }
            }
            else {
                // A register with a constant reg nmber, e.g. %g2.  In this case, we want to return r[const 2]
                $$(Location::regOf(it->second));
            }
        }

    |   REG_IDX exp ']' {
            $$(Location::regOf($2));
        }

    |   REG_NUM {
            // chop off leading r
            const int regNum = QString($1).midRef(1).toInt();
            $$(Location::regOf(regNum));
        }

    |   MEM_IDX exp ']' {
            $$(Location::memOf($2));
        }
    |   NAME {
            // This is a mixture of the param: PARM {} match and the value_op: NAME {} match
            SharedExp s;
            std::set<QString>::iterator it = Dict.ParamSet.find($1);
            if (it != Dict.ParamSet.end()) {
                s = Location::get(opParam, Const::get($1), NULL);
            }
            else if (ConstTable.find($1) != ConstTable.end()) {
                s = Const::get(ConstTable[$1]); // TODO ???
            }
            else {
                error();
                s = Const::get(0);
            }

            $$(s);
        }

    |   exp AT '[' exp COLON exp ']' {
            $$(Ternary::get(opAt, $1, $4, $6));
        }

    |   TEMP {
            $$(Location::tempOf(Const::get($1)));
        }

        // This indicates a post-instruction marker (var tick)
    |   location '\'' {
            $$(Unary::get(opPostVar, $1));
        }
    |   SUCCESSOR exp ')' {
            $$(makeSuccessor($2));
        }
    ;

cast:
        '{' NUM '}' {
            $$ = $2;
        }
    ;

endianness:
        ENDIANNESS BIG {
            Dict.m_bigEndian = Endian::Big;
        }
    |   ENDIANNESS LITTLE {
            Dict.m_bigEndian = Endian::Little;
        }
    ;

assigntype:
        ASSIGNTYPE {
            const char c = qPrintable($1)[1];
            if (c == '*') {
                $$(SizeType::get(0)); // MVE: should remove these
            }
            else if (isdigit(c)) {
                const int size = QString($1).midRef(1).toInt();
                $$(std::make_shared<SizeType>(size));
            }
            else {
                // Skip star and letter
                int size = QString($1).midRef(2).toInt();
                if (size == 0) {
                    size = STD_SIZE;
                }

                switch (c) {
                    case 'i': $$(IntegerType::get(size, 1));  break;
                    case 'j': $$(IntegerType::get(size, 0));  break;
                    case 'u': $$(IntegerType::get(size, -1)); break;
                    case 'f': $$(FloatType::get(size));       break;
                    case 'c': $$(CharType::get());            break;
                    default:
                        LOG_WARN("Unexpected char '%1' in assign type", c);
                        $$ = IntegerType::get(0);
                }
            }
        }
    ;

// Section for indicating which instructions to substitute when using -f (fast but not quite as exact instruction
// mapping)
fastlist:
        FAST fastentries
    ;

fastentries:
        fastentries ',' fastentry
    |   fastentry
    ;

fastentry:
        NAME INDEX NAME {
            Dict.fastMap[QString($1)] = QString($3);
        }
    ;
