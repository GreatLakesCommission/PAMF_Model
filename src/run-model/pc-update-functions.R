# 04/29/2019
# Functions supporting the partial controllability matrix update
#
# Functions:
#  getTBM      : Get participant's assessment of whether they followed PAMF 
#                guidance
#  ma2mc       : Get the combination (character) code associated with 3 numeric 
#                management action codes. This function differs from getMComb() 
#                in that it takes numbers instead of management reports
#  getCountsPC : Get the number of times each intended-implemented pair appears 
#                in the data
#  convertPC   : Convert the partial controllability matrix from data frame 
#                format to matrix format
##

getTBM = function(mnts, n_phases=3) {
  # Given a MU's management reports for a single PAMF cycle, return:
  #  * TRUE  if treatbymodel == 1 for all phases
  #  * FALSE if treabymodel  == 0 for any phases (and no other phase has a 2)
  #  * NA    if treatbymodel == 2 for any phases
  # These values (0,1,2) are as per the encodings in the database
  #
  # INPUT
  # mnts     : management records for one Mu over one PAMF cycle (data frame)
  # n_phases : number of phases per PAMF cycle
  #
  # OUTPUT
  # TRUE if treatbymodel==TRUE in all rows, FALSE if rows are a mix of
  # TRUE AND FALSE; NA if any row indicates no guidance given
  #
  # ASSUMPTIONS
  # * mnts has the following columns:
  #    phase
  #    treatbymodel
  # * There is only one unique treatbymodel value per phase
  ##
  
  tbm = mnts$treatbymodel
  if(length(tbm)<n_phases){     # not enough phases reported
    if(any(tbm==2)){return(NA)} # 'no guidance' repored in at least one phase
    else{return(FALSE)}         # participant knows of guidance + didnt follow
  }
  else{
    if(all(tbm==1)) {return(TRUE)}
    else{
      if(any(tbm==2)){return(NA)}
      else{return(FALSE)}
    }
  }
} # end getTBM

ma2mc = function(t_act, d_act, g_act, map){
  # Given numeric management action codes for each of the three PAMF phases
  # and a data frame containing all possible mappings, return the character 
  # string code for the management combination as a whole.
  #
  # INPUTS
  # t_act : code denoting translocating phase action (numeric)
  # d_act : code denoting dormant phase action (numeric)
  # g_act : code denoting growing phase action (numeric)
  # map   : data frame whose rows contain action codes (numeric) and combination
  #         codes (character)
  #
  # OUTPUTS
  # The combination code (character) associated with the inputs. If there is
  # no such code, return "OTHER"
  #
  # ASSUMPTIONS
  # * There is a unique combination code for each unique sequence of actions
  # * t_act, d_act, and g_act make up a PAMF combination. This is a reasonable
  #   assumption when this function is called by update_pc.R because these 
  #   values are taken from guidance (which is always a PAMF combination)
  # * map contains the following columns:
  #      db_tloc
  #      db_dorm
  #      db_grow
  #      mnt_comb
  ##
  
  # Subset map by t_act, d_act, g_act to isolate the correct row; pull out
  # the mnt_code column
  mnt_code = map[map$db_tloc==t_act & map$db_dorm==d_act & map$db_grow==g_act,
                 "mnt_comb"]
  
  # Check that mnt_code contains exactly one code and respond accordingly
  if(length(mnt_code)==1){ 
    # the map associates the actions with exactly one management combination
    return(as.character(mnt_code))
  }
  else{
    if(length(mnt_code)==0){
      # the actions do not make a combination that appears in the map
      return("OTHER")
    }
    else { 
      # more than one management code found
      stop(paste("ma2mc: More than one managment combination associated with 
                 this set of actions:", t_act, ",", d_act, ",", g_act))
    }
  }  
} # end ma2mc

getCountsPC = function(firsti, lasti, data){
  # Given the first and last index of a block of identical rows in a data frame 
  # and the data frame itself, return a row containing (a) the values that 
  # appear in the block and (b) the number of rows in that block
  #
  # INPUTS
  # firsti : First row index of a block of identical rows (numeric)
  # lasti  : Last row index of a block of identical rows (numeric)
  # data   : The data frame containing the identical row blocks 
  # 
  # OUTPUTS
  # A single-row data frame containing (a) the values that define the identical 
  # block and (b) the number of rows in the block.
  # 
  # ASSUMPTIONS
  # * data is already sorted so that identical rows are already gathered
  #   together in blocks
  ##
  
  # get number of identical rows in the block defined by firsti, lasti
  count = (lasti-firsti) + 1 # 1 row when firsti==lasti
  
  return(data.frame(data[firsti,], count=count, stringsAsFactors=FALSE))
  
} # end getCountsPC

convertPC = function(pc_df, transitions=TRUE) {
  # Given a partial controllability matrix in data frame format (where each row
  # corresponds to a matrix entry), convert to matrix format
  #
  # INPUT
  # pc_df       : the partial controllability matrix in data frame format 
  #               (data frame)
  # transitions : If TRUE, return a matrix of transition probabilities. otherwise
  #               return a matrix of concentrations (numeric)
  # 
  # OUTPUT
  # A matrix version of the information in pc_df
  # 
  # ASSUMPTIONS
  # * All of the management combinations used by the optimization appear
  #   in both the mnt_intended and mnt_implemented columns of pc_df
  # * pc_df has the following columns:
  #      mnt_intended
  #      mnt_implemented
  #      probability
  ##
  
  # Sort by mnt_implemented, then mnt_intended. 
  # This organizes the data by what will become the columns of the partial 
  # controllability matrix (with the rows in a consistent order)
  pc_df = pc_df[order(pc_df$mnt_implemented, pc_df$mnt_intended),]
  
  # Get management combination codes for matrix labels
  mnt_combs = unique(pc_df$mnt_intended)
  rows_cols = length(mnt_combs)
  
  # convert to matrix & return
  if(transitions==TRUE){
    pc_matrix = matrix(pc_df$probability, nrow=rows_cols, ncol=rows_cols)
  }else{
    pc_matrix = matrix(pc_df$concentration, nrow=rows_cols, ncol=rows_cols)
  }
  
  rownames(pc_matrix) = mnt_combs
  colnames(pc_matrix) = mnt_combs
  
  return(pc_matrix)
  
} # end convertPC