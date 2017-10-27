#pragma region License
/*
 * This file is part of the Boomerang Decompiler.
 *
 * See the file "LICENSE.TERMS" for information on usage and
 * redistribution of this file, and for a DISCLAIMER OF ALL
 * WARRANTIES.
 */
#pragma endregion License
#pragma once


#include "boomerang/db/statements/GotoStatement.h"


class CaseStatement : public GotoStatement
{
public:
    CaseStatement();
    virtual ~CaseStatement() override;

    /// \copydoc GotoStatement::clone
    virtual Statement *clone() const override;

    /// \copydoc GotoStatement::accept
    virtual bool accept(StmtVisitor *visitor) override;

    /// \copydoc GotoStatement::accept
    virtual bool accept(StmtExpVisitor *visitor) override;

    /// \copydoc GotoStatement::accept
    virtual bool accept(StmtModifier *modifier) override;

    /// \copydoc GotoStatement::accept
    virtual bool accept(StmtPartModifier *modifier) override;

    /// \copydoc GotoStatement::print
    virtual void print(QTextStream& os, bool html = false) const override;

    /// \copydoc GotoStatement::searchAndReplace
    virtual bool searchAndReplace(const Exp& search, SharedExp replace, bool cc = false) override;

    /// \copydoc GotoStatement::searchAll
    virtual bool searchAll(const Exp& search, std::list<SharedExp>& result) const override;

    /// \copydoc GotoStatement::generateCode
    virtual void generateCode(ICodeGenerator *generator, const BasicBlock *parentBB) override;

    /// \copydoc GotoStatement::usesExp
    virtual bool usesExp(const Exp& e) const override;

    /// \copydoc GotoStatement::simplify
    virtual void simplify() override;

    /// Get information about this switch statement
    SwitchInfo *getSwitchInfo();

    void setSwitchInfo(SwitchInfo *psi);

private:
    SwitchInfo *m_switchInfo; ///< Ptr to struct with information about the switch
};
