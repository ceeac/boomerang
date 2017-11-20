// Generated by Bisonc++ V6.00.00 on Fri, 13 Oct 2017 13:43:01 +0200

#ifndef sslSSLParser_h_included
#define sslSSLParser_h_included

// $insert baseclass
#include "SSLParserBase.h"
// $insert scanner.h
#include "SSLScanner.h"

// $insert namespace-open
namespace ssl
{

#undef SSLParser
    // CAVEAT: between the baseclass-include directive and the
    // #undef directive in the previous line references to SSLParser
    // are read as SSLParserBase.
    // If you need to include additional headers in this file
    // you should do so after these comment-lines.


class SSLParser: public SSLParserBase
{
    std::ifstream m_file;

    // $insert scannerobject
    SSLScanner d_scanner;


    public:
        SSLParser(RTLInstDict& dict, const QString& filename)
            : m_file(qPrintable(filename))
            , d_scanner(m_file)
            , m_dict(dict)
        {}

        SSLParser(RTLInstDict& dict, std::istream& in = std::cin, std::ostream& out = std::cout)
            : d_scanner(in, out)
            , m_dict(dict)
        {}

        int parse();

        /**
         * Parses an assignment from \p str
         * \returns an Assignment or nullptr.
         */
        static Statement *parseExp(const char *str);

    private:
        void error();                   // called on (syntax) errors
        int lex();                      // returns the next token from the
                                        // lexical scanner.
        void print();                   // use, e.g., d_token, d_loc
        void exceptionHandler(std::exception const &exc);

    // support functions for parse():
        void executeAction__(int ruleNr);
        void errorRecovery__();
        void nextCycle__();
        void nextToken__();
        void print__();


    private:
        /**
         * Convert a string operator (e.g. "+f") to an OPER (opFPlus)
         * \note    An attempt is made to make this moderately efficient,
         *          else we might have a skip chain of string comparisons
         * \note    This is a member of SSLParser so we can call yyerror
         *          and have line number etc printed out
         * \param   s pointer to the operator C string
         * \returns An OPER, or opWild if not found
         */
        OPER strToOper(const QString& s);
        OPER strToTerm(const QString& s);

        /**
         * Convert a list of formal parameters in the form of a STL list of strings
         * into one expression (using opList)
         * \param   ls - the list of strings
         * \returns The opList expression
         */
        SharedExp listStrToExp(const std::list<QString>& ls);

        /**
         * Convert a list of actual parameters in the form of a STL list of Exps
         * into one expression (using opList)
         * \note The expressions in the list are not cloned;
         *       they are simply copied to the new opList
         *
         * \param le  the list of expressions
         * \returns The opList Expression
         */
        SharedExp listExpToExp(const std::deque<SharedExp>& le);

        /**
         * Expand tables in an RTL and save to dictionary
         * \note    This may generate many entries
         *
         * \param   iname Parser object representing the instruction name
         * \param   params Parser object representing the instruction params
         * \param   o_rtlist Original rtlist object (before expanding)
         * \param   Dict Ref to the dictionary that will contain the results of the parse
         */
        void expandTables(const std::shared_ptr<InsNameElem>& iname, const std::list<QString>& params, SharedRTL o_rtlist, RTLInstDict& Dict);

        /**
         * Make the successor of the given expression, e.g. given r[2], return succ( r[2] )
         * (using opSuccessor).
         * We can't do the successor operation here, because the parameters
         * are not yet instantiated (still of the form param(rd)).
         * Actual successor done in Exp::fixSuccessor()
         *
         * \note       The given expression should be of the form    r[const]
         * \note       The parameter expresion is copied (not cloned) in the result
         * \param      e  The expression to find the successor of
         * \returns    The modified expression
         */
        SharedExp makeSuccessor(SharedExp e);

    private:
        RTLInstDict& m_dict;

        static Assign *theAssign; ///< for parseExp()
        bool m_floatRegister; ///< float / integer register, for register definitions
        std::map<QString, int> m_constTable; ///< maps constant names to values
        std::map<QString, std::shared_ptr<Table>> m_tableDict;
        std::map<QString, std::shared_ptr<InsNameElem>> m_indexRefMap;
};

// $insert namespace-close
}

#endif