
## ---- 2018 (base version, generated in 2021) ---------------------------------

options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2018/enrollFULL-2018-09-19.csv")
enroll <- read.csv("./database-downloads/2018/enroll-2018-09-19.csv")
monitor <- read.csv("./database-downloads/2018/monitor-2018-09-19.csv")
manage <- read.csv("./database-downloads/2018/manage-2018-09-19.csv")
mndates <- read.csv("./database-downloads/2018/managedate-2018-09-19.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2018
CYCLE <- c(2017, 2018)
REPORTBEGIN <- as.Date("2017-08-01")
REPORTEND <- as.Date("2018-09-19")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)

man_issues <- read.csv("./model-runs/base runs used in 2022/2022-08-22-13.57.38 BASE 2018/manage_issues.csv")
mon_issues <- read.csv("./model-runs/base runs used in 2022/2022-08-22-13.57.38 BASE 2018/monitor_issues.csv")

# datpak        = read.csv("./model-runs/base runs used in 2022/2022-08-22-13.57.38 BASE 2018/datpak.csv")
# datpak_issues = read.csv("./model-runs/base runs used in 2022/2022-08-22-13.57.38 BASE 2018/datpak_issues.csv")

## ---- 2019 (base version, generated in 2021) ---------------------------------

options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2019/enrollFULL-2019-08-13.csv")
monitor <- read.csv("./database-downloads/2019/monitor-2019-08-13.csv")
manage <- read.csv("./database-downloads/2019/manage-2019-08-13.csv")
mndates <- read.csv("./database-downloads/2019/managedate-2019-08-13.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2019
CYCLE <- c(2018, 2019)
REPORTBEGIN <- as.Date("2018-09-19")
REPORTEND <- as.Date("2019-08-13")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)

man_issues <- read.csv("./model-runs/2021-08-25-16.20.40 base 2019/manage_issues.csv")
mon_issues <- read.csv("./model-runs/2021-08-25-16.20.40 base 2019/monitor_issues.csv")

# datpak        = read.csv("./model-runs/2021-08-25-16.20.40 base 2019/datpak.csv")
# datpak_issues = read.csv("./model-runs/2021-08-25-16.20.40 base 2019/datpak_issues.csv")


## ---- 2020 (OFFICIAL, generated 2020) ----------------------------------------
options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2020/enroll-2020-08-11.csv")
monitor <- read.csv("./database-downloads/2020/monitor-2020-08-11.csv")
manage <- read.csv("./database-downloads/2020/manage-2020-08-11.csv")
mndates <- read.csv("./database-downloads/2020/managedate-2020-08-11.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2020
CYCLE <- c(2019, 2020)
REPORTBEGIN <- as.Date("2019-08-13")
REPORTEND <- as.Date("2020-08-11")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)

man_issues <- read.csv("./model-runs/2020-09-14-15.38.45 OFFICIAL 2020/manage_issues.csv")
mon_issues <- read.csv("./model-runs/2020-09-14-15.38.45 OFFICIAL 2020/monitor_issues.csv")

# datpak        = read.csv("./model-runs/2020-09-10-10.19.58 OFFICIAL 2020/datpak.csv")
# datpak_issues = read.csv("./model-runs/2020-09-10-10.19.58 OFFICIAL 2020/datpak_issues.csv")


# ---- 2021-08-11 data pull ----------------------------------------------------
options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2021/enroll-2021-08-11.csv")
monitor <- read.csv("./database-downloads/2021/monitor-2021-08-11.csv")
manage <- read.csv("./database-downloads/2021/manage-2021-08-11.csv")
mndates <- read.csv("./database-downloads/2021/managedate-2021-08-11.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2021
CYCLE <- c(2020, 2021)
REPORTBEGIN <- as.Date("2020-08-11")
REPORTEND <- as.Date("2021-08-11")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)


