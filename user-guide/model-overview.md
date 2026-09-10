# PAMF Model Overview  

## Table of Contents  
- [How the PAMF Model Works](#how-the-pamf-model-works)
- [Mid-Cycle Forecasting Guidance](#mid-cycle-forecasting-guidance)
- [Model Schematic](#model-schematic)
- [Phase-date Decisions](#phase-date-decisions)
- [Base Runs](#base-runs)

## How the PAMF Model Works    
The PAMF Model is the foundation of the 
[*Phragmites* Adaptive Management Framework](https://www.greatlakesphragmites.net/pamf/). 
The PAMF model is made up of a back-end component (R scripts) that analyzes 
participants' monitoring and management data (or [data packages](#data-packages)) 
and generates guidance, and a front-end component (R Shiny application) designed 
to facilitate the model's usage by PAMF staff. [Management guidance](#management-guidance) 
production occurs over two broadly defined steps: (1) the PAMF Model draws from data in 
the PAMF database to update [transition probabilities](#transition-probabilities) across 
a set of matrices describing the efficacy of each [management combination](#management-combinations) 
across all possible [invasion states](#invasion-states), and (2) the Model provides these 
updated transition matrices, alongside cost information, satisfaction values, and 
information regarding participants' usage of past guidance 
([partial controllability](#partial-controllability)), to an 
[optimization routine](#optimization-routine) that solves for the optimal 
approach to *Phragmites* management for each PAMF [management unit](#management-units). 
The PAMF Model is run yearly after the end of a PAMF 'cycle' (August of year 1 
to August of year 2) to produce management guidance for the next PAMF cycle. The 
PAMF Model can also be run in February to produce 
[Mid-Cycle Forecasting Guidance](#mid-cycle-forecasting-guidance) for a 
prediction of what standard August guidance may be. 

See the conceptual diagram below for the steps the PAMF Model takes to produce 
management guidance, starting from the top left.  
<img src="/user-guide/images/model_diagram.PNG"/>  
**Figure 1.** Key to colors: white = input, light gray = intermediate output, 
medium gray = output, black = process. "MU" = management unit.  

### Management units    
In PAMF, a management unit (MU) is defined as the enrolled area where a PAMF 
participant manages non-native *Phragmites* in a uniform manner. Determining 
the size and shape of the MU is left to each participant, but PAMF staff 
recommend defining an MU as the smallest area surrounding the *Phragmites* 
that a participant plans on managing and over which they are able to apply 
the same management action at one time. Incomplete application of an action 
across the full extent of the *Phragmites* in the MU or the application of 
two or more actions within the MU results in management reports that cannot 
be used in the PAMF Model. When enrolling in PAMF, participants note whether 
any of the following management techniques can be used at the MU:  

* Herbicide  
* Cutting underwater  
* Manipulation of water levels (i.e., flooding)  

These management restrictions are used to determine which 
[management combination](#management-combinations) can be suggested 
as [management guidance](#management-guidance) to participants. For example, 
the PAMF Model will not recommend that someone use a management combination 
that involves any kind of herbicide if herbicide is not permitted for use at 
the MU. See the [PAMF Participant Guide](https://bugwoodcloud.org/pamf/resources/PAMFParticipantGuideV5.0.pdf) 
for more criteria for enrolling management units in PAMF. 

### Invasion states  
PAMF participants collect information about the invasion state of their
management unit (MU) yearly in July. See the 
[PAMF Participant Guide](https://bugwoodcloud.org/pamf/resources/PAMFParticipantGuideV5.0.pdf) for
more information about the monitoring protocol. Data collected by participants
is used to delineate the MU's invasion state ranging from 1 (low *Phragmites*
invasion) to 6 (high *Phragmites* invasion) based on the stem density at five
0.25 square meter quadrats and the percent establishment across the MU.

<img src="/user-guide/images/invasion_states.PNG" width="400"/>  

**Figure 2.** Diagram of *Phragmites* invasion state determination.  

### Management Combinations  
PAMF uses 16 potential management combinations that are intended to reflect
current management practices throughout different phases of the *Phragmites*
life cycle (Table 1). Each combination consists of three management actions
(e.g., Combo #2 has Glyphosate, Remove Biomass, Rest) with one action for each
management phase (i.e., translocating, dormant, and growing biological phases,
or fall, winter, and spring/summer, respectively). See the 
[PAMF Participant Guide](https://bugwoodcloud.org/pamf/resources/PAMFParticipantGuideV5.0.pdf) for
definitions of each management action.

**Table 1.** PAMF management combinations. Each combination is made up of 
separate management actions, one for each phase. Translocating phase = 
August-October; Dormant phase = November - March; Growing phase = April-June.  

|    | Translocating  | Dormant                        | Growing        |
|----|----------------|--------------------------------|----------------|
| 1  | Glyphosate     | Pre-flood clearing             | Flood          |
| 2  | Glyphosate     | Remove biomass                 | Rest           |
| 3  | Glyphosate     | Flood                          | Flood          |
| 4  | Glyphosate     | Mechanical (and leave biomass) | Rest           |
| 5  | Glyphosate     | Rest                           | Glyphosate     |
| 6  | Glyphosate     | Rest                           | Rest           |
| 7  | Glyphosate +   | Remove biomass                 | Rest           |
| 8  | Glyphosate +   | Flood                          | Flood          |
| 9  | Glyphosate +   | Mechanical (and leave biomass) | Rest           |
| 10 | Glyphosate +   | Pre-flood clearing             | Flood          |
| 11 | Glyphosate +   | Rest                           | Rest           |
| 12 | Imazapyr       | Rest                           | Rest           |
| 13 | Rest           | Pre-flood clearing             | Flood          |
| 14 | Cut underwater | Rest                           | Cut underwater |
| 15 | Spading        | Rest                           | Spading        |
| 16 | Rest           | Rest                           | Rest           |

### Data Packages  
There are two types of data packages used in the PAMF Model.  

#### Complete Data Package  
A data package that has fulfilled all the data submission requirements for a
given management unit (MU) to receive guidance from the PAMF Model. For new
management units, this is just a monitoring report during the monitoring window
at the end of the current PAMF cycle. For MUs that were monitored during the
previous cycle, a complete data package entails two monitoring reports (pre- and
post-treatment) and three or more management reports (at least one per phase).
Complete data packages from new MUs are not used to update the PAMF Model's
transition probabilities, but are only used to obtain management guidance.

#### Full Data Package
A full data package is a subset of complete data package. A data package that
includes the previous year's monitoring report, three or more management reports
(i.e., at least one for each phase), and the current year’s monitoring report.
The data package must follow a valid [management
combination](#management-combinations). This data is used to update the PAMF
Model's transition probabilities.

<img src="/user-guide/images/Data_packages.PNG" width="900"/>  

**Figure 3.** Differences in which PAMF Model actions can occur based on the 
data available from new management units (MUs; enrolled in program in the 
current year) and previously enrolled MUs. * indicates that the data package can 
only be considered a full data package eligible to contribute to the PAMF Model's 
learning process if it follows a valid [management combination](#management-combinations).  

### Transition Probabilities  
PAMF uses first-order Markovian transition matrices to derive optimal
state-action policies and to organize observed *Phragmites* responses to
management. Because we expect each [management
combination](#management-combinations) to affect *Phragmites* differently, the
PAMF Model includes a separate matrix for each management combination, for a
total of 16 matrices. Each matrix contains the probabilities of transition among
the six possible [invasion states](#invasion-states). Bayesian updating of
Dirichlet-multinomial distributions is used to incorporate new observations from
[full data packages](#data-packages) into the transition matrices. Management
reports determine which transition matrix of the 16 that the observation belongs
to, while the previous-year and current-year monitoring reports determine which
row(s) and column(s), respectively, that the observation will influence.

<img src="/user-guide/images/Transition_matrix.PNG" width="350"/>  

**Figure 4.** Example of a transition matrix where the management combination 
is "Cut underwater, Rest, Cut underwater." The transition probabilities between 
beginning *Phragmites* invasion states (pre-management) and end invasion states 
(post-management) are noted in each cell of the matrix. In this example, there 
is a 80% probability of a management unit transitioning from invasion state 5 
(high *Phragmites*) to state 1 (low *Phragmites*) following management using 
"Cut underwater, Rest, Cut underwater", but a 20% probability that it will 
transition to state 3.  

Each transition in each matrix is associated with a concentration value (α,
α>0), which represents the cumulative weight of evidence behind the
corresponding transition probability. When a data package describes a transition
between two states, **A** and **B**, the concentration associated with the
**A**->**B** transition is incremented by 1. Then all transition probabilities
originating in State **A** are re-calculated by dividing the concentration of
each transition out of **A** by the total concentration of transitions out of
**A**, to maintain a sum of 1 across the row. As observations of the
**A**->**B** transition accumulate, the probability associated with that
transition increases and the probabilities of other transitions out of **A**
decrease. Observations of transitions out of **A** do not affect the
probabilities of transitions out of any other state, and observations made under
one management combination do not affect the transition probabilities associated
with any other management combination. Moreover, observations accumulate
unevenly within and across matrices, due to the set of realized initial states
among PAMF management units (MUs), and to participants' management decisions.

In cases where a data package contains uncertainty about which invasion state an
MU is in (i.e., stem counts in one or both monitoring reports fall on both sides
of the low/high density threshold), the PAMF Model treats the MU's state as
probabilistic, where its likelihood of belonging to the high- or low-density
state is defined by the proportion of stem counts above or below the density
threshold, respectively. Such uncertainty in state leads to uncertainty in the
observed transition. The PAMF Model accommodates for uncertainty among
transitions by distributing the observation proportionally across those
transitions defined by the MU's possible states. Specifically, it calculates the
outer product of the MU's state probabilities at the beginning and end of the
cycle, and assigns the corresponding partial observation to each possible
transition. Transition probabilities are then updated as described above. This
method of dealing with uncertainty assumes independence between the stem counts
taken each year. Each time participants monitor a MU, the Web Hub generates a
new set of quadrat locations along a transect in the MU.

The PAMF Model's state-and-transition model was initialized prior to the first
PAMF cycle with weakly informative priors, based on the results of an expert
elicitation exercise, that capture existing knowledge and uncertainty among
*Phragmites* managers and researchers in the region. To establish the priors, we
set each transition's prior concentration equal to the probability provided by
the experts. Consequently, all prior concentrations are < 1, with slightly more
evidence weight for more-likely transitions than for less-likely transitions.
From these prior values, concentration parameters increase without limit as
observations accumulate through time to inform each transition.

### Optimization Routine  
The PAMF Model's optimization routine selects the [management
combination](#management-combinations) that provides the best balance of
efficacy (i.e., reduction in invasion state) and cost for each management unit
(MU). The PAMF Model uses a Markov Decision Process (MDP) to perform this step (Chadès et al. 2014).
An MDP is made up of a process with probabilistic transitions between states and
a notion of reward, along with a finite set of actions, only one of which can be
implemented at any time step. Solving an MDP requires finding an optimal policy,
which comprises a reward-maximizing action for each possible state. The PAMF
model uses the R package
[MDPToolbox](https://cran.r-project.org/web/packages/MDPtoolbox/index.html) to
find optimal policies (i.e., [management guidance](#management-guidance)).

In the PAMF Model, the reward value depends upon a satisfaction score describing
the desirability of a given outcome, and upon the cost of the chosen action.
Satisfaction values were derived from an expert elicitation exercise and is
assumed to remain constant through time. Cost is based upon a ranking by effort,
under the assumption that management combinations requiring more effort are more
costly and that differences in cost between progressively expensive actions are
equal. We use an outer product to combine satisfaction and cost into a single
reward value. The optimization step also takes [partial
controllability](#partial-controllability) into account.

Not all management combinations are appropriate for every MU, and in such cases
are not provided as guidance. The three constraints on management are listed in
the ["management units" section](#management-units). In order to provide
guidance for MUs where one or more of these cases applies, we optimize over
possible management combinations under each combination of constraints for a
total of eight optimizations. The optimal management combination for each MU
depends both upon its state at the time of the model run and upon its management
restrictions.

To accommodate for budget limitations and unexpected conditions that may limit
participants' ability to follow the optimal guidance, the PAMF model also
identifies near-optimal management combinations. These near-optimal
recommendations are similar in cost and/or effectiveness to the optimal
recommendation, with reward values within 5% of the reward value of the optimal
recommendation. Like the optimal recommendation, near-optimal recommendations
are state-specific and adhere to each MU's management constraints.

### Partial Controllability  
Optimal guidance may lead to sub-optimal outcomes if participants are unable or
unwilling to follow it. Partial controllability refers to the possibility that
managers don't implement the recommended set of actions. The partial
controllability matrix stores the probability that any PAMF combination **P**
will be implemented, given recommendation **R**. These probabilities can be
incorporated into the transition matrices of the PAMF Model by multiplying a
vector corresponding to one transition across all actions by a column of the
partial controllability matrix. In this case, the 'transitions' are from
recommended combination to implemented combination, and the prior assumes that
guidance is followed 100% of the time with a concentration = 1.

### Management Guidance   
Management guidance includes model-generated recommendations of how to manage
the *Phragmites* in a management unit (MU). This guidance will consist of an
optimal [management combination](#management-combinations) that participants are
encouraged to follow (e.g., Combo #1: Glyphosate in the translocating phase,
Pre-Flood Clearing in the dormant phase, and Flood in the growing phase) as well
as a few near-optimal combinations that may also perform well at the MU. These
near-optimal recommendations are similar in cost and/or effectiveness to the
optimal recommendation, with reward values within 5% of the reward value of the
optimal recommendation. The optimal management combination is determined by
evaluating the trade off between anticipated management action efficacy over
time and expected accumulated costs. Thus, the optimal combination may not
necessarily be the combo that would reduce the MU's *Phragmites* the most, but
rather the combo that the model identifies as striking the best balance between
reducing *Phragmites*, minimizing costs over a period of time, maximizing
satisfaction, and taking into account what other managers have done. An example
of management guidance is provided in Table 2 below.

**Table 2.** Example of management guidance created by the PAMF Model for a single management unit.  

| Guidance type | Translocating | Dormant | Growing |
|---------------|---------------|---------|---------|
| Optimal       | Spading       | Rest    | Spading |
| Near-optimal  | Rest          | Rest    | Rest    |

## Mid-Cycle Forecasting Guidance  

Management guidance produced by the PAMF Model is provided to participants in
August, which may be too late in the year for some managers to begin planning
their management for the next year. For this reason, PAMF offers an additional
way to generate guidance: Mid-Cycle Forecasting Guidance (MCFG). MCFG
anticipates in February what the optimal guidance in August is most likely to
be. MCFG is generated through the same model that provides guidance each August
and recommends the management combination that is the most likely to be the
optimal August guidance. PAMF makes this determination by predicting the chance
of occurrence of each invasion state following the current management actions.
In order to receive MCFG, a participant must already be following one of the
standard 16 PAMF [management combinations](#management-combinations). See the
[PAMF Participant Guide](https://bugwoodcloud.org/pamf/resources/PAMFParticipantGuideV5.0.pdf) for
more information about how MCFG is implemented in the PAMF program. R scripts
used to create MCFG are in the folder
[src/forecast-guidance/](src/forecast-guidance/); visit the [PAMF Model
Schematic](model-schematic.md) to see how these scripts interact.

## Model Schematic

View the [PAMF Model Schematic](model-schematic.md) to see how all the R scripts 
that make up the PAMF Model interact with one another. The PAMF Model git
repository also contains a number of CSV files necessary for running and/or
testing the model. Metadata for these files can be found in
[Table_metadata.csv](user-guide/Table_metadata.csv), with additional metadata
found in the [PAMF data release](https://doi.org/10.5066/P92NZCYL). Descriptions
of the columns in "Table_metadata.csv" are found in the 
[user-guide folder's README file](user-guide/README.md). Note that some of the CSV files in this
repository can also be found in the PAMF data release, and are retained in this
git repository as convenience copies.

## Phase-date Decisions  

View the [Phase-date decisions schematic](phase-date-decisions.md) to see how 
the decisions are made in ["**phase-date-agreement.R**"](src/construct-datpaks/phase-date-agreement.R). 
These decisions determine which [management phase](#management-combinations) a 
management report falls into based on the report's quality, reported date(s), 
management action, and other information.  

## Base Runs  

Visit [PAMF Model Base Runs](base-runs.md) to see an explanation of what base 
runs are, how they work, if you need to run them, how to run them, and how to 
edit the code to incorporate more base runs down the road.  

## References  
Chadès, I., G. Chapron, M.-J. Cros, F. Garcia, and R. Sabbadin. 2014. 
MDPtoolbox: a multi-platform toolbox to solve stochastic dynamic programming problems. Ecography 37:916-920. 
