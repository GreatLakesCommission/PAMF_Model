# 2020-07-31
#
# Functions supporting the transition matrix update
#
# Functions:
#   getPseudoCounts      : Distributes an observation among possible transitions
#                          in a data package, according to their probability
#   getTotalPseudocounts : Get all (whole and partial) observed transitions 
#                          between states, under one managment combination
#   getTransProbs        : Calculate the probability of each possible transition 
#                         out of a single state
##

getPseudoCounts = function(observed) {
  # Distributes an observation among possible transitions in a data package, 
  # according to their probability
  #
  # INPUT
  # observed : A data frame row representing one observed uncertain transition 
  #            (data frame)
  # 
  # OUTPUT
  # A vector where the first 6 elements are pseudocounts for transitions out of 
  # state 1, the next 6 elements are the pseudocounts for transitions out of 
  # state 2, etc.
  # 
  # ASSUMPTIONS
  # 1. observed has the following columns:
  #      pr_est0_begin |
  #      pr_est1_begin | these sum to 1
  #      pr_est2_begin |
  #      pr_lo_begin   } these sum to 1
  #      pr_hi_begin   }
  #      pr_est0_end   ) 
  #      pr_est1_end   ) these sum to 1
  #      pr_est2_end   )
  #      pr_lo_end     ] these sum to 1
  #      pr_hi_end     ]
  # 2. All of these columns contain numerical values (NOT NA)
  ##
  
  ## Calculate conditional probabilities
  # Each of the pr_* columns the probabilities of observing the management
  # unit to be in state A, when it is really in state B.
  # Note the (very likely) possibility that B=A!
  ##
  
  # probability of each establishment category before cycle
  peb = c(observed$pr_est0_begin, observed$pr_est1_begin, observed$pr_est2_begin)
  # probability of each establishment category after the cycle
  pea = c(observed$pr_est0_end, observed$pr_est1_end, observed$pr_est2_end) 
  # probability of each density category before the cycle
  pdb = c(observed$pr_lo_begin, observed$pr_hi_begin)
  # probability of each density category after the cycle
  pda = c(observed$pr_lo_end, observed$pr_hi_end) 
  
  
  # Build list of conditional probabilities for beginning states:
  cprobs_init = rep(peb, each=length(pdb)) * pdb
  # This vector gives the probability of the MU being in any est-dens
  # combination as its initial state: 
  # cprobs_init[1] : P (state 1- est=0.1 AND dens=L)
  # cprobs_init[1] : P (state 2- est=0.1 AND dens=H) etc.
  # cprobs_final works the same way.
  
  # Build list of conditional probabilities for ending states:
  cprobs_final = rep(pea, each=length(pda)) * pda
  
  
  ## Assuming that conditional probabilities between one time step and the next 
  # are independent (i.e. measurement accuracy doesn't change systematically over
  # the years), calculate pseudocounts by taking outer product of the conditional
  # probabilities associated with the initial and final states.
  ##
  g = outer(cprobs_init, cprobs_final)
  # Rows of g are initial states, columns are final states
  
  ## Return as a vector (format described above)
  #  Since single indexing moves down columns rather than across rows, first take
  #  the transpose
  ##
  return(t(g)[1:length(g)])
} # end getPseudocounts

getTotalPseudocounts = function(observed){
  # Get all (whole and partial) observed transitions between states, under one 
  # managment combination
  #
  # INPUT
  # observed : A set of transition observations with or without uncertainty 
  #            (data frame)
  # 
  # OUTPUT
  # A two-column data frame, where one column describes the management 
  # combination and the other contains the total observed transitions from one 
  # state to another. The order of the observations is equivalent to appending 
  # the rows of a transition matrix end to end
  #
  # ASSUMPTIONS
  # 1. observed has the following columns:
  #      mnt_comb
  #      pr_est0_begin |
  #      pr_est1_begin | these sum to 1
  #      pr_est2_begin |
  #      pr_lo_begin   } these sum to 1
  #      pr_hi_begin   }
  #      pr_est0_end   ) 
  #      pr_est1_end   ) these sum to 1
  #      pr_est2_end   )
  #      pr_lo_end     ] these sum to 1
  #      pr_hi_end     ]
  # 2. All of these columns contain numerical values (NOT NA)
  # 3. There is only one unique value in observed$mnt_comb
  # 4. The following functions are sourced:
  #      getPseudoCounts
  ##
  
  ## Get pseudocounts for each row in observed then sum them up
  pcounts = sapply(split(observed, observed$munitid), getPseudoCounts)
  pcounts_tot = rowSums(pcounts)
  
  return(data.frame(mnt_comb=rep(unique(observed$mnt_comb), length(pcounts_tot)),
                    pseudocount = pcounts_tot, stringsAsFactors=FALSE))
} # end getTotalPseudocounts

getTransProbs = function(concentrations){
  # Calculate the probability of each possible transition out of a single state
  #
  # INPUT
  # concentrations : number of times each transition was observed, can be partial
  #                  (numeric)
  #
  # OUTPUT
  # A vector of probabilities
  #
  # ASSUMPTIONS
  #  * concentrations describes observed transitions out of one state, to any 
  #    possible state
  ##
  
  if(sum(concentrations)>0){
    t_probs = concentrations / sum(concentrations)
    
    ## Distribute any rounding errors evenly across the probabilities so that 
    #  they sum to 1 and return
    t_probs = suppressWarnings(repairSums(t_probs))
    
    # Verify that repairSums did not succumb to its own rounding errors
    if(sum(t_probs)-1 != 0){
      warning("getTransProbs: Failure of repairSums!")
    }
    
    return(t_probs)
  }else{
    return(rep(NaN, length(concentrations)))
  }

} # end getTransProbs
