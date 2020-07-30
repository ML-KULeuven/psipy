import std.conv;
import std.algorithm;
import std.format;

import options, hashtable, dutil;


import pyd.pyd;

import dparse;
import dexpr;
import distrib;
import integration;




auto S(string symbol){
   return new PsiExpr(symbol.dParse.simplify(one));
}
auto S(int number){
   return new PsiExpr(to!string(number).dParse.simplify(one));
}
auto S(float number){
   return new PsiExpr(to!string(number).dParse.simplify(one));
}
auto S(double number){
   return new PsiExpr(to!string(number).dParse.simplify(one));
}

class PsiExpr{
   dexpr.DExpr _expression;
   this(dexpr.DExpr expression){
      _expression = expression;
   }


   override string toString(){
      return _expression.toString();
   }


   auto is_polynomial(){
      return isPolynomial(_expression);
   }

   auto is_zero(){
      return _expression==zero;
   }
   auto is_one(){
      return _expression==one;
   }
   auto is_iverson(){
      if (auto dummy = cast(DIvr)_expression) return 1;
      else return 0;
   }


   auto simplify(){
      return  new PsiExpr(_expression.simplify(one));
   }

   auto opBinary(string op)(PsiExpr rhs) if(op == "+"){
      return new PsiExpr(_expression + rhs._expression);
   }
   auto opBinary(string op)(PsiExpr rhs) if(op == "-"){
      return new PsiExpr(_expression - rhs._expression);
   }
   auto opBinary(string op)(PsiExpr rhs) if(op == "*"){
      return new PsiExpr(_expression * rhs._expression);
   }
   auto opBinary(string op)(PsiExpr rhs) if(op == "/"){
      return new PsiExpr(_expression / rhs._expression);
   }
   auto opBinary(string op)(PsiExpr rhs) if(op == "^^"){
      return new PsiExpr(_expression ^^ rhs._expression);
   }


   auto eq(PsiExpr rhs){
      return new PsiExpr(dexpr.dIvr(DIvr.Type.eqZ, rhs._expression-_expression).simplify(one));
   }
   auto ne(PsiExpr rhs){
      return new PsiExpr(dexpr.dIvr(DIvr.Type.neqZ, rhs._expression-_expression).simplify(one));
   }


   auto lt(PsiExpr rhs) {
      return new PsiExpr(dexpr.dIvr(DIvr.Type.lZ, _expression-rhs._expression).simplify(one));
   }

   auto le(PsiExpr rhs){
      return new PsiExpr(dexpr.dIvr(DIvr.Type.leZ, _expression-rhs._expression).simplify(one));
   }

   auto gt(PsiExpr rhs){
      return new PsiExpr(dexpr.dIvr(DIvr.Type.lZ, rhs._expression-_expression).simplify(one));
   }

   auto ge(PsiExpr rhs){
      return new PsiExpr(dexpr.dIvr(DIvr.Type.leZ, rhs._expression-_expression).simplify(one));
   }


   auto negate(){
      if (auto iv = cast(DIvr)_expression) {
         return new PsiExpr(dexpr.negateDIvr(iv));
      }
      else{
         auto s = format!"You can only negate Iverson brackets, %s is not a (pure) Iverson bracket"(_expression);
         throw new TypeError(s);
      }
   }


   auto filter_open_iverson(){
      auto result = _filter_open_iverson(_expression);
      return new PsiExpr(result);
   }

   dexpr.DExpr _filter_open_iverson(dexpr.DExpr expression){
      if(auto dsum=cast(DPlus)expression){
         auto result = zero;
         foreach(s;dsum.summands()){
            result = result+_filter_open_iverson(s);
         }
         return result;
      }
      else if(auto dmult=cast(DMult)expression){
         auto result = one;
         foreach(f;dmult.factors()){
            result = result*_filter_open_iverson(f);
         }
         return result;
      }
      else if(auto iv=cast(DIvr)expression){
         if (iv.type==DIvr.Type.neqZ){
            return one;
         }
         if (iv.type==DIvr.Type.eqZ){
            return zero;
         }
         else{
            return expression;
         }
      }
      else{
         return expression;
      }
   }

}





