/*
 * This file is part of the Boomerang Decompiler.
 *
 * See the file "LICENSE.TERMS" for information on usage and
 * redistribution of this file, and for a DISCLAIMER OF ALL
 * WARRANTIES.
 */

// options
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


// keywords
%token KW_INTEGER KW_FLOAT KW_ENDIANNESS
%token KW_BIG KW_LITTLE
%token KW_OPERAND
%token KW_COVERS KW_SHARES KW_FAST
%token KW_FPOP KW_FPUSH


// types & variables
%token <str> IDENTIFIER     // name of a variable
%token <str> REG_IDENTIFIER // name of a register

// literals
%token <num> NUM
%token <dbl> FLOAT_NUM ///< I'd prefer type double here!

// misc
%token <str> ASSIGNTYPE
%token <str> REG_NUM DECOR
%token <str> TEMP CONV_FUNC TRUNC_FUNC TRANSCEND FABS_FUNC
%token <str> NAME_CALL NAME_LOOKUP
%token FLAGMACRO SUCCESSOR
%token ADDR

// operators
%token INDEX
%token FNEG THEN
%token TO COLON REG_IDX ASSIGN
%token MEM_IDX

%left  <str> LOG_OP         ///< Logical operation
%right <str> COND_OP        ///< Conditional operation
%left  <str> BIT_OP         ///< Bit operation
%left  <str> ARITH_OP       ///< Arithmetic operation
%left  <str> FARITH_OP
%right NOT LNOT
%left <str> CAST_OP
%left LOOKUP_RDC
%left S_E       // Sign extend. Note it effectively has low precedence, because being a post operator,
                // the whole expression is already parsed, and hence is sign extended.
                // Another reason why ! is deprecated!

// maybe it should be right-associative
// to make things like %eax@5 + 10 work
%nonassoc AT

%type <num> const_exp
%type <exp> exp location exp_term
%type <str> bin_oper param
%type <regtransfer> regtransfer assign_regtransfer
%type <rtlist> rt_list
%type <typ> assigntype
%type <num> cast
%type <tab> table_expr
%type <insel> name_contract instr_name instr_elem
%type <strlist> reg_table
%type <strlist> paramlist func_parameter
%type <namelist> str_term str_expr str_array name_expand opstr_expr opstr_array
%type <explist> flag_list
%type <explist> exprstr_expr exprstr_array
%type <explist> list_actualparameter

%%

spec_or_assign:
        ssl_specs
    |   assign_regtransfer {
            theAssign = dynamic_cast<Assign *>($1);
            assert(theAssign != nullptr);
        }
    |   exp {
            theAssign = new Assign(Terminal::get(opNil), $1);
        }
    ;

ssl_specs:
        ssl_spec ';'
    |   ssl_spec ';' ssl_specs
    ;

ssl_spec:
        endianness      // Optional one-line section declaring endianness
    |   const_def       // Name := value
    |   register_def    // Definition of register(s)
    |   table_def
        // Declaration of "flag functions". These describe the detailed flag setting semantics for instructions
    |   flagfunc_def
    |   instruction_def

        // Optional section describing faster versions of instructions (e.g. that don't inplement the full
        // specifications, but if they work, will be much faster)
    |   KW_FAST fastlist

        // Addressing modes (or instruction operands) (optional)
    |   KW_OPERAND operandlist { m_dict.fixupParams(); }

    ;

endianness:
        KW_ENDIANNESS KW_BIG {
            m_dict.m_bigEndian = Endian::Big;
        }
    |   KW_ENDIANNESS KW_LITTLE {
            m_dict.m_bigEndian = Endian::Little;
        }
    ;

const_def:
        IDENTIFIER ASSIGN const_exp {
            if (m_constTable.find($1) != m_constTable.end()) {
                error();
            }
            m_constTable[QString($1)] = $3;
        }
    ;

const_exp: // TODO: More operators
        NUM { $$ = $1; }
    |   IDENTIFIER {
            if (m_constTable.find($1) == m_constTable.end()) {
                LOG_ERROR("Undefined constant '%1' encountered.", $1);
                error();
            }
            $$ = m_constTable[QString($1)];
        }
    |   '(' const_exp ')' { $$ = $2; }
    |   const_exp ARITH_OP const_exp {
            if (QString($2) == "+") {
                $$ = $1 + $3;
            }
            else if (QString($2) == "-") {
                $$ = $1 - $3;
            }
            else {
                LOG_ERROR("Constants can only be initialized "
                    "by expressions containing '+' and '-'.");
                error();
            }
        }
    ;

