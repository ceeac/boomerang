#pragma region License
/*
 * This file is part of the Boomerang Decompiler.
 *
 * See the file "LICENSE.TERMS" for information on usage and
 * redistribution of this file, and for a DISCLAIMER OF ALL
 * WARRANTIES.
 */
#pragma endregion License
#include "ParserTest.h"


#include "boomerang/core/Boomerang.h"
#include "boomerang/db/ssl/SSLParser.ih"
#include "boomerang/db/statements/Statement.h"
#include "boomerang/util/Log.h"

#include <QDebug>


#define SSL_FILE(path) (Boomerang::get()->getSettings()->getDataDirectory().absoluteFilePath(path))


void ParserTest::initTestCase()
{
    Boomerang::get()->getSettings()->setDataDirectory(BOOMERANG_TEST_BASE "share/boomerang/");
    Boomerang::get()->getSettings()->setPluginDirectory(BOOMERANG_TEST_BASE "lib/boomerang/plugins/");
}


void ParserTest::cleanupTestCase()
{
    Boomerang::destroy();
}


void ParserTest::testRead()
{
    RTLInstDict d;

    QVERIFY(d.readSSLFile(SSL_FILE("ssl/hppa.ssl")));
    QVERIFY(d.readSSLFile(SSL_FILE("ssl/mc68k.ssl")));
    QVERIFY(d.readSSLFile(SSL_FILE("ssl/mips.ssl")));
    QVERIFY(d.readSSLFile(SSL_FILE("ssl/pentium.ssl")));
    QVERIFY(d.readSSLFile(SSL_FILE("ssl/ppc.ssl")));
    QVERIFY(d.readSSLFile(SSL_FILE("ssl/sparc.ssl")));
    QVERIFY(d.readSSLFile(SSL_FILE("ssl/st20.ssl")));
}


void ParserTest::testExp()
{
    QString   s("*i32* r0 := 5 + 6");
    Statement *a = ssl::SSLParser::parseExp(qPrintable(s));

    QVERIFY(a);
    QString     res;
    QTextStream ost(&res);
    a->print(ost);
    QCOMPARE(res, "   0 " + s);
    QString s2 = "*i32* r[0] := 5 + 6";
    a = ssl::SSLParser::parseExp(qPrintable(s2));
    QVERIFY(a);
    res.clear();
    a->print(ost);
    // Still should print to string s, not s2
    QCOMPARE(res, "   0 " + s);
}


QTEST_GUILESS_MAIN(ParserTest)
