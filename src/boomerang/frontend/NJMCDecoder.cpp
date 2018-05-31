#pragma region License
/*
 * This file is part of the Boomerang Decompiler.
 *
 * See the file "LICENSE.TERMS" for information on usage and
 * redistribution of this file, and for a DISCLAIMER OF ALL
 * WARRANTIES.
 */
#pragma endregion License


#include "NJMCDecoder.h"

#include "boomerang/core/Boomerang.h"
#include "boomerang/util/Log.h"
#include "boomerang/util/Util.h"

#include "boomerang/db/RTL.h"
#include "boomerang/db/Register.h"
#include "boomerang/db/CFG.h"
#include "boomerang/db/proc/Proc.h"
#include "boomerang/db/Prog.h"
#include "boomerang/db/statements/Assignment.h"
#include "boomerang/db/statements/Assign.h"
#include "boomerang/db/statements/CallStatement.h"
#include "boomerang/db/exp/Exp.h"
#include "boomerang/db/exp/Location.h"

#include <cassert>
#include <cstdarg> // For varargs
#include <cstring>


NJMCDecoder::NJMCDecoder(Prog *prog)
    : m_prog(prog)
{
}


std::unique_ptr<RTL> NJMCDecoder::instantiate(Address pc, const char *name, const std::initializer_list<SharedExp>& args)
{
    // Get the signature of the instruction and extract its parts
    std::pair<QString, unsigned> sig = m_rtlDict.getSignature(name);
    QString      opcode      = sig.first;
    unsigned int numOperands = sig.second;

    if (numOperands != args.size()) {
        QString msg = QString("Disassembled instruction '%1' has %2 arguments, "
            "but the instruction has %3 parameters in the RTL dictionary")
            .arg(name).arg(args.size()).arg(numOperands);
        throw std::invalid_argument(msg.toStdString());
    }

    // Put the operands into a vector
    std::vector<SharedExp> actuals(args);

    if (DEBUG_DECODER) {
        QTextStream q_cout(stdout);
        // Display a disassembly of this instruction if requested
        q_cout << pc << ": " << name << " ";

        for (const SharedExp& itd : actuals) {
            if (itd->isIntConst()) {
                int val = itd->access<Const>()->getInt();

                if ((val > 100) || (val < -100)) {
                    q_cout << "0x" << QString::number(val, 16);
                }
                else {
                    q_cout << val;
                }
            }
            else {
                itd->print(q_cout);
            }
        }

        q_cout << '\n';
    }

    return m_rtlDict.instantiateRTL(opcode, pc, actuals);
}


SharedExp NJMCDecoder::instantiateNamedParam(char *name, const std::initializer_list<SharedExp>& args)
{
    if (m_rtlDict.ParamSet.find(name) == m_rtlDict.ParamSet.end()) {
        LOG_MSG("No entry for named parameter '%1'", name);
        return nullptr;
    }

    assert(m_rtlDict.DetParamMap.find(name) != m_rtlDict.DetParamMap.end());
    ParamEntry& ent = m_rtlDict.DetParamMap[name];

    if ((ent.m_kind != PARAM_ASGN) && (ent.m_kind != PARAM_LAMBDA)) {
        LOG_MSG("Attempt to instantiate expressionless parameter '%1'", name);
        return nullptr;
    }

    // Start with the RHS
    assert(ent.m_asgn->isAssign());
    std::shared_ptr<Assign> assign = std::static_pointer_cast<Assign>(ent.m_asgn);

    SharedExp result   = assign->getRight() ? assign->getRight()->clone() : nullptr;
    auto      arg_iter = args.begin();

    if (result) {
        for (auto& elem : ent.m_params) {
            Location  formal(opParam, Const::get(elem), nullptr);
            SharedExp actual = *arg_iter++;
            bool      change;
            result = result->searchReplaceAll(formal, actual, change);
        }
    }

    return result;
}


void NJMCDecoder::substituteCallArgs(char *name, SharedExp *exp, const std::initializer_list<SharedExp>& args)
{
    if (m_rtlDict.ParamSet.find(name) == m_rtlDict.ParamSet.end()) {
        LOG_VERBOSE("No entry for named parameter '%1'", name);
        return;
    }

    ParamEntry& ent      = m_rtlDict.DetParamMap[name];
    auto        arg_iter = args.begin();

    for (auto& elem : ent.m_funcParams) {
        Location  formal(opParam, Const::get(elem), nullptr);
        SharedExp actual = *arg_iter++;
        bool      change;
        *exp = (*exp)->searchReplaceAll(formal, actual, change);
    }
}


SharedExp NJMCDecoder::dis_Reg(int regNum)
{
    return Location::regOf(regNum);
}


SharedExp NJMCDecoder::dis_Num(unsigned num)
{
    return Const::get(num); // TODO: what about signed values ?
}


void NJMCDecoder::processUnconditionalJump(const char *name, int size, HostAddress relocd, ptrdiff_t delta, Address pc,
                                           DecodeResult& result)
{
    result.numBytes = size;
    GotoStatement *jump = new GotoStatement();
    jump->setDest(Address((relocd - delta).value()));
    result.rtl->append(jump);
    SHOW_ASM(name << " " << relocd - delta)
}


void NJMCDecoder::processComputedJump(const char *name, int size, SharedExp dest, Address pc, DecodeResult& result)
{
    result.numBytes = size;

    GotoStatement *jump = new GotoStatement();
    jump->setDest(dest);
    jump->setIsComputed(true);
    result.rtl->append(jump);

    SHOW_ASM(name << " " << dest)
}


void NJMCDecoder::processComputedCall(const char *name, int size, SharedExp dest, Address pc, DecodeResult& result)
{
    result.numBytes = size;

    CallStatement *call = new CallStatement();
    call->setDest(dest);
    call->setIsComputed(true);
    result.rtl->append(call);

    SHOW_ASM(name << " " << dest)
}


QString NJMCDecoder::getRegName(int idx) const
{
    for (const std::pair<QString, int>& elem : m_rtlDict.RegMap) {
        if (elem.second == idx) {
            return elem.first;
        }
    }

    return QString("");
}


int NJMCDecoder::getRegSize(int idx) const
{
    auto iter = m_rtlDict.DetRegMap.find(idx);

    if (iter == m_rtlDict.DetRegMap.end()) {
        return 32;
    }

    return iter->second.getSize();
}


int NJMCDecoder::getRegIdx(const QString& name) const
{
    auto iter = m_rtlDict.RegMap.find(name);

    if (iter == m_rtlDict.RegMap.end()) {
        assert(!"Failed to find named register");
        return -1;
    }

    return iter->second;
}