class TypeError : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class PsiPolynomial{
   PsiExpr _polynomial;
   this(PsiExpr expression,bool unsafe_init=false){
      if (unsafe_init) {
         _polynomial = expression;
      }
      else if (expression.is_polynomial) {
         _polynomial = expression;
      }
      else{
         auto s = format!"You're intialization expression (%s) is not a polynomial"(expression);
         throw new TypeError(s);
      }
   }

   auto simplify(){
      auto expression = _polynomial.simplify();
      return  new PsiPolynomial(expression , true);
   }

   auto to_PsiExpr(){
      return new PsiExpr(_polynomial._expression);
   }


   auto opBinary(string op)(PsiPolynomial rhs) if(op == "+"){
      return new PsiPolynomial(_polynomial + rhs._polynomial);
   }
   auto opBinary(string op)(PsiPolynomial rhs) if(op == "-"){
      return new PsiPolynomial(_polynomial - rhs._polynomial);
   }
   auto opBinary(string op)(PsiPolynomial rhs) if(op == "*"){
      return new PsiPolynomial(_polynomial * rhs._polynomial);
   }


   override string toString(){
      return _polynomial.toString();
   }


}





extern(C) void PydMain() {
   def!(S)();

   module_init();
   wrap_class!(
      PsiExpr,
      Init!(dexpr.DExpr),

      Repr!(PsiExpr.toString),

      Property!(PsiExpr.is_zero),
      Property!(PsiExpr.is_one),
      Property!(PsiExpr.is_iverson),

      Def!(PsiExpr.simplify),

      OpBinary!("+"),
      OpBinary!("-"),
      OpBinary!("*"),
      OpBinary!("/"),
      OpBinary!("^^"),

      Def!(PsiExpr.eq),
      Def!(PsiExpr.ne),

      Def!(PsiExpr.lt),
      Def!(PsiExpr.le),
      Def!(PsiExpr.gt),
      Def!(PsiExpr.ge),

      Def!(PsiExpr.negate),

      Def!(PsiExpr.filter_open_iverson),

   )();


   wrap_class!(
      PsiPolynomial,
      Init!(PsiExpr,bool),

      Def!(PsiPolynomial.simplify),
      Def!(PsiPolynomial.to_PsiExpr),

      OpBinary!("+"),
      OpBinary!("-"),
      OpBinary!("*"),

      Repr!(PsiPolynomial.toString),

   )();

}



/* extern(C) void PydMain() {





   def!(integrate)();
   def!(integrate_simple)();
   def!(integrate_poly)();
   def!(filter_iverson)();


   def!(terms)();


   module_init();
   wrap_class!(
      DExpr,
      Repr!(DExpr.toString)
   )(); */






















/* auto integrate(string[] variables, dexpr.DExpr integrand){
   auto integral = integrand;
   foreach (i; 0 ..variables.length){
      integral = integrate_simple(variables[i], integral);
   }
   return integral.simplify(one);
} */


/* auto integrate_simple(string variable, dexpr.DExpr integrand){
   return dInt(variable.dVar, integrand);
}



auto integrate_poly(string[] variables, dexpr.DExpr integrand){
   auto integral = integrand;
   foreach (i; 0 ..variables.length){
      integral = integrate_poly_simple1(variables[i], integral);
   }
   integral = integral.simplify(one);
   return integral;
}


auto integrate_poly_simple1(string variable, dexpr.DExpr integrand){
   auto v = variable.dVar;
   integrand = make_closed_bounds(integrand);
   auto result = dInt(v, integrand);
   return result;
} */



/*

dexpr.DExpr make_closed_bounds(dexpr.DExpr expression){
   if(auto dsum=cast(DPlus)expression){
      auto result = S("0");
      foreach(s;dsum.summands()){
         result = result+make_closed_bounds(s);
      }
      return result;
   }
   else if(auto dmult=cast(DMult)expression){
      auto result = S("1");
      foreach(f;dmult.factors()){
         result = result*make_closed_bounds(f);
      }
      return result;
   }
   else if(auto iv=cast(DIvr)expression){
      if (expression.toString().canFind("≠")){
         return S("1");
      }
      else if (expression.toString().canFind("=")){
         return S("0");
      }
      else{
         return expression;
      }
   }
   else{
      return expression;
   }
} */


