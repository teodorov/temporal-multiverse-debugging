import data.set.basic
import sli.sli model_checking.mc_bridge debugging.rmd_bridge debugging.rmd_search

namespace rmd_step
universe u
variables (S C A E R V α : Type)

open sli
open sli.toTR
open model_checking
open rmd_bridge
open rmd_search

/-! 
  # A bridge from the subject semantics with breakpoints to a transition relation
  The breakpoint is a **temporal** step-based 
-/ 
def FinderBridgeTemporalStep {C₂ A₂ BE: Type}
  [has_evaluate: Evaluate C A E bool]
  [h: ∀ (actions : set (C × MaybeStutter A × C)), decidable (actions = ∅)]
  (istr : iSTR C₂ A₂ E (Step C A) bool (has_evaluate.step))
  (accepting : (C₂ → bool)  )                            
  (o : STR C A)      -- underlying STR
  (initial : set C)   -- initial configurations
  : TR (C × C₂) := 
    ModelCheckingStepBridge C C₂ A A₂ E
      (ReplaceInitial C A o initial)
      (λ c, true)
      (istr)
      (accepting)


def FinderFnTemporalStep {C₂ A₂ BE: Type}
  [has_evaluate: Evaluate C A E bool]
  [has_reduce:   Reduce (C×C₂) R α]
  [h: ∀ (actions : set (C × MaybeStutter A × C)), decidable (actions = ∅)]
  (
    inject : BE →                                             -- le model (code, expression) du breakpoint
        (iSTR C₂ A₂ E (Step C A) bool (has_evaluate.step))  -- semantique du breakpoint
      × (C₂ → bool)                                           -- la fonction d'acceptation induite par la semantic de breakpoint
      × EmptinessChecker (C × C₂) α 
  )
    : Finder C A E R α BE (C × C₂) 
| o initial breakpoint reduction :=  
let 
  (istr, accepting, search_breakpoint) := inject breakpoint 
in
  (list.map
    (λ (c: C × C₂), match c with | (c₁, c₂) := c₁ end) 
    (search_breakpoint
      (@FinderBridgeTemporalStep C A E C₂ A₂ BE has_evaluate h istr accepting o initial) 
      (Reduce.state reduction))
    )

/-!
  # The top-level semantics of the debugger
  it needs :
  * a subject semantics
  * a breakpoint
  * an abstraction of C
-/
def TopReducedMultiverseDebuggerTemporalStep {BE C₂ A₂: Type}
  [h_C_deq: decidable_eq C]
  [has_evaluate: Evaluate C A E bool]
  [has_reduce:   Reduce (C × C₂) R α]
  [h: ∀ (actions : set (C × MaybeStutter A × C)), decidable (actions = ∅)]
  [
    inject : BE →                                             -- le model (code, expression) du breakpoint
        (iSTR C₂ A₂ E (Step C A) bool (has_evaluate.step))  -- semantique du breakpoint
      × (C₂ → bool)                                           -- la fonction d'acceptation induite par la semantic de breakpoint
      × EmptinessChecker (C × C₂) α 
  ]
  (o : STR C A) (breakpoint : BE) (reduction : R) 
: STR (DebugConfig C A) (DebugAction C A) :=
    ReducedMultiverseDebuggerBridge C A E R α o 
      (FinderFnTemporalStep C A E R α inject) breakpoint reduction

def TemporalStepRMD {BE C₂ A₂: Type}
  [h_C_deq: decidable_eq C]
  [h: ∀ (actions : set (C × MaybeStutter A × C)), decidable (actions = ∅)]
  [has_evaluate: Evaluate C A E bool]
  [has_reduce:   Reduce (C × C₂) R α]
  [
    inject : BE →                                             -- le model (code, expression) du breakpoint
        (iSTR C₂ A₂ E (Step C A) bool (has_evaluate.step))  -- semantique du breakpoint
      × (C₂ → bool)                                           -- la fonction d'acceptation induite par la semantic de breakpoint
      × EmptinessChecker (C × C₂) α 
  ]
 := ReducedMultiverseDebugger S C A E R α (FinderFnTemporalStep C A E R α inject)


end rmd_step