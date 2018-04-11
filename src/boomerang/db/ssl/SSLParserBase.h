// Generated by Bisonc++ V6.01.03 on Wed, 11 Apr 2018 15:59:32 +0200

// hdr/includes
#ifndef sslSSLParserBase_h_included
#define sslSSLParserBase_h_included

#include <exception>
#include <vector>
#include <iostream>
// $insert polyincludes
#include <memory>
// $insert preincludes
#include "sslparser_support.h"

// hdr/baseclass

namespace // anonymous
{
    struct PI__;
}

// $insert namespace-open
namespace ssl
{

// $insert polymorphic
enum class Tag__
{
    charTy,
    intTy,
    bin,
    loc,
    dbl,
    typ,
    namelist,
    tab,
    num,
    rtlist,
    regtransfer,
    exp,
    str,
    insel,
    explist,
    strlist,
    sizeTy,
    opTable,
    expTable,
    floatTy,
    aConst,
    tern,
    asgn,
};

namespace Meta__
{

extern size_t const *t_nErrors;

extern size_t const *s_nErrors__;

template <Tag__ tag>
struct TypeOf;

template <typename Tp_>
struct TagOf;

// $insert polymorphicSpecializations
enum { sizeofTag__ = 23 };

extern char const *idOfTag__[];
template <>
struct TagOf<std::shared_ptr<CharType>>
{
    static Tag__ const tag = Tag__::charTy;
};

template <>
struct TagOf<std::shared_ptr<IntegerType>>
{
    static Tag__ const tag = Tag__::intTy;
};

template <>
struct TagOf<std::shared_ptr<Binary>>
{
    static Tag__ const tag = Tag__::bin;
};

template <>
struct TagOf<std::shared_ptr<Location>>
{
    static Tag__ const tag = Tag__::loc;
};

template <>
struct TagOf<double>
{
    static Tag__ const tag = Tag__::dbl;
};

template <>
struct TagOf<SharedType>
{
    static Tag__ const tag = Tag__::typ;
};

template <>
struct TagOf<std::deque<QString>>
{
    static Tag__ const tag = Tag__::namelist;
};

template <>
struct TagOf<std::shared_ptr<Table>>
{
    static Tag__ const tag = Tag__::tab;
};

template <>
struct TagOf<int>
{
    static Tag__ const tag = Tag__::num;
};

template <>
struct TagOf<SharedRTL>
{
    static Tag__ const tag = Tag__::rtlist;
};

template <>
struct TagOf<Statement *>
{
    static Tag__ const tag = Tag__::regtransfer;
};

template <>
struct TagOf<SharedExp>
{
    static Tag__ const tag = Tag__::exp;
};

template <>
struct TagOf<QString>
{
    static Tag__ const tag = Tag__::str;
};

template <>
struct TagOf<std::shared_ptr<InsNameElem>>
{
    static Tag__ const tag = Tag__::insel;
};

template <>
struct TagOf<std::deque<SharedExp>>
{
    static Tag__ const tag = Tag__::explist;
};

template <>
struct TagOf<std::list<QString>>
{
    static Tag__ const tag = Tag__::strlist;
};

template <>
struct TagOf<std::shared_ptr<SizeType>>
{
    static Tag__ const tag = Tag__::sizeTy;
};

template <>
struct TagOf<std::shared_ptr<OpTable>>
{
    static Tag__ const tag = Tag__::opTable;
};

template <>
struct TagOf<std::shared_ptr<ExprTable>>
{
    static Tag__ const tag = Tag__::expTable;
};

template <>
struct TagOf<std::shared_ptr<FloatType>>
{
    static Tag__ const tag = Tag__::floatTy;
};

template <>
struct TagOf<std::shared_ptr<Const>>
{
    static Tag__ const tag = Tag__::aConst;
};

template <>
struct TagOf<std::shared_ptr<Ternary>>
{
    static Tag__ const tag = Tag__::tern;
};

template <>
struct TagOf<std::shared_ptr<Assign>>
{
    static Tag__ const tag = Tag__::asgn;
};

template <>
struct TypeOf<Tag__::charTy>
{
    typedef std::shared_ptr<CharType> type;
};

template <>
struct TypeOf<Tag__::intTy>
{
    typedef std::shared_ptr<IntegerType> type;
};

template <>
struct TypeOf<Tag__::bin>
{
    typedef std::shared_ptr<Binary> type;
};

template <>
struct TypeOf<Tag__::loc>
{
    typedef std::shared_ptr<Location> type;
};

template <>
struct TypeOf<Tag__::dbl>
{
    typedef double type;
};

template <>
struct TypeOf<Tag__::typ>
{
    typedef SharedType type;
};

template <>
struct TypeOf<Tag__::namelist>
{
    typedef std::deque<QString> type;
};

template <>
struct TypeOf<Tag__::tab>
{
    typedef std::shared_ptr<Table> type;
};

template <>
struct TypeOf<Tag__::num>
{
    typedef int type;
};

template <>
struct TypeOf<Tag__::rtlist>
{
    typedef SharedRTL type;
};

template <>
struct TypeOf<Tag__::regtransfer>
{
    typedef Statement * type;
};

template <>
struct TypeOf<Tag__::exp>
{
    typedef SharedExp type;
};

template <>
struct TypeOf<Tag__::str>
{
    typedef QString type;
};

template <>
struct TypeOf<Tag__::insel>
{
    typedef std::shared_ptr<InsNameElem> type;
};

template <>
struct TypeOf<Tag__::explist>
{
    typedef std::deque<SharedExp> type;
};

template <>
struct TypeOf<Tag__::strlist>
{
    typedef std::list<QString> type;
};

template <>
struct TypeOf<Tag__::sizeTy>
{
    typedef std::shared_ptr<SizeType> type;
};

template <>
struct TypeOf<Tag__::opTable>
{
    typedef std::shared_ptr<OpTable> type;
};

template <>
struct TypeOf<Tag__::expTable>
{
    typedef std::shared_ptr<ExprTable> type;
};

template <>
struct TypeOf<Tag__::floatTy>
{
    typedef std::shared_ptr<FloatType> type;
};

template <>
struct TypeOf<Tag__::aConst>
{
    typedef std::shared_ptr<Const> type;
};

template <>
struct TypeOf<Tag__::tern>
{
    typedef std::shared_ptr<Ternary> type;
};

template <>
struct TypeOf<Tag__::asgn>
{
    typedef std::shared_ptr<Assign> type;
};


