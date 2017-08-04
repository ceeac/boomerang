#pragma once

#include "boomerang/db/statements/Statement.h"

// Common to BranchStatement and BoolAssign
// Return true if this is now a floating point Branch
bool condToRelational(SharedExp& pCond, BranchType jtCond);