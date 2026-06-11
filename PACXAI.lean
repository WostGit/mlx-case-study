import PACXAI.Core
import PACXAI.Transcript
import PACXAI.Recovery
import PACXAI.Conditioning
import PACXAI.Distillation
import PACXAI.Leakage.FiniteCapacity
import PACXAI.InfoTheory.FiniteDistribution
import PACXAI.InfoTheory.DPI
import PACXAI.InfoTheory.FanoStyle
import PACXAI.PAC.MonteCarlo

namespace PACXAI

/-- CI smoke theorem: the repository contains a buildable Lean library. -/
theorem ci_smoke : True := by
  trivial

end PACXAI
