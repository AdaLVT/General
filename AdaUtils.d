module AdaUtils;
/++
Just some neat little utilities for projects, this one for D
++/
import std.variant, std.conv;

// Converts a U -> T function into a U -> Variant version
Variant delegate(U) toVarF(T, U...)(T delegate(U) f) {
	return (U args){
		return f(args).to!Variant;
	};
}