register_def:
        KW_INTEGER { m_floatRegister = false; } reglist_sequence
    |   KW_FLOAT   { m_floatRegister = true;  } reglist_sequence
    ;

reglist_sequence:
        a_reglist
    |   a_reglist ',' reglist_sequence
    ;

a_reglist:
        // %eax -> 3
        REG_IDENTIFIER INDEX NUM {
            if (m_dict.RegMap.find($1) != m_dict.RegMap.end()) {
                error();
            }
            m_dict.RegMap[$1] = $3;
        }
        // %eax[32] -> 1
    |   REG_IDENTIFIER '[' NUM ']' INDEX NUM {
            if (m_dict.RegMap.find($1) != m_dict.RegMap.end()) {
                error();
            }
            m_dict.addRegister( $1, $6, $3, m_floatRegister);
        }
        // %eax_edx[64] -> 10 COVERS eax..edx (note: eax and edx must have adjacent register IDs)
    |   REG_IDENTIFIER '[' NUM ']' INDEX NUM KW_COVERS REG_IDENTIFIER TO REG_IDENTIFIER {
            if (m_dict.RegMap.find($1) != m_dict.RegMap.end()) {
                error();
            }

            m_dict.RegMap[$1] = $6;
            // Now for detailed Reg information
            if (m_dict.DetRegMap.find($6) != m_dict.DetRegMap.end()) {
                error();
            }

            m_dict.DetRegMap[$6].setName($1);
            m_dict.DetRegMap[$6].setSize($3);

            // check range is legitimate for size. 8,10
            if ((m_dict.RegMap.find($8) == m_dict.RegMap.end()) || (m_dict.RegMap.find($10) == m_dict.RegMap.end())) {
                error();
            }
            else {
                int bitsize = m_dict.DetRegMap[m_dict.RegMap[$10]].getSize();
                for (int i = m_dict.RegMap[$8]; i != m_dict.RegMap[$10]; i++) {
                    if (m_dict.DetRegMap.find(i) == m_dict.DetRegMap.end()) {
                        error();
                        break;
                    }
                    bitsize += m_dict.DetRegMap[i].getSize();
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
            m_dict.DetRegMap[$6].setMappedIndex(m_dict.RegMap[$8]);
            m_dict.DetRegMap[$6].setMappedOffset(0);
            m_dict.DetRegMap[$6].setIsFloat(m_floatRegister);
        }
        // %ax[16] -> 10 SHARES %eax@[0..15]
    |   REG_IDENTIFIER '[' NUM ']' INDEX NUM KW_SHARES REG_IDENTIFIER AT '[' NUM TO NUM ']' {
            if (m_dict.RegMap.find($1) != m_dict.RegMap.end()) {
                error();
            }

            m_dict.RegMap[$1] = $6;

            // Now for detailed Reg information
            if (m_dict.DetRegMap.find($6) != m_dict.DetRegMap.end()) {
                error();
            }

            m_dict.DetRegMap[$6].setName($1);
            m_dict.DetRegMap[$6].setSize($3);

            // Do checks
            if ($3 != ($13 - $11) + 1) {
                error();
            }

            if (m_dict.RegMap.find($8) != m_dict.RegMap.end()) {
                if ($13 >= m_dict.DetRegMap[m_dict.RegMap[$8]].getSize()) {
                    error();
                }
            }
            else {
                error();
            }

            m_dict.DetRegMap[$6].setMappedIndex(m_dict.RegMap[$8]);
            m_dict.DetRegMap[$6].setMappedOffset($11);
            m_dict.DetRegMap[$6].setIsFloat(m_floatRegister);
        }
        // [%eax, %edx][32] -> 10..11
    |   '[' reg_table ']' '[' NUM ']' INDEX NUM TO NUM {
            if ((int)($2.size()) != ($10 - $8 + 1)) {
                error();
            }
            else {
                std::list<QString>::iterator loc = $2.begin();
                for (int x = $8; x <= $10; x++, loc++) {
                    if (m_dict.RegMap.find(*loc) != m_dict.RegMap.end()) {
                        error();
                    }
                    m_dict.addRegister(*loc, x, $5, m_floatRegister);
                }
            }
        }
        // [%eax, %edx][32] -> -1
    |   '[' reg_table ']' '[' NUM ']' INDEX NUM {
            for (const QString& regName : $2) {
                if (m_dict.RegMap.find(regName) != m_dict.RegMap.end()) {
                    error();
                }
                m_dict.addRegister(regName, $8, $5, m_floatRegister);
            }
        }
    ;

reg_table:
        REG_IDENTIFIER {
            $$();
            $$.push_back($1);
        }
    |   REG_IDENTIFIER ',' reg_table {
            $3.push_back($1);
            $$($3);
        }
    ;

table_def:
        // Ex.: shiftOperands := { "<<", ">>" }
        IDENTIFIER ASSIGN table_expr {
            const QString name($1);
            m_tableDict[name] = $3;
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

            for (const QString& i : $1) {
                for (const QString& j : $2) {
                    $$.push_back(i + j);
                }
            }
        }
    |   str_term {
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


name_expand:
        '\'' IDENTIFIER '\'' {
            $$();
            $$.push_back("");
            $$.push_back($2);
        }
    |   '"' IDENTIFIER '"' {
            $$(1, $2);
        }
    |   '$' IDENTIFIER {
            // expand $2 from table of names
            if (m_tableDict.find($2) != m_tableDict.end()) {
                if (m_tableDict[$2]->getType() == NAMETABLE)
                    $$(m_tableDict[$2]->Records);
                else {
                    error();
                }
            }
            else {
                error();
            }
        }
    |   IDENTIFIER {
            // try and expand $1 from table of names.
            // if fail, expand using '"' NAME '"' rule
            if (m_tableDict.find($1) != m_tableDict.end()) {
                if (m_tableDict[$1]->getType() == NAMETABLE) {
                    $$(m_tableDict[$1]->Records);
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

opstr_expr:
        // Example: shiftOps := { "<<", ">>", ">>A" };
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

bin_oper:
        BIT_OP    { $$($1); }
    |   ARITH_OP  { $$($1); }
    |   FARITH_OP { $$($1); }
    ;

exprstr_expr:
        // Example: coditionCodes := { "~%ZF", "%ZF", "~(%ZF | (%NF ^ %OF))", ...
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
        //$1     $2      $3        $4   $5
    |   exp NAME_LOOKUP IDENTIFIER ']' exp_term %prec LOOKUP_RDC {
            if (m_indexRefMap.find($3) == m_indexRefMap.end()) {
                error();
            }
            else if (m_tableDict.find($2) == m_tableDict.end()) {
                error();
            }
            else if (m_tableDict[$2]->getType() != OPTABLE) {
                error();
            }
            else if (m_tableDict[$2]->Records.size() < m_indexRefMap[$3]->getNumTokens()) {
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

 cast:
        '{' NUM '}' {
            $$ = $2;
        }
    ;


exp_term:
        NUM         { $$(Const::get($1)); }
    |   FLOAT_NUM   { $$(Const::get($1)); }
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

        // Transcendental functions
    |   TRANSCEND exp ')' { $$(Unary::get(strToOper($1), $2)); }

        // Example: *Use* of COND[idx]
        //  $1       $2
    |   NAME_LOOKUP IDENTIFIER ']' {
            if (m_indexRefMap.find($2) == m_indexRefMap.end()) {
                LOG_ERROR("Index '%1' not declared for use.", $2);
                error();
            }
            else if (m_tableDict.find($1) == m_tableDict.end()) {
                LOG_ERROR("Table '%1 not declared for use.", $1);
                error();
            }
            else if (m_tableDict[$1]->getType() != EXPRTABLE) {
                LOG_ERROR("Table %1 is not an expression table "
                            "but appears to be used as one.", $1);
                error();
            }
            else  {
                auto exprTable = std::dynamic_pointer_cast<ExprTable>(m_tableDict[$1]);
                assert(exprTable != nullptr);

                if (exprTable->expressions.size() < m_indexRefMap[$2]->getNumTokens()) {
                    LOG_ERROR("Table '%1' (size %2) is too small to use '%3' (size %4) as an index",
                        ($1), exprTable->expressions.size(),
                        ($2), m_indexRefMap[$2]->getNumTokens());
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
            if (m_dict.ParamSet.find($1) != m_dict.ParamSet.end() ) {
                if (m_dict.DetParamMap.find($1) != m_dict.DetParamMap.end()) {
                    ParamEntry& param = m_dict.DetParamMap[$1];
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

location:
        // This is for constant register numbers. Often, these are special, in the sense that the register mapping
        // is -1. If so, the equivalent of a special register is generated, i.e. a Terminal or opMachFtr
        // (machine specific feature) representing that register.
        REG_IDENTIFIER {
            const bool isFlag = QString($1).contains("flags");
            std::map<QString, int>::const_iterator it = m_dict.RegMap.find($1);
            if (it == m_dict.RegMap.end() && !isFlag) {
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
    |   IDENTIFIER {
            // This is a mixture of the param: PARM {} match and the value_op: NAME {} match
            SharedExp s;
            std::set<QString>::iterator it = m_dict.ParamSet.find($1);
            if (it != m_dict.ParamSet.end()) {
                s = Location::get(opParam, Const::get($1), NULL);
            }
            else if (m_constTable.find($1) != m_constTable.end()) {
                s = Const::get(m_constTable[$1]); // TODO ???
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

// Flag definitions
flagfunc_def:
        // $1       $2      $3  $4    $5    $6
        NAME_CALL paramlist ')' '{' rt_list '}' {
            // Note: $2 is a list of strings
            m_dict.FlagFuncs[$1] = std::make_shared<FlagDef>(listStrToExp($2), $5);
        }
    ;

    // Note: this list is a list of strings (other code needs this)
paramlist:
        { $$(); }
    |   param {
            $$();
            $$.push_back($1);
        }
    |   paramlist ',' param {
            assert($3 != 0);
            $1.push_back($3);
            $$ = $1;
        }
    ;

param:
        IDENTIFIER {
            // MVE: Likely wrong. Likely supposed to be OPERAND params only
            m_dict.ParamSet.insert($1);
            $$($1);
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
            if (m_dict.FlagFuncs.find($1) != m_dict.FlagFuncs.end()) {
                // Note: SETFFLAGS assigns to the floating point flags. All others to the integer flags
                const bool floatFlags = (QString($1) == "SETFFLAGS");
                const OPER op = floatFlags ? opFflags : opFlags;

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

assign_regtransfer:
        // Size   guard =>     lhs    :=    rhs
        //  $1      $2         $4           $6
        assigntype exp THEN location ASSIGN exp {
            Assign *a(new Assign($1, $4, $6));
            a->setGuard($2);
            $$(a);
        }
    // Size        lhs        :=     rhs
        // $1        $2        $3     $4
    |   assigntype location ASSIGN exp {
            // update the size of any generated RT's
            $$(new Assign($1, $2, $4));
        }

    // FPUSH and FPOP are special "transfers" with just a Terminal
    |   KW_FPUSH {
            $$(new Assign(Terminal::get(opNil), Terminal::get(opFpush)));
        }
    |   KW_FPOP {
            $$(new Assign(Terminal::get(opNil), Terminal::get(opFpop)));
        }
    ;

assigntype:
        ASSIGNTYPE {
            QString typeStr($1);
            // chop off asterisks
            typeStr = typeStr.mid(1, typeStr.length()-2);

            if (typeStr.isEmpty()) {
                $$(VoidType::get());
            }
            else {
                bool ok = false;
                int tySize = typeStr.toInt(&ok);
                if (ok) {
                    $$(std::make_shared<SizeType>(tySize));
                }
                else {
                    char tyAbbr = typeStr[0].toLatin1();
                    tySize = typeStr.midRef(1).toInt(&ok);
                    if (!ok || tyAbbr == 0) {
                        LOG_ERROR("Parse error: Unknown type '%1'", typeStr);
                        error();
                    }

                    switch(tyAbbr) {
                    case 'i': $$(IntegerType::get(tySize, 1));  break;
                    case 'j': $$(IntegerType::get(tySize, 0));  break;
                    case 'u': $$(IntegerType::get(tySize, -1)); break;
                    case 'f': $$(FloatType::get(tySize));       break;
                    case 'c': $$(CharType::get());              break;
                    default:
                        LOG_WARN("Unexpected char '%1' in assign type", tyAbbr);
                        $$ = IntegerType::get(0);
                    }
                }
            }
        }
    ;

flag_list:
        flag_list ',' REG_IDENTIFIER {
            // Not sure why the below is commented out (MVE)
//            Location* pFlag = Location::regOf(m_dict.RegMap[$3]);
//            $1->push_back(pFlag);
//            $$ = $1;
            $$ = 0;
        }
    |   REG_IDENTIFIER {
//            std::list<Exp*>* tmp = new std::list<Exp*>;
//            Unary* pFlag = new Unary(opIdRegOf, m_dict.RegMap[$1]);
//            tmp->push_back(pFlag);
//            $$ = tmp;
            $$ = 0;
        }
    ;

// instruction definition
instruction_def:
        //  $1                                         $3         $4
        instr_name { $1->getRefMap(m_indexRefMap); } paramlist rt_list {
            // This function expands the tables and saves the expanded RTLs to the dictionary
            expandTables($1, $3, $4, m_dict);
        }
    ;

instr_name:
        instr_elem { $$($1); }
    |   instr_name DECOR {
            QString decorName = $2;
            assert(!decorName.isEmpty());

            // remove leading ^
            if (decorName[0] == '^') { decorName.replace(0, 1, ""); }

            decorName = decorName.replace("\"", "");
            decorName = decorName.replace(".", "");
            decorName = decorName.replace("_", "");

            $$($1);
            $$->append(std::make_shared<InsNameElem>(decorName));
        }
    ;

instr_elem:
        IDENTIFIER { $$(std::make_shared<InsNameElem>($1)); }
    |   name_contract { $$($1); }
    |   instr_elem name_contract {
            $$($1);
            $$->append($2);
        }
    ;

name_contract:
        '\'' IDENTIFIER '\'' {
            $$(std::make_shared<InsOptionElem>($2));
        }
    |   NAME_LOOKUP NUM ']' {
            if (m_tableDict.find($1) == m_tableDict.end()) {
                LOG_ERROR("Table '%1' has not been declared.", $1);
                error();
            }
            else if (($2 < 0) || ($2 >= (int)m_tableDict[$1]->Records.size())) {
                LOG_ERROR("Can't get element %1 of table %2.", $2, $1);
                error();
            }
            else {
                $$(std::make_shared<InsNameElem>(m_tableDict[$1]->Records[$2]));
            }
        }

        // Example: ARITH[IDX]    where ARITH := { "ADD", "SUB", ...};
    |   NAME_LOOKUP IDENTIFIER ']' {
            if (m_tableDict.find($1) == m_tableDict.end()) {
                LOG_ERROR("Table '%1' has not been declared.", $1);
                error();
            }
            else {
                $$(std::make_shared<InsListElem>($1, m_tableDict[$1], $2));
            }
        }

    |   '$' NAME_LOOKUP NUM ']' {
            if (m_tableDict.find($2) == m_tableDict.end()) {
                LOG_ERROR("Table %1 has not been declared.", $2);
                error();
            }
            else if (($3 < 0) || ($3 >= (int)m_tableDict[$2]->Records.size())) {
                LOG_ERROR("Can't get element %1 of table '%2'.", $3, $2);
                error();
            }
            else {
                $$(std::make_shared<InsNameElem>(m_tableDict[$2]->Records[$3]));
            }
        }
    |   '$' NAME_LOOKUP IDENTIFIER ']' {
            if (m_tableDict.find($2) == m_tableDict.end()) {
                LOG_ERROR("Table '%1' has not been declared.", $2);
                error();
            }
            else {
                $$(std::make_shared<InsListElem>($2, m_tableDict[$2], $3));
            }
        }
    |   '"' IDENTIFIER '"' {
            $$(std::make_shared<InsNameElem>($2));
        }
    ;


// Section for indicating which instructions to substitute when using -f (fast but not quite as exact instruction
// mapping)
fastlist:
        fastlist ',' fastentry
    |   fastentry
    ;

fastentry:
        IDENTIFIER INDEX IDENTIFIER {
            m_dict.fastMap[QString($1)] = QString($3);
        }
    ;

operandlist:
        operand
    |   operand ',' operandlist
    ;

operand:
        // In the .tex documentation, this is the first, or variant kind
        // Example: reg_or_imm := { imode, rmode };
        //$1    $2    $3     $4    $5
        param ASSIGN '{' paramlist '}' {
            // Note: the below copies the list of strings!
                m_dict.DetParamMap[$1].m_params = $4;
                m_dict.DetParamMap[$1].m_kind = PARAM_VARIANT;
            }

        // In the documentation, these are the second and third kinds
        // The third kind is described as the functional, or lambda, form
        // In terms of DetParamMap[].kind, they are PARAM_EXP unless there
        // actually are parameters in square brackets, in which case it is
        // PARAM_LAMBDA
        // Example: indexA    rs1, rs2 *i32* r[rs1] + r[rs2]
        //$1       $2         $3           $4      $5
    |   param paramlist func_parameter assigntype exp {
            ParamEntry &param = m_dict.DetParamMap[$1];
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
        '[' paramlist ']' { $$($2); }
    |   { $$(); }
    ;