/* auto filter_iverson(dexpr.DExpr expression){
   if(isPolynomial(expression)){
      return expression;
   }
   else if(auto iv=cast(DIvr)expression){
      return S("1");
   }
   else if(auto dsum=cast(DPlus)expression){
      auto result = S("0");
      foreach(s;dsum.summands()){
         result = result+filter_iverson(s);
      }
      return result;
   }
   else if(auto dmult=cast(DMult)expression){
      auto result = S("1");
      foreach(f;dmult.factors()){
         result = result*filter_iverson(f);
      }
      return result;
   }
   else{
      return expression;
   }
} */

/+
DExpr[3] splitCommonFactors(DExpr e1,DExpr e2){
		auto common=intersect(e1.factors.setx,e2.factors.setx); // TODO: optimize?
		if(!common.length) return [one,e1,e2];
		auto e1only=e1.factors.setx.setMinus(common);
		auto e2only=e2.factors.setx.setMinus(common);
		return [dMult(common),dMult(e1only),dMult(e2only)];
}


auto integrate_poly_simple2(string variable, dexpr.DExpr integrand){
   auto v = variable.dVar;
   auto polytope_integrals = build_polytop_integrals(integrand,v);
   auto result  = zero;
   /*writeln("");*/
   /*writeln(polytope_integrals.length);*/
   /*writeln(v);*/
   foreach(pi;polytope_integrals){
      /*writeln(pi[0]);
      writeln(pi[1]);*/
      result = result + dInt(v,pi[0]*pi[1]);

      auto common = splitCommonFactors(result,dInt(v,pi[0]*pi[1]));
      /*writeln(common[0]);
      writeln(common[1]);
      writeln(common[2]);*/

      result = common[0]*(common[1]+common[2]);
   }
   writeln(v);
   return result;
}

dexpr.DExpr[][] build_polytop_integrals(dexpr.DExpr expression, DVar v){
   dexpr.DExpr[][] result;

   if(auto iv=cast(DIvr)expression){
      if (iv.toString().canFind("≠")){
         result ~= [S("1"),S("1")];
         return result;
      }
      else if (iv.toString().canFind("=")){
         result ~= [S("0"),S("0")];
         return result;
      }
      else if (iv.hasFreeVar(v)){
         return result ~= [expression,S("1")];
      }
      else {
         return result ~= [S("1"),iv];
      }
   }
   else if(isPolynomial(expression)){
      result ~= [S("1"),expression];
      return result;
   }
   else if(auto dsum=cast(DPlus)expression){
      dexpr.DExpr[][] r;
      foreach(s;dsum.summands()){
         r = build_polytop_integrals(s,v);
         foreach(t;r){
            result ~= t;
         }
      }
      return result;
   }
   else if(auto dmult=cast(DMult)expression){
      dexpr.DExpr[][] r;
      dexpr.DExpr[][] result_help;
      result ~= [S("1"), S("1")];
      foreach(f;dmult.factors()){
         r = build_polytop_integrals(f,v);
         foreach(t1;r){
            foreach(t2;result){
               result_help ~= [(t1[0]*t2[0]).simplify(one), (t1[1]*t2[1]).simplify(one)];
            }
         }
         result = null;
         foreach(t;result_help){
            result ~= [t[0],t[1]];
         }
         result_help = null;

      }
      return result;
   }
   else{
      return result ~= [S("1"), expression];
   }
}