    // Individual semantic value classes are derived from Base, offering a
    // member returning the value's Tag__, a member cloning the object of its
    // derived Semantic<Tag__> and a member returning a pointerr to its
    // derived Semantic<Tag__> data. See also Bisonc++'s distribution file
    // README.polymorphic-techical
class Base
{
    protected:
        Tag__ d_baseTag;        // d_baseTag is assigned by Semantic.

    public:
        Base() = default;
        Base(Base const &other) = delete;

        virtual ~Base();

        Tag__ tag() const;
        Base *clone() const;
        void *data() const;        

    private:
        virtual Base *vClone() const = 0;
        virtual void *vData() const = 0;
};

inline Base *Base::clone() const
{
    return vClone();
}

inline void *Base::data() const
{
    return vData();
}

inline Tag__ Base::tag() const
{
    return d_baseTag;
}

    // The class Semantic stores a semantic value of the type matching tg_
template <Tag__ tg_>
class Semantic: public Base
{
    typename TypeOf<tg_>::type d_data;
    
    public:
        Semantic();
        Semantic(Semantic<tg_> const &other);   // req'd for cloning

            // This constructor member template forwards its arguments to
            // d_data, allowing it to be initialized using whatever
            // constructor is available for DataType
        template <typename ...Params>
        Semantic(Params &&...params);

    private:
        Base *vClone() const override;
        void *vData() const override;
};

template <Tag__ tg_>
Semantic<tg_>::Semantic()
{
    d_baseTag = tg_;                // Base's data member:
}

template <Tag__ tg_>
Semantic<tg_>::Semantic(Semantic<tg_> const &other)
:
    d_data(other.d_data)
{
    d_baseTag = other.d_baseTag;
}

template <Tag__ tg_>
template <typename ...Params>
Semantic<tg_>::Semantic(Params &&...params)
:
    d_data(std::forward<Params>(params) ...)
{
    d_baseTag = tg_;
}


template <Tag__ tg_>
Base *Semantic<tg_>::vClone() const
{
    return new Semantic<tg_>{*this};
}

template <Tag__ tg_>
void *Semantic<tg_>::vData() const 
{
    return const_cast<typename TypeOf<tg_>::type *>(&d_data);
}


    // The class SType wraps a pointer to Base.  It becomes the polymorphic
    // STYPE__ type. It also defines get members, allowing constructions like
    // $$.get<INT> to be used.  
class SType: private std::unique_ptr<Base>
{
    typedef std::unique_ptr<Base> BasePtr;

