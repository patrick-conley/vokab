Confidence
==========

The lower-bound confidence used throughout this document is p. Choice of p
determines two things:

    - using higher p increases non-linearity of results: under high p, a
      few early correct results can give a very score; under low p, 
      score ≅ pos/total
    - using higher p decreases the range between results (in the body of the
      plot), so often-correct words will appear much more frequently than under
      low p

I propose using 2σ-confidence: p = 0.95

Wilson score
============

A score is computed for each word according to the Wilson score lower bound
from <http://www.evanmiller.org/how-not-to-sort-by-average-rating.html>,

# score = ( p + z^2/2n + z * sqrt( ( p(1-p) + z^2/4n )/n ) ) / ( 1 + z^2/n)

where z is the quantile function,

# z(p) = sqrt(2) erf⁻¹(p)

Note that Wikipedia uses erf⁻¹(2p-1); however, the Wilson score uses z(1-α/2),
(α ≡ 1-p), which cancels out.

The Wilson score interval only applies when results are statistically
independent, which is not the case, but since this isn't a study on lanugage
acquisition, I'll ignore that..

Word weighting
==============

Each word is weighted by the inverse of its Wilson score. Words that have been
seen fewer than three times are assigned a score of 0.5 (prevents division by
0 and early biasing).

Chapter weighting
=================

Only words from chapters up to the current chapter will ever be selected. The
current chapter increases only when FracWords(score>0.8) > p.

Words in each chapter have a secondary weighting, applied after the score, of 

# 0.8^(CurrentChap-chap)

Final selection
===============

Then, the selection probability of a word is 

# (Wilson⁻¹ * ChapterWeight) / ( sum over words (Wilson⁻¹ * ChapterWeight) )

A uniformly-distributed random number in [0,1) selects