dexpr.DExpr[][] build_polytop_integrals2(dexpr.DExpr expression, DVar v){
   dexpr.DExpr[][] result;


   if(auto iv=cast(DIvr)expression){
      if (iv.toString().canFind("≠")){
         result ~= [S("1"),S("1"),S("1")];
         return result;
      }
      else if (iv.toString().canFind("=")){
         result ~= [S("0"),S("0"),S("0")];
         return result;
      }
      else if (iv.hasFreeVar(v)){
         result ~= [expression,S("1"),S("1")];
         return result;
      }
      else {
         result ~= [S("1"),S("1"),iv];
         return result;
      }
   }
   else if(isPolynomial(expression)){
      if (expression.hasFreeVar(v)){
         result ~= [S("1"),expression.simplify(one),S("1")];
      }
      else{
         result ~= [S("1"),S("1"),expression.simplify(one)];
      }
      return result;
   }
   else if(auto dsum=cast(DPlus)expression){
      dexpr.DExpr[][] r;
      dexpr.DExpr[][] result_help;
      dexpr.DExpr[string] result_bounds_help;
      dexpr.DExpr[string] result_integrand_help;
      dexpr.DExpr[string] result_rest_help;
      string bounds_as_key;

      foreach(s;dsum.summands()){
         r = build_polytop_integrals2(s,v);
         foreach(t;r){
            result ~= t;
         }
      }
      /*result_help = result;
      foreach(t;result_help){
            bounds_as_key = t[0].toString();
            if ((bounds_as_key in result_bounds_help) && (t[2]==result_rest_help[bounds_as_key])) {
               result_integrand_help[bounds_as_key] = result_integrand_help[bounds_as_key]+t[1];

            }
            else{
               result_bounds_help[bounds_as_key] = t[0];
               result_integrand_help[bounds_as_key] = t[1];
               result_rest_help[bounds_as_key] = t[2];
            }
      }*/
      return result;
   }
   else if(auto dmult=cast(DMult)expression){
      dexpr.DExpr[][] r;
      dexpr.DExpr[][] result_help;
      dexpr.DExpr[string] result_bounds_help;
      dexpr.DExpr[string] result_integrand_help;
      dexpr.DExpr[string] result_rest_help;
      string bounds_as_key;

      result ~= [S("1"), S("1"),S("1")];
      foreach(f;dmult.factors()){
         r = build_polytop_integrals2(f,v);
         foreach(t1;r){
            foreach(t2;result){
               result_help ~= [(t1[0]*t2[0]).simplify(one),(t1[1]*t2[1]).simplify(one),(t1[2]*t2[2]),simplify(one)];
            }
         }
         /*foreach(t;result_help){
               bounds_as_key = t[0].toString();
               if ((bounds_as_key in result_bounds_help) && (t[2]==result_rest_help[bounds_as_key])) {
                  result_integrand_help[bounds_as_key] = result_integrand_help[bounds_as_key]+t[1];

               }
               else{
                  result_bounds_help[bounds_as_key] = t[0];
                  result_integrand_help[bounds_as_key] = t[1];
                  result_rest_help[bounds_as_key] = t[2];
               }
         }*/

         result = null;
         result = result_help;
         /*foreach(k;result_bounds_help.byKey()){
            result ~= [result_bounds_help[k],result_integrand_help[k],result_rest_help[k]];
         }*/

         result_help = null;
         result_bounds_help = null;
         result_integrand_help = null;
         result_rest_help = null;
      }
      return result;
   }
   else{
      return result ~= [S("1"), S("1"),expression];
   }


}
+/



/* auto terms(dexpr.DExpr expression){
   dexpr.DExpr[] result;
   foreach(s;expression.summands){
      result ~= s;
   }
   return result;
} */

/*
extern(C) void PydMain() {
   def!(toString)();

    def!(S)();
    def!(simplify)();

    def!(is_zero)();
    def!(is_one)();
    def!(is_iverson)();

   def!(less)();
   def!(less_equal)();
   def!(greater)();
   def!(greater_equal)();
   def!(equal)();
   def!(not_equal)();
   def!(negate_condition)();

   def!(add)();
   def!(sub)();
   def!(mul)();
   def!(distribute_mul)();

   def!(div)();
   def!(pow)();
   def!(exp)();
   def!(sig)();

   def!(real_symbol)();

   def!(delta_pdf)();
   def!(normal_pdf)();
   def!(normalInd_pdf)();
   def!(uniform_pdf)();
   def!(beta_pdf)();
   def!(poisson_pdf)();

   def!(integrate)();
   def!(integrate_simple)();
   def!(integrate_poly)();
   def!(filter_iverson)();


   def!(terms)();


   module_init();
   wrap_class!(
      DExpr,
      Repr!(DExpr.toString)
   )();
} */