# ---- 2021-08-20 data pull ----------------------------------------------------
options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2021/enroll-2021-08-20.csv")
monitor <- read.csv("./database-downloads/2021/monitor-2021-08-20.csv")
manage <- read.csv("./database-downloads/2021/manage-2021-08-20.csv")
mndates <- read.csv("./database-downloads/2021/managedate-2021-08-20.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2021
CYCLE <- c(2020, 2021)
REPORTBEGIN <- as.Date("2020-08-11")
REPORTEND <- as.Date("2021-08-20")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)

man_issues <- read.csv("./model-runs/2021-08-20-15.21.40 new pull 08-20/manage_issues.csv")
mon_issues <- read.csv("./model-runs/2021-08-20-15.21.40 new pull 08-20/monitor_issues.csv")

datpak <- read.csv("./model-runs/2021-08-20-15.21.40 new pull 08-20/datpak.csv")
datpak_issues <- read.csv("./model-runs/2021-08-20-15.21.40 new pull 08-20/datpak_issues.csv")

transitions <- read.csv("./model-runs/2021-08-20-15.21.40 new pull 08-20/transition_matrices.csv")
pc_matrix <- read.csv("./model-runs/2021-08-20-15.21.40 new pull 08-20/partcontrol_matrices.csv")
policies <- read.csv("./model-runs/2021-08-20-15.21.40 new pull 08-20/policies.csv")

# 2022 -------------------------------------------------------------------------
options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2022/enroll-2022-08-17.csv")
monitor <- read.csv("./database-downloads/2022/monitor-2022-08-17.csv")
manage <- read.csv("./database-downloads/2022/manage-2022-08-17.csv")
mndates <- read.csv("./database-downloads/2022/managedate-2022-08-17.csv")

COST_CONSTS <- read.csv("./cost-constants/cost_constants_v2_2022.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2022
CYCLE <- c(2021, 2022)
REPORTBEGIN <- as.Date("2021-08-20")
REPORTEND <- as.Date("2022-08-17")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)

man_issues <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/manage_issues.csv")
mon_issues <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/monitor_issues.csv")

datpak <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/datpak.csv")
datpak_issues <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/datpak_issues.csv")

transitions <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/transition_matrices.csv")
pc_matrix <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/partcontrol_matrices.csv")
policies <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/policies.csv")

# 2024 -------------------------------------------------------------------------
options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2024/enroll-2024-08-21.csv")
monitor <- read.csv("./database-downloads/2024/monitor-2024-08-21.csv")
manage <- read.csv("./database-downloads/2024/manage-2024-08-21.csv")
mndates <- read.csv("./database-downloads/2024/managedate-2024-08-21.csv")

COST_CONSTS <- read.csv("./cost-constants/cost_constants_2023.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2024
CYCLE <- c(2023, 2024)
REPORTBEGIN <- as.Date("2023-08-15")
REPORTEND <- as.Date("2024-08-21")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)

model <- "2024-08-21-19.32.46 OFFICIAL 2024"
man_issues <- read.csv(paste0("./model-runs/",model,"/manage_issues.csv"))
mon_issues <- read.csv(paste0("./model-runs/",model,"/monitor_issues.csv"))

datpak <- read.csv(paste0("./model-runs/",model,"/datpak.csv"))
datpak_issues <- read.csv(paste0("./model-runs/",model,"/datpak_issues.csv"))

transitions <- read.csv(paste0("./model-runs/",model,"/transition_matrices.csv"))
pc_matrix <- read.csv(paste0("./model-runs/",model,"/partcontrol_matrices.csv"))
policies <- read.csv(paste0("./model-runs/",model,"/policies.csv"))

# 2025 -------------------------------------------------------------------------
options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2025/enroll-2025-08-20.csv")
monitor <- read.csv("./database-downloads/2025/monitor-2025-08-20.csv")
manage <- read.csv("./database-downloads/2025/manage-2025-08-20.csv")
mndates <- read.csv("./database-downloads/2025/managedate-2025-08-20.csv")

