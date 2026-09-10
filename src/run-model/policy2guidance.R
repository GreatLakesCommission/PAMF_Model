# This script reads the policies generated in optimizer.R and assigns the 
# correct management combinations to each management unit, based on (a) its 
# current state, and (b) any policy restrictions (e.g. no flood, no herbicide).
#
# The 'correct' management combinations include both optimal and near-optimal
# combinations, with optimality denoted in the "optimal" column of policies*.csv
# where 1 = TRUE and 0 = FALSE
#
# Note that the set of management units used here may be different than the one
# used to update the model: Here, we need only a complete monitoring report at 
# the end of the cycle; management reports don't matter.
#
# Sourced by: run-the-model.R
#
# DEPENDENCIES
# * Global Constants
#    CYCLEEND   : final year of the cycle being analyzed
#    LODENS_MAX : maximum stem count for low density
#    STATES     : codes for the states of the state & transition model
#    PAMF_COMBS : management combination codes
#
# * Variables
#    enroll_data   : enrollment reports
#    mon_data      : monitoring reports with monitor_year column added
#    mon_issues    : potential issues with monitoring reports submitted during 
#                    CYCLEEND
#    datpak        : data packages from the cycle being analyzed
#    datpak_issues : potential issues with data packages belonging to datpak
#    policies      : optimal guidance by state (i.e. by %est, dens combination)
#    opnop_actions : optimal and near-optimal actions for each state
#    action_restrictions : management codes available under each policy 
#                          restriction
##

# Get Management Units (MUs) with current reports -----------------------------

# MUs to get guidance meet these criteria:
#  1. Active in CYCLEEND (everything in datpak meets this criterion)
#  2. Not withheld from guidance release by coordinator
#  3. Have a known state in CYCLEEND
##
coordrej_munitid = mon_issues[mon_issues$monitor_year==CYCLEEND & 
                                mon_issues$coordreject_guid==TRUE, "munitid"]
stateend_munitid = datpak[datpak$cycle_end==CYCLEEND & !is.na(datpak$state_end), 
                          "munitid"]
guidance_munitid = setdiff(stateend_munitid, coordrej_munitid)

guidance_mus = datpak[datpak$cycle_end==CYCLEEND & datpak$munitid %in% 
                        guidance_munitid, c("munitid", "state_end")]
colnames(guidance_mus)[which(colnames(guidance_mus)=="state_end")]="state"

# Determine which action restriction applies to each MU ------------------------

# Merge management restrictions (from enrollment reports) onto guidance_mus
guidance_mus = merge(guidance_mus, enroll_data[,c("munitid", "herbicide", "cut", 
                                                  "controlwater")])

# Get one row from action_restrictions for each restr_id
restrictions = unique(action_restrictions[,c("restr_id", "herbicide", "cut", 
                                            "controlwater")])

# Merge guidance_mus and restrictions, thereby gathering 'state' and 'restr_id'
# for each management unit into a single row
guidance_mus = merge(guidance_mus, restrictions, by=c("herbicide", "cut", 
                                                      "controlwater"))

# Now merge on the recommended actions (optimal AND near-optimal) 
# We don't need Q anymore, it was saved to CSV in run-the-model.R after
# optimizer.R was run
opnop_actions$Q <- NULL 
# Keep only the optimal and near-optimal policies, not the ones with NA
opnop_actions <- opnop_actions[!is.na(opnop_actions$optimal), ]
guidance = merge(guidance_mus, opnop_actions, by=c("state", "restr_id"))

# Keep munitid, state, db_*, and add a column to indicate which cycle the 
# guidance is from
recommenddate   = rep(Sys.Date(), nrow(guidance))
recommend_cycle = rep(CYCLEEND, nrow(guidance))
guidance = cbind(guidance[, c("munitid","state", "db_tloc", "db_dorm", "db_grow",
                              "optimal")], recommend_cycle, recommenddate)

# change db_tr, db_do, db_gr to more informative names
colnames(guidance) = c("munitid", "state", "transrec", "dormrec", "growrec", 
                       "optimal", "recommend_cycle", "recommenddate")

# Clean up temporary variables -------------------------------------------------

rm(coordrej_munitid, stateend_munitid, guidance_mus, restrictions, 
   recommend_cycle)
