import std.conv;
import std.algorithm;

import options, hashtable, dutil;


import pyd.pyd;

import dparse;
import dexpr;
import distrib;
import integration;

auto toString(dexpr.DExpr a){
   return a.toString();
}

auto S(string symbol){
   return symbol.dParse.simplify(one);
}
auto simplify(dexpr.DExpr a){
   return a.simplify(one);
}

auto is_zero(dexpr.DExpr a){
   return a==S("0");
}
auto is_one(dexpr.DExpr a){
   return a==S("1");
}
auto is_iverson(dexpr.DExpr a){
   return cast(DIvr)a;
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
auto negate_condition(dexpr.DExpr exp){
   auto iv=cast(DIvr)exp;
   return dexpr.negateDIvr(iv);
}



auto add(dexpr.DExpr a, dexpr.DExpr b){
   return (a+b);
}
auto sub(dexpr.DExpr a, dexpr.DExpr b){
   return (a-b);
}
auto mul(dexpr.DExpr a, dexpr.DExpr b){
   return (a*b);
}

auto distribute_mul(DExpr sum1, DExpr sum2){
   dexpr.DExpr result = "0".dParse;
   auto s1=cast(DPlus)sum1;
   auto s2=cast(DPlus)sum2;
   if (s1 && s2){
      foreach(t1;s1.summands){
         foreach(t2;s2.summands){
            result = result + (t1*t2).simplify(one);
         }
      }
   }
   else if (s1){
      foreach(t1;s1.summands){
         result = result + (t1*sum2).simplify(one);
      }
   }
   else if (s2){
      foreach(t2;s2.summands){
         result = result + (t2*sum1).simplify(one);
      }
   }
   else{
      result = sum1*sum2;
   }
   return result;
}



auto div(dexpr.DExpr a, dexpr.DExpr b){
   return (a/b);
}
auto pow(dexpr.DExpr a, dexpr.DExpr b){
   return (a^^b);
}
auto exp(dexpr.DExpr a){
   dexpr.DExpr E;
   E = "e".dParse;
   return (E^^a);
}
auto sig(dexpr.DExpr x){
   dexpr.DExpr E;
   E = "e".dParse;
   return (1/(1+E^^(-x)));
}


auto real_symbol(string var){
   return S(var);
}

auto delta_pdf(string var, dexpr.DExpr root){
   auto v = dVar(var);
   return dDelta(v-root).simplify(one);
}
auto normal_pdf(string var, dexpr.DExpr mu, dexpr.DExpr sigma){
   auto v = dVar(var);
   return (gaussPDF(v, mu, sigma)).simplify(one);
}
auto normalInd_pdf(string[] var, dexpr.DExpr[] mu, dexpr.DExpr[] sigma){
   auto result =  S("1");
   for (int i = 0; i < var.length; i++){
      result =  result*gaussPDF(dVar(var[i]), mu[i], sigma[i]);
   }
   return result;
}


auto uniform_pdf(string var, dexpr.DExpr alpha, dexpr.DExpr beta){
   auto v = dVar(var);
   return (uniformPDF(v, alpha, beta)).simplify(one);
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
   auto integral = integrand;
   foreach (i; 0 ..variables.length){
      integral = integrate_simple(variables[i], integral);
      /*integral = integral.simplify(one);*/
   }
   return integral.simplify(one);

   /*return integral.simplify(one);*/
}


auto integrate_simple(string variable, dexpr.DExpr integrand){
   return dInt(variable.dVar, integrand);
}



auto integrate_poly(string[] variables, dexpr.DExpr integrand){
   auto integral = integrand;
   foreach (i; 0 ..variables.length){
      /*writeln(variables[i]);*/
      /*writeln(integral);*/
      integral = integrate_poly_simple1(variables[i], integral);
      /*integral = integral.simplify(one);*/
      /*writeln("");*/
   }
   /*writeln("");*/
   /*writeln(integral);*/
   /*writeln("simplifying");*/
   /*writeln(integral);*/
   integral = integral.simplify(one);
   writeln(integral);

   /*writeln(integral);*/
   return integral;
}


auto integrate_poly_simple1(string variable, dexpr.DExpr integrand){
   auto v = variable.dVar;
   integrand = make_closed_bounds(integrand);
   auto result = dInt(v, integrand);
   return result;
}





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
}


auto filter_iverson(dexpr.DExpr expression){
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
}

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




auto integrate_poly_simple3(string variable, dexpr.DExpr integrand){
   auto v = variable.dVar;
   auto polytope_integrals = build_polytop_integrals2(integrand,v);
   auto result  = zero;
   /*writeln("");
   writeln(polytope_integrals.length);
   writeln(v);*/
   foreach(pi;polytope_integrals){
      /*writeln(pi[0]);
      writeln(pi[1]);*/
      /*result = (result + make_closed_bounds(dInt(v,pi[0]*pi[1])).simplify(one)*pi[2]).simplify(one);*/
      auto inter_result = make_closed_bounds(dInt(v,pi[0]*pi[1]).simplify(one));
      inter_result = (inter_result*pi[2]).simplify(one);
      auto common = splitCommonFactors(result,inter_result);

      /*writeln("commmon");
      writeln(common[0]);
      writeln(common[1]);
      writeln(common[2]);*/

      result = common[0]*(common[1]+common[2]);

   }
   /*result = make_closed_bounds(result);*/
   /*writeln(result);*/
   writeln(v);
   return result;
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



auto terms(dexpr.DExpr expression){
   dexpr.DExpr[] result;
   foreach(s;expression.summands){
      result ~= s;
   }
   return result;
}


extern(C) void PydMain() {
   def!(toString)();

    def!(S)();
    def!(simplify)();

    def!(is_zero)();
    def!(is_one)();

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
}
