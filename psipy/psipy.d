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
}


auto integrate_simple(string variable, dexpr.DExpr integrand){
   return dInt(variable.dVar, integrand);
}



auto integrate_poly(string[] variables, dexpr.DExpr integrand){
   auto integral = integrand;
   foreach (i; 0 ..variables.length){
      integral = integrate_poly_simple(variables[i], integral);
      /*integral = integral.simplify(one);*/
   }

   return integral;
}


auto integrate_poly_simple(string variable, dexpr.DExpr integrand){
   auto v = variable.dVar;
   integrand = remove_ineq(integrand);
   writeln(integrand);
   integrand = dInt(v, integrand);
   return integrand.simplify(one);
}


dexpr.DExpr remove_ineq(dexpr.DExpr expression){
   if(auto dsum=cast(DSum)expression){
      auto result = S("0");
      foreach(s;dsum.summands()){
         result = result+remove_ineq(s);
      }
      return result;
   }
   else if(auto dmult=cast(DMult)expression){
      auto result = S("1");
      foreach(f;dmult.factors()){
         result = result*remove_ineq(f);
      }
      return result;
   }
   else if(auto iv=cast(DIvr)expression){
      if (expression.toString().canFind("≠")){
         return S("1");
      }
      else{
         return expression;
      }
   }
   else{
      return expression;
   }
}



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

   def!(delta_pdf)();
   def!(normal_pdf)();
   def!(normalInd_pdf)();
   def!(uniform_pdf)();
   def!(beta_pdf)();
   def!(poisson_pdf)();

   def!(integrate)();
   def!(integrate_simple)();
   def!(integrate_poly)();


   def!(terms)();


   module_init();
   wrap_class!(
      DExpr,
      Repr!(DExpr.toString)
   )();
}
