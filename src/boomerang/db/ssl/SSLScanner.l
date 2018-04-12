/*
 * This file is part of the Boomerang Decompiler.
 *
 * See the file "LICENSE.TERMS" for information on usage and
 * redistribution of this file, and for a DISCLAIMER OF ALL
 * WARRANTIES.
 */


/*
 * \file  sslscanner.l Defines a scanner to parse the tokens of a Semantic
 * Specification Language specification.
 */

/*
 * Shane Sendall (original C version) Dec 1997
 * Doug Simon (C++ version) Jan 1998
 * 29 Apr 02 - Mike: Mods for boomerang; removed &~, |~, and ^~ operators
 * 09 May 02 - Mike: ASSIGNSIZE is an num now
 * 05 May 04 - Mike: ASSIGNSIZE replaced by ASSIGNTYPE (text)
 * 20 Mar 11 - Mike: Note: YY_FATAL_ERROR needs (char*) cast inserted into output
 */

//%debug
%class-name="SSLScanner"
%baseclass-header="SSLScannerBase.h"
%class-header="SSLScanner.h"
%implementation-header="SSLScanner.ih"
%lex-source="SSLScanner.cpp"

%%

"INTEGER"       { return ssl::SSLParser::KW_INTEGER; }
"FLOAT"         { return ssl::SSLParser::KW_FLOAT; }
"OPERAND"       { return ssl::SSLParser::KW_OPERAND; }
"ENDIANNESS"    {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::KW_ENDIANNESS;
    }
"BIG"           {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::KW_BIG;
    }
"LITTLE"        {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::KW_LITTLE;
    }
"COVERS"        { return ssl::SSLParser::KW_COVERS; }
"SHARES"        { return ssl::SSLParser::KW_SHARES; }
"FAST"          { return ssl::SSLParser::KW_FAST; }

"FPOP"      {    return ssl::SSLParser::KW_FPOP; }
"FPUSH"     {    return ssl::SSLParser::KW_FPUSH; }


"*"[a-z]?[0-9]*"*" {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::ASSIGNTYPE;
    }

"or"    |
"and"   {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::LOG_OP;
    }

"="     |
"~="    |
"<"     |
">"     |
"<="    |
">="    |
"<u"    |
">u"    |
"<=u"   |
">=u"   {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::COND_OP;
    }

"rlc"   |
"rrc"   |
"rl"    |
"rr"    |
">>"    |
"<<"    |
">>A"   |
"|"     |
"&"     |
"^"     {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::BIT_OP;
    }

"%"     |
"*"     |
"/"     |
"*!"    |
"/!"    |
"%!"    |
"+"     |
"-"     {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::ARITH_OP;
    }

"*f"    |
"*fd"   |
"*fq"   |
"*fsd"  |
"*fdq"  |
"/f"    |
"/fd"   |
"/fq"   |
"+f"    |
"+fd"   |
"+fq"   |
"-f"    |
"-fd"   |
"-fq"   |
"pow"   {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::FARITH_OP;
    }

"~"     { return ssl::SSLParser::NOT;  }
"L~"    { return ssl::SSLParser::LNOT; }
"~f"    { return ssl::SSLParser::FNEG; }
"=>"    { return ssl::SSLParser::THEN; }
"->"    { return ssl::SSLParser::INDEX; }
":="    { return ssl::SSLParser::ASSIGN; }

".."    { return ssl::SSLParser::TO;    }
":"     { return ssl::SSLParser::COLON; }
"!"     { return ssl::SSLParser::S_E;   }
"@"     { return ssl::SSLParser::AT;    }
"addr(" { return ssl::SSLParser::ADDR;  }

"fsize("    |
"itof("     |
"ftoi("     |
"fround("   |
"truncu("   |
"truncs("   |
"zfill("    |
"sgnex("    {
        // chop off trailing paren
        *d_val = QString(matched().c_str()).left(matched().length()-1);
        return ssl::SSLParser::CONV_FUNC;
    }
"ftrunc("   {
        // chop off trailing paren
        *d_val = QString(matched().c_str()).left(matched().length()-1);
        return ssl::SSLParser::TRUNC_FUNC;
    }
"fabs("     {
        // chop off trailing paren
        *d_val = QString(matched().c_str()).left(matched().length()-1);
        return ssl::SSLParser::FABS_FUNC;
    }
"defineflags("      |
"undefineflags("    { return ssl::SSLParser::FLAGMACRO; }

"sin("     |
"cos("     |
"tan("     |
"arctan("  |
"log2("    |
"loge("    |
"log10("   |
"execute(" |
"sqrt(" {
        // chop off trailing paren
        *d_val = QString(matched().c_str()).left(matched().length()-1);
        return ssl::SSLParser::TRANSCEND;
    }

"succ("     { return ssl::SSLParser::SUCCESSOR; }

"tmp"[a-zA-Z0-9_]* {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::TEMP;
    }

"r["        {   return ssl::SSLParser::REG_IDX; }
"r"[0-9]*   {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::REG_NUM;
    }
"m["        {    return ssl::SSLParser::MEM_IDX; }
"_"         {    return matched()[0];    }

_?[A-Za-z][A-Za-z0-9_]* {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::IDENTIFIER;
    }
"%"[A-Za-z][A-Za-z0-9]* {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::REG_ID;
    }
_?[A-Za-z][A-Za-z0-9_]*"(" {
        // chop off trailing paren
        *d_val = QString(matched().c_str()).left(matched().length()-1);
        return ssl::SSLParser::NAME_CALL;
    }
_?[A-Za-z][A-Za-z0-9_]*"[" {
        // chop off trailing bracket
        *d_val = QString(matched().c_str()).left(matched().length()-1);
        return ssl::SSLParser::NAME_LOOKUP;
    }
"."[A-Za-z][A-Za-z.0-9]* |
"^"\"[A-Za-z][A-Za-z]*\" {
        *d_val = QString(matched().c_str());
        return ssl::SSLParser::DECOR;
    }

[?,{}()'"]  {    return matched()[0];    }
"]"         {    return matched()[0];    }
"["         {    return matched()[0];    }
";"         {    return matched()[0];    }
"$"         {    return matched()[0];    }
-?[0-9]+"."[0-9]+ {
        *d_val = atof(matched().c_str());
        return ssl::SSLParser::FLOAT_NUM;
     }
-?[0-9]+ {
        *d_val = (int)strtol(matched().c_str(), 0, 10);
        return ssl::SSLParser::NUM;
     }

0x[A-F0-9]+ {
        *d_val = (int)strtol(matched().c_str(), 0, 16);
        return ssl::SSLParser::NUM;
     }

-?"2**"[0-9]+    {
        // a power of two
        int sign = (matched()[0] == '-' ? -1 : 1);
        const char* start = &matched()[((sign == -1) ? 4:3)];

        *d_val = (int)(1 << (strtol(start, 0, 10) * sign));
        return ssl::SSLParser::NUM;
    }

[ \t]+          ;
#.*$            ;    // comment
.               ;
\n

%%
