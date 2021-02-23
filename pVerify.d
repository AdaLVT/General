//Project Verify

import std.variant;

/++
Plans for a theorem verifier written in D, which outputs me-readable notation
Beep boop my proofs are symbol hell.

Reference proof:

wffDN[[x @ 1]] |- [[~~x
: wffNot [[~x
: wffNot [[x : 1]]
]]
]]


++/

alias Justification = Algebraic!(void, Proof);

/++ an alias for possible justifications, 
or a proof step in itself (Proof) [with reference
numbers being added by the verifier]
or void for an assertion without proof ++/

enum ProofType { WFF, Assumption, Set, Class }

class Expression {} //Will sketch out later
/++ Internal representation of expressions, so something like:
Implies(Implies(Not(x), Not(y)), Implies(y, x)) ++/

class Proof {
	private string representation;
	/++ In the above example, this would be: [[ ~~x v wffDN[[x]] ]] ++/
	
	private ProofType proofType;
	/++ In the above example, this would be ProofType.WFF ++/

	private Expression expression;
	/++ This would be something like Not(Not(x)),
	an internal representation of ~~x ++/

	private Justification justification;
	/++ The justification for the step, so
	this would be `wffNot(wffNot(x))`,
	with a type signature of Proof wffNot(Proof x)++/
}
	
void main() {}
