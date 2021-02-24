//Project Verify

import std.variant;
import std.stdio;

/++
Plans for a theorem verifier written in D, which outputs "me-readable" notation.
Reference proof:

wffDN:
[[x @ 1]] |- [[~~x
: wffNot [[~x
: wffNot [[x : 1]]
]]
]]


++/

alias Justification = Algebraic!(void, Proof[]);

/++ an alias for possible justifications:
Either a proof step in itself (Proof) [with reference
numbers being added by the verifier]
or void for an assertion without proof ++/

enum ProofType { WFF, Assumption, Set, Class }

/+ [[ WFF ]]: formulas with a true or false value.
(( Assumption )): something that is true.
{{ Set }}: Some parameter that is a set
<< Class >>: Some parameter that is a class
+/

interface Exp {
	public bool isAtomic();
	public bool isNegation();
	public bool isImplication(); 
}

/++An interface to implement the `isX()` features of Expression.++/

abstract class Expression: Exp {
	private string representation;
	private Expression[] arguments;

	public string getRepresentation() {
		return this.representation;
	}
	
	public Expression[] getArguments() {
		return this.arguments;
	}

}
/+ And abstract class that the individual expression types inherit from +/

class Atomic: Expression {
	public bool isAtomic() { return true; }
	public bool isNegation() { return false;}
	public bool isImplication() { return false; }
	this(string rep) {
		this.representation = rep;
		this.arguments = [];
	}
}
Atomic atom(string arg) {
	return new Atomic(arg);
}

/+ The class that is stuff like "x" "phi" "\varnothing" etc. +/

class Negation: Expression {
	public bool isAtomic() { return false; }
	public bool isNegation() { return true;}
	public bool isImplication() { return false; }
	this(Expression arg) {
		if(arg.isAtomic || arg.isNegation)
			this.representation = "\\lnot" ~ arg.representation;
		else
			this.representation = "\\lnot(" ~ arg.representation ~ ")";
		this.arguments = [arg];
	}
}
Negation not(Expression arg) {
	return new Negation(arg);
}
/+ Logical negation +/

class Implication: Expression {
	public bool isAtomic() { return false; }
	public bool isNegation() { return false;}
	public bool isImplication() { return true; }
	this(Expression lhs, Expression rhs) {
		string lhsP, rhsP;
		if(lhs.isAtomic || lhs.isNegation)
			lhsP = lhs.representation;
		else
			lhsP = "(" ~ lhs.representation ~ ")";
		if(rhs.isAtomic || rhs.isNegation)
			rhsP = rhs.representation;
		else
			rhsP = "(" ~ rhs.representation ~ ")";
		this.representation = lhsP ~ "\\Leftrightarrow " ~ rhsP;
		this.arguments = [lhs, rhs];
	}
}
Implication implies(Expression lhs, Expression rhs) {
	return new Implication(lhs, rhs);
}

/+ Logical implication +/


		

/++ Expression is the >internal< representation of expressions, 
with `.representation` being the human-readable form ++/

class Proof {
	/++ In the above example, this would be: wffDN 
	the internal representation when using a proof ++/
	private string name;
	public string getName() {
		return this.name;
	}	

	private ProofType proofType;
	public bool isWFF() {
		return this.proofType == ProofType.WFF;
	}
	public bool isAssumption() {
		return this.proofType == ProofType.Assumption;
	}
	public bool isSet() {
		return this.proofType == ProofType.Set;
	}
	public bool isClass() {
		return this.proofType == ProofType.Class;
	}
	/++ In the above example, this would be ProofType.WFF ++/
	
	private Expression expression;
	public Expression getExpression() {
		return this.expression;
	}
	/++ This would be something like Not(Not(x)),
	an internal representation of ~~x ++/

	private Justification justification;
	public bool isAxiom() {
		return this.justification.peek!(void) !is null;
	}
	public Proof[] getProof() {
		return *this.justification.peek!(Proof[]);
	}
	
	/++ The justification for the step, so
	this would be `wffNot(wffNot(x))`,
	with a type signature of Proof wffNot(Proof x)++/

	this(string name, ProofType proofType, Expression expression) {
		this.name = name;
		this.proofType = proofType;
		this.expression = expression;
	}
	/+ For statements without proof: axioms +/

	this(string name, ProofType proofType, Expression expression, Proof[] justification) {
		this.name = name;
		this.proofType = proofType;
		this.expression = expression;
		this.justification = justification;
	}

	public string getRepresentation() {
		string res = this.expression.getRepresentation();
		if(this.justification.peek!(void) !is null) { //TODO: make axiom be []. 
			assert(true);
		} else {
			res ~= " \\\\\n\\because " ~ this.getName();
			foreach(j; *this.justification.peek!(Proof[])) {
				res ~=  j.getRepresentation();
			}
		}
		if(this.isWFF()) {
			return "\\lBrack " ~ res ~ " \\rBrack";
		} else if(this.isAssumption()) {
			return "\\lParen " ~ res ~ " \\rParen";
		} else if(this.isSet()) {
			return "\\lBrace " ~ res ~ " \\rBrace";
		} else {
			return "\\lAngle " ~ res ~ " \\rAngle";
		}
	}
}

Proof wffFalse() {
	return new Proof("wffFalse", ProofType.WFF, atom("0"));
}

Proof wffNot(Proof x) {
	assert(x.isWFF(), "Error: Argument to wffNot not a WFF!");
	return new Proof("wffNot", ProofType.WFF, not(x.getExpression()), [x]);
}

Proof wffImplies(Proof x, Proof y) {
	assert(x.isWFF(), "Error: Left argument to wffImplies not a WFF!");
	assert(y.isWFF(), "Error: Right argument to wffImplies not a WFF!");
	return new Proof("wffImplies", ProofType.WFF, implies(x.getExpression(), y.getExpression()), [x, y]);
}

Proof axMp(Proof wffPhi, Proof assPhi, Proof wffPsi, Proof assImp) {
	assert(wffPhi.isWFF(), "Error: major validity argument to axMp not a WFF!");
	assert(assPhi.isAssumption(), "Error: major assumption argument to axMp not an assumption!");
	assert(wffPhi.getExpression().getRepresentation() == assPhi.getExpression().getRepresentation(), "Error: major validity and assumption mismatch in axMp!");
	assert(wffPsi.isWFF(), "Error: minor validity argument to axMp not a WFF!");
	assert(assImp.isAssumption(), "Error: minor assumption argument to axMp not an assumption!");
	assert(assImp.getExpression().getRepresentation() == wffPhi.getExpression().implies(wffPsi.getExpression()).getRepresentation(), "Error: minor assumption and implication of phi => psi mismatch in axMp!");
	return new Proof("axMp", ProofType.Assumption, wffPhi.getExpression().implies(wffPsi.getExpression()), [wffPhi, assPhi, wffPsi, assImp]);
}	
a
void main() {
	auto f = wffFalse();
	auto g = new Proof("testAss", ProofType.Assumption, f.getExpression());
	auto h = new Proof("testImp", ProofType.Assumption, f.getExpression().implies(f.getExpression()));
	auto p = axMp(f, g, f, h);
	writeln(p.getRepresentation());
}