    public:
        SType() = default;
        SType(SType const &other);
        SType(SType &&tmp);

        ~SType() = default;

            // Specific overloads are needed for SType = SType assignments
        SType &operator=(SType const &rhs);
        SType &operator=(SType &rhs);           // required so it is used
                                                // instead of the template op=
        SType &operator=(SType &&tmp);

            // A template member operator= can be used when the compiler is
            // able to deduce the appropriate typename. Otherwise use assign.
        template <typename Type>
        SType &operator=(Type const &value);

        template <typename Type>                // same, now moving
        SType &operator=(Type &&tmp);

        template <Tag__ tag, typename ...Args>
        void assign(Args &&...args);
    
            // By default the get()-members check whether the specified <tag>
            // matches the tag returned by SType::tag (d_data's tag). If they
            // don't match a run-time fatal error results.
        template <Tag__ tag>
        typename TypeOf<tag>::type &get();

        template <Tag__ tag>
        typename TypeOf<tag>::type const &get() const;

        Tag__ tag() const;
        bool valid() const;
};

inline SType::SType(SType const &other)
:
    BasePtr{other ? other->clone() : 0}
{}

inline SType::SType(SType &&tmp)
:
    BasePtr{std::move(tmp)}
{}

inline SType &SType::operator=(SType const &rhs)
{
    reset(rhs->clone());
    return *this;
}

inline SType &SType::operator=(SType &rhs)
{
    reset(rhs->clone());
    return *this;
}

inline SType &SType::operator=(SType &&tmp)
{
    BasePtr::operator=(std::move(tmp));
    return *this;
}

    // A template assignment function can be used when the compiler is 
    // able to deduce the appropriate typename
template <typename Type>
inline SType &SType::operator=(Type const &value)
{
    assign< TagOf<Type>::tag >(value);
    return *this;
}

template <typename Type>
inline SType &SType::operator=(Type &&tmp)
{
    assign< 
        TagOf<
            typename std::remove_reference<Type>::type
        >::tag 
    >(std::move(tmp));

    return *this;
}

template <Tag__ tag, typename ...Args>
void SType::assign(Args &&...args)
{
    reset(new Semantic<tag>(std::forward<Args>(args) ...));
}

template <Tag__ tg>
typename TypeOf<tg>::type &SType::get()
{
// $insert warnTagMismatches

    if (tag() != tg)
    {
        if (*t_nErrors != 0)
            const_cast<SType *>(this)->assign<tg>();
        else
        {
            std::cerr << "[Fatal] calling `.get<Tag__::" << 
                idOfTag__[static_cast<int>(tg)] << 
                ">()', but Tag " <<
                idOfTag__[static_cast<int>(tag())] << " is encountered. Try "
                "option --debug and call setDebug(Parser::ACTIONCASES)\n";
            throw 1;        // ABORTs
        }
    }

    return *static_cast<typename TypeOf<tg>::type *>( (*this)->data() );
}

template <Tag__ tg>
typename TypeOf<tg>::type const &SType::get() const
{
// $insert warnTagMismatches

    if (tag() != tg)
    {
        if (*t_nErrors != 0)
            const_cast<SType *>(this)->assign<tg>();
        else
        {
            std::cerr << "[Fatal] calling `.get<Tag__::" << 
                idOfTag__[static_cast<int>(tg)] << 
                ">()', but Tag " <<
                idOfTag__[static_cast<int>(tag())] << " is encountered. Try "
                "option --debug and call setDebug(Parser::ACTIONCASES)\n";
            throw 1;        // ABORTs
        }
    }

    return *static_cast<typename TypeOf<tg>::type *>( (*this)->data() );
}

inline Tag__ SType::tag() const
{
    return valid() ? (*this)->tag() : static_cast<Tag__>(sizeofTag__);
}

inline bool SType::valid() const
{
    return BasePtr::get() != 0;
}

}  // namespace Meta__

class SSLParserBase
{
    public:
        enum DebugMode__
        {
            OFF           = 0,
            ON            = 1 << 0,
            ACTIONCASES   = 1 << 1
        };

// $insert tokens