COST_CONSTS <- read.csv("./cost-constants/cost_constants_2025.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2025
CYCLE <- c(2024, 2025)
REPORTBEGIN <- as.Date("2024-08-21")
REPORTEND <- as.Date("2025-08-20")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)

model <- "2025-08-22-16.40.47 OFFICIAL 2025"
man_issues <- read.csv(paste0("./model-runs/",model,"/manage_issues.csv"))
mon_issues <- read.csv(paste0("./model-runs/",model,"/monitor_issues.csv"))

datpak <- read.csv(paste0("./model-runs/",model,"/datpak.csv"))
datpak_issues <- read.csv(paste0("./model-runs/",model,"/datpak_issues.csv"))

transitions <- read.csv(paste0("./model-runs/",model,"/transition_matrices.csv"))
pc_matrix <- read.csv(paste0("./model-runs/",model,"/partcontrol_matrices.csv"))
policies <- read.csv(paste0("./model-runs/",model,"/policies.csv"))


# MCFG -------------------------------------------------------------------------
source("./src/forecast-guidance/midcycle-functions.R")

options(stringsAsFactors = FALSE)
enroll <- read.csv("./database-downloads/2023/enroll-2023-01-17.csv")
monitor <- read.csv("./database-downloads/2023/monitor-2023-01-17.csv")
manage <- read.csv("./database-downloads/2023/manage-2023-01-17.csv")
mndates <- read.csv("./database-downloads/2023/managedate-2023-01-17.csv")
midcycle <- read.csv("./database-downloads/2023/midcycle-2023-01-17.csv")

source("./src/global-constants.R")
source("./src/format-functions.R")
CYCLEEND <<- 2023
CYCLE <- c(2022, 2023)
REPORTBEGIN <- as.Date("2020-08-11")
REPORTEND <- as.Date("2023-01-17")
PREVCYCLE <- 2022
current_cycle_cutoff <- as.Date("2022-08-01")

enroll_data <- formatEnroll(enroll, CYCLEEND)
mon_data <- formatMonitor(monitor, CYCLEEND)
man_data <- formatManage(manage, mndates, CYCLEEND)
midcycle <- formatMidcycle(midcycle, CYCLEEND)

man_issues <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/manage_issues.csv")
mon_issues <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/monitor_issues.csv")

datpak <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/datpak.csv")
datpak_issues <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/datpak_issues.csv")

transitions <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/transition_matrices.csv")
pc_matrix <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/partcontrol_matrices.csv")
policies <- read.csv("./model-runs/2022-08-23-10.16.33 OFFICIAL 2022/policies.csv")

action_restrictions =  read.csv("./src/policy_definitions2018-07-31.csv")

## Read model outputs from the previous run & trim to previous run's cycle
datpak <- datpak[datpak$cycle_end == PREVCYCLE, ]
mon_issues <- mon_issues[mon_issues$cycle_end == PREVCYCLE, ]
transitions <- transitions[transitions$cycle_used == PREVCYCLE, ]
policies <- policies[policies$cycle_end == PREVCYCLE &
                       policies$optimal == 1, ]


midcycle <- midcycle[midcycle$dateentered > current_cycle_cutoff, ]

managetest <- manage[manage$munitid %in% midcycle$munitid, 
                     c("id","munitid", "managementdate", "dateentered", 
                       "phase", "treatmethod", "cycleyear" )]


manage <- manage[manage$dateentered > current_cycle_cutoff, ]

## Check for duplicate monitoring reports --------------------------------------
for (id in unique(mon_data$munitid)) {
  for (y in CYCLE) {
    nr <- nrow(mon_issues[mon_issues$munitid == id & mon_issues$monitor_year == y, ])
    if (nr > 1) {
      message(paste("MU:", id, "year:", y))
      message(nr)
    }
  }
}
