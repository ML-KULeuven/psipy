import std.math;
import std.stdio;
import std.typecons;
import std.conv;
import std.datetime;

import pyd.pyd;


import dparse;
import dexpr;
import distrib;
import integration;
import options;



auto parse(string integrant){
	return integrant.dParse.simplify(one);
}


auto toText(dexpr.DExpr a){
	return text(a);
}
auto toSympyString(dexpr.DExpr a){
	return a.toString(Format.sympy);
}
auto toString(dexpr.DExpr a){
	return a.toString();
}


auto simplify(dexpr.DExpr a){
	return a.simplify(one);
}



auto linearizeConstraints(string[] variables, dexpr.DExpr expression){
	expression = expression.simplify(one);
	foreach (i; 0 ..variables.length){
		expression = dexpr.linearizeConstraints(expression, variables[i].dVar);
	}
	return expression;
}





auto less(dexpr.DExpr lhs, dexpr.DExpr rhs){
	return dexpr.dIvr(DIvr.Type.lZ, lhs-rhs);
}

auto less_equal(dexpr.DExpr lhs, dexpr.DExpr rhs){
	return dexpr.dIvr(DIvr.Type.leZ, lhs-rhs);
}

auto greater(dexpr.DExpr lhs, dexpr.DExpr rhs){
	return dexpr.dIvr(DIvr.Type.lZ, rhs-lhs);
}

auto greater_equal(dexpr.DExpr lhs, dexpr.DExpr rhs){
	return dexpr.dIvr(DIvr.Type.leZ, rhs-lhs);
}

auto equal(dexpr.DExpr lhs, dexpr.DExpr rhs){
	return dexpr.dIvr(DIvr.Type.eqZ, rhs-lhs);
}

auto not_equal(dexpr.DExpr lhs, dexpr.DExpr rhs){
	return dexpr.dIvr(DIvr.Type.neqZ, rhs-lhs);
}


auto negate_ivr(DIvr iv){
	return dexpr.negateDIvr(iv);
}


auto mul(dexpr.DExpr a, dexpr.DExpr b){
	return (a*b).simplify(one);
}
auto add(dexpr.DExpr a, dexpr.DExpr b){
	return (a+b).simplify(one);
}
auto sub(dexpr.DExpr a, dexpr.DExpr b){
	return (a-b).simplify(one);
}
auto div(dexpr.DExpr a, dexpr.DExpr b){
	return (a/b).simplify(one);
}
auto pow(dexpr.DExpr a, dexpr.DExpr b){
	return (a^^b).simplify(one);
}
auto exp(dexpr.DExpr a){
	dexpr.DExpr E;
	E = "e".dParse;
	return (E^^a).simplify(one);
}
auto sig(dexpr.DExpr x){
	dexpr.DExpr E;
	E = "e".dParse;
	return (1/(1+E^^(-x))).simplify(one);
}




auto delta_pdf(string var, dexpr.DExpr root){
	auto v = dVar(var);
	return dDelta(v-root).simplify(one);
}
auto normal_pdf(string var, dexpr.DExpr mu, dexpr.DExpr sigma){
	auto v = dVar(var);
	return (gaussPDF(v, mu, sigma)).simplify(one);
}
auto beta_pdf(string var, dexpr.DExpr alpha, dexpr.DExpr beta){
	auto v = dVar(var);
	return (betaPDF(v, alpha, beta)).simplify(one);
}
auto poisson_pdf(string var, dexpr.DExpr n){
	auto v = dVar(var);
	return (poissonPDF(v, n)).simplify(one);
}

auto integrate(string[] variables, dexpr.DExpr integrand){
	auto integral = integrand.simplify(one);
	foreach (i; 0 ..variables.length){
		integral = dInt(variables[i].dVar, integral);
	}
	return integral.simplify(one);
}





extern(C) void PydMain() {
    def!(parse)();
    def!(toString)();
    def!(toSympyString)();
    def!(simplify)();
		def!(toText)();

		def!(linearizeConstraints)();

		def!(less)();
		def!(less_equal)();
		def!(greater)();
		def!(greater_equal)();
		def!(equal)();
		def!(not_equal)();

		def!(negate_ivr)();

    def!(add)();
    def!(sub)();
    def!(mul)();
    def!(div)();
    def!(pow)();
    def!(exp)();
    def!(sig)();

		def!(delta_pdf)();
		def!(normal_pdf)();
		def!(beta_pdf)();
		def!(poisson_pdf)();

		def!(integrate)();

    module_init();

		wrap_class!(
			DExpr,
			Repr!(DExpr.toString)
		)();
}