    // Symbolic tokens:
    enum Tokens__
    {
        KW_INTEGER = 257,
        KW_FLOAT,
        KW_ENDIANNESS,
        KW_BIG,
        KW_LITTLE,
        KW_OPERAND,
        KW_COVERS,
        KW_SHARES,
        KW_FAST,
        KW_FETCHEXEC,
        KW_FPOP,
        KW_FPUSH,
        IDENTIFIER,
        REG_ID,
        NUM,
        FLOAT_NUM,
        ASSIGNTYPE,
        REG_NUM,
        DECOR,
        TEMP,
        CONV_FUNC,
        TRUNC_FUNC,
        TRANSCEND,
        FABS_FUNC,
        NAME_CALL,
        NAME_LOOKUP,
        FLAGMACRO,
        SUCCESSOR,
        ADDR,
        INDEX,
        FNEG,
        THEN,
        TO,
        COLON,
        REG_IDX,
        ASSIGN,
        MEM_IDX,
        LOG_OP,
        COND_OP,
        BIT_OP,
        ARITH_OP,
        FARITH_OP,
        NOT,
        LNOT,
        CAST_OP,
        LOOKUP_RDC,
        S_E,
        AT,
    };

// $insert STYPE
    typedef Meta__::SType STYPE__;


    private:
                        // state  semval
        typedef std::pair<size_t, STYPE__> StatePair;
                       // token   semval
        typedef std::pair<int,    STYPE__> TokenPair;

        int d_stackIdx = -1;
        std::vector<StatePair> d_stateStack;
        StatePair  *d_vsp = 0;       // points to the topmost value stack
        size_t      d_state = 0;

        TokenPair   d_next;
        int         d_token;

        bool        d_terminalToken = false;
        bool        d_recovery = false;


    protected:
        enum Return__
        {
            PARSE_ACCEPT__ = 0,   // values used as parse()'s return values
            PARSE_ABORT__  = 1
        };
        enum ErrorRecovery__
        {
            UNEXPECTED_TOKEN__,
        };

        bool        d_actionCases__ = false;    // set by options/directives
        bool        d_debug__ = true;
        size_t      d_requiredTokens__;
        size_t      d_nErrors__;                // initialized by clearin()
        size_t      d_acceptedTokens__;
        STYPE__     d_val__;


        SSLParserBase();

        void ABORT() const;
        void ACCEPT() const;
        void ERROR() const;

        STYPE__ &vs__(int idx);             // value stack element idx 
        int  lookup__() const;
        int  savedToken__() const;
        int  token__() const;
        size_t stackSize__() const;
        size_t state__() const;
        size_t top__() const;
        void clearin__();
        void errorVerbose__();
        void lex__(int token);
        void popToken__();
        void pop__(size_t count = 1);
        void pushToken__(int token);
        void push__(size_t nextState);
        void redoToken__();
        bool recovery__() const;
        void reduce__(int rule);
        void shift__(int state);
        void startRecovery__();

    public:
        void setDebug(bool mode);
        void setDebug(DebugMode__ mode);
}; 

// hdr/abort
inline void SSLParserBase::ABORT() const
{
    throw PARSE_ABORT__;
}

// hdr/accept
inline void SSLParserBase::ACCEPT() const
{
    throw PARSE_ACCEPT__;
}


// hdr/error
inline void SSLParserBase::ERROR() const
{
    throw UNEXPECTED_TOKEN__;
}

// hdr/savedtoken
inline int SSLParserBase::savedToken__() const
{
    return d_next.first;
}

// hdr/opbitand
inline SSLParserBase::DebugMode__ operator&(SSLParserBase::DebugMode__ lhs,
                                     SSLParserBase::DebugMode__ rhs)
{
    return static_cast<SSLParserBase::DebugMode__>(
            static_cast<int>(lhs) & rhs);
}

// hdr/opbitor
inline SSLParserBase::DebugMode__ operator|(SSLParserBase::DebugMode__ lhs, 
                                     SSLParserBase::DebugMode__ rhs)
{
    return static_cast<SSLParserBase::DebugMode__>(static_cast<int>(lhs) | rhs);
};

// hdr/recovery
inline bool SSLParserBase::recovery__() const
{
    return d_recovery;
}

// hdr/stacksize
inline size_t SSLParserBase::stackSize__() const
{
    return d_stackIdx + 1;
}

// hdr/state
inline size_t SSLParserBase::state__() const
{
    return d_state;
}

// hdr/token
inline int SSLParserBase::token__() const
{
    return d_token;
}

// hdr/vs
inline SSLParserBase::STYPE__ &SSLParserBase::vs__(int idx) 
{
    return (d_vsp + idx)->second;
}

// hdr/tail
// For convenience, when including ParserBase.h its symbols are available as
// symbols in the class Parser, too.
#define SSLParser SSLParserBase

// $insert namespace-close
}

#endif



