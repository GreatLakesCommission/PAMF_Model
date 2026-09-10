# Purpose: Define functions for estimating costs of different treatments.
#   This will be used in the optimization portion of the PAMF guidance model.

# ---------- Cost Function Definitions ------------

## ---- Sub-functions ----

areaProportion <- function(treat_area, MU_area, total_area) {
  # This function calculates the proportion of the treated area composed of the
  # MU. 
  #
  # INPUT
  # treat_area : whether or not reported costs are for the exact area of the MU
  #              or total area treated; 1 = exact area, 2 = total area (numeric)
  # MU_area    : area of the management unit (numeric)
  # total_area : the total area treated (larger or smaller than the management
  #              unit) (numeric)
  #
  # OUTPUT
  # The returned value is an integer
  #
  # ASSUMPTIONS
  # * treat_area assumed to be non "NA"
  #   Both total_area and MU_area are some sort of numerical variable that can
  #   be used in mathematical equations and are non "NA". total_area is assumed
  #   to be non-zero. Each acre contains the same amount of Phragmites and the
  #   work is evenly distributed across the entire area treated.
  #
  # DESCRIPTION
  # Managers are given the option to report cost data for areas outside of the
  # management unit if they treated them on the same day. The purpose of this
  # function is to find the proportion of the area they treated that falls
  # within the management unit. For example, if they treated 10 acres of
  # Phragmites but the MU is only 5 acres the area_proportion would be 5/10 =
  # 0.5 The subsequent cost calculations will be multiplied by 0.5
  # Used for herbicide application: 
  # Managers are given the option to report herbicide volume data for areas
  # outside of the management unit if they treated them on the same day. The
  # purpose of this function is to find the proportion of the area they treated
  # that falls within the management unit. For example, if they treated 10 acres
  # of Phragmites with herbicide but the MU is only 5 acres the
  # area_proportion_herb would be 5/10 = 0.5 The subsequent herbicide volume
  # cost calculations will be multiplied by 0.5
  
  # check assumptions
  # if(is.na(treat_area)){print("treat_area is NA - need value of 1 or 2 (areaProportion function)")}
  # if(treat_area == 2 & is.na(MU_area)){print("MU-area is NA - May have inaccurate value (areaProportion function)")}
  # if(treat_area == 2 & is.na(total_area)){print("total-area is NA - May have inaccurate value (areaProportion function)")}

  # function code
  if (!is.na(treat_area)) {
    if (treat_area == 2) {
      area_proportion <- MU_area / total_area
    } else {
      if (treat_area == 1) {
        area_proportion <- 1
      } else {
        warning("areaProportion: treat_area does not equal 1 or 2 - ensure that all variables are entered properly")
        area_proportion <- NA
      }
    }
  } else {
    warning("areaProportion: treat_area does not equal 1 or 2 - ensure that all variables are entered properly")
    area_proportion <- NA
  }
  return(area_proportion)
} # end areaProportion


herbicideProductCost <- function(cost_product, concentration, volume_mix) {
  # This function estimates the cost of the herbicide product used in the
  # treatment
  #
  # INPUT
  # cost_product  : the pre-determined cost of the given herbicide (numeric)
  # concentration : The participant-entered percent concentration of the 
  #                 herbicide product used (numeric). Note that in model 
  #                 versions prior to 2023 the concentration was assumed to 
  #                 be a proportion, but participants actually submit a 
  #                 percentage. This has been accounted for here by converting
  #                 percentages into proportions.
  # volume_mix    : The participant-entered Volume of the mixture used to treat
  #                 Phragmites (numeric)
  #
  #
  # OUTPUT
  # Returns the estimated cost of using a particular herbicide product to treat
  # Phragmites (numeric)
  #
  # ASSUMPTIONS
  # * All variables are assigned based on the management action used. The
  #   concentration and volume_mix are entered by the participant, while
  #   cost_product is a pre-determined global constant. Variables are assumed to
  #   be non-zero when appropriate and non "NA".
  # * Where concentration and/or volume_mix is NA, assume that the participant
  #   didn't fill out these fields because they didn't apply herbicide (e.g. in
  #   cases where this function is used to calculate the cost of 'added'
  #   herbicide when only one herbicide was used) OR they entered herbicide
  #   info as volume (quarts) of herbicide per acre
  # * In these same cases, cost_product is NA because no added herbicide has
  #   been designated. this is common, so we'll set cost_product to 0 when it's
  #   NA
  #
  # DESCRIPTION
  # Based on the cost of the brand, concentration of the product, and the volume
  # used this function calculates the cost of using a given herbicide product to
  # complete an herbicide management action. It will be used in the broader
  # herbicide costs function.
  ##

  # Check for missing values
  if (is.na(cost_product)) {
    warning("herbicideProductCost: Cost of product is NA - assign value at beginning of document")
    cost_product <- 0
  }
  if (is.na(concentration)) {
    concentration <- 0
  }
  if (is.na(volume_mix)) {
    volume_mix <- 0
  }

  # function code
  cost_herbiciding <- cost_product * (concentration/100) * volume_mix

  return(cost_herbiciding)
} # End of herbicideProductCost

herbicideProductCostAcre <- function(cost_product, volume_acre) {
  # This function estimates the cost of the herbicide product used in the
  # treatment if volume of herbicide / acre was submitted
  #
  # INPUT
  # cost_product  : the pre-determined cost of the given herbicide (numeric)
  # volume_acre   : The participant-entered volume (quarts) of the mixture used 
  #                 per acre to treat Phragmites (numeric)
  #
  # OUTPUT
  # Returns the estimated cost of using a particular herbicide product to treat
  # Phragmites per acre (numeric)
  #
  # ASSUMPTIONS
  # * All variables are assigned based on the management action used. The
  #   volume_acre is entered by the participant, while
  #   cost_product is a pre-determined global constant. Variables are assumed to
  #   be non-zero when appropriate and non "NA".
  # * Where volume_acre is NA, assume that the participant
  #   didn't fill out these fields because they didn't apply herbicide (e.g. in
  #   cases where this function is used to calculate the cost of 'added'
  #   herbicide when only one herbicide was used) OR because they submitted
  #   herbicide information in the form of concentratio and volume_mix
  # * In these same cases, cost_product is NA because no added herbicide has
  #   been designated. This is common, so we'll set cost_product to 0 when it's
  #   NA
  #
  # DESCRIPTION
  # Based on the cost of the brand and the volume (quarts)/acre used this 
  # function calculates the cost of using a given herbicide product to
  # complete an herbicide management action. It will be used in the broader
  # herbicide costs function.
  ##
  
  # Check for missing values
  if (is.na(cost_product)) {
    warning("herbicideProductCost: Cost of product is NA - assign value at beginning of document")
    cost_product <- 0
  }
  if (is.na(volume_acre)) {
    volume_acre <- 0
  }
  # function code - convert volume from quarts of herbicide to gallons 
  # 1 quart = 0.25 gallons  
  cost_herbiciding_acre <- cost_product * volume_acre * 0.25 
  
  return(cost_herbiciding_acre)
} # End of herbicideProductCostAcre

hourlyEquipmentCost <- function(cost, equipment_hours) {
  # Calculates the cost of the equipment used to perform a management action
  #
  # INPUT
  # cost            : the cost of (manager-determined rental or pre-determined
  #                   operation) for a given type of equipment per hour USD/hour
  #                   (numeric)
  # equipment_hours : The number of hours the equipment was used (numeric)
  #
  # OUTPUT
  # The cost of using a given type of equipment for a given number of hours
  #
  # ASSUMPTIONS
  # * This function assumes that the arguments have been sorted by management
  #   action already. All variables are assumed to be non-missing numerical
  #   variables.
  #
  # DESCRIPTION
  # Calculates the cost of using equipment by multiplying cost(USD/hour) by hours
  # of equipment use (hours).
  ##

  # Checking for missing values
  if (is.na(cost)) {
    warning("equipmentCost: Cost is NA - Need numerical value")
  }
  if (is.na(equipment_hours)) {
    warning("equipmentCost: Equipment hours is NA - Setting to zero")
    equipment_hours <- 0
  }

  # Function Code
  cost_equipment <- cost * equipment_hours

  return(cost_equipment)
} # end equipmentCost

equipmentRentalCost <- function(cost_equip_rental) {
  # Determines if the rentcost variable is missing, in which case rent_cost = 0
  #
  # INPUT
  # cost_equip_rental : the total, participant-reported cost of renting equipment
  #                     for the entire management action (numeric)
  #
  # OUTPUT
  # The cost total cost of rental (numeric)
  #
  # ASSUMPTIONS
  # This function assumes that if the rentcost variable is missing that indicates
  # that equipment was not rented and therefore the cost of rental = 0. No extra
  # costs are added for owning the equipment because ownership estimates would
  # be too complicated for these functions.
  #
  # DESCRIPTION
  # Reports the total cost of renting equipment as entered by the participant
  ##

  # Check if the value is NA
  cost_rental <- ifelse(is.na(cost_equip_rental), 0, cost_equip_rental)

  return(cost_rental)
}


fuelCost <- function(min_gas, max_gas, cost_gas = cost.gas, # gas variables
                     min_diesel, max_diesel, cost_diesel = cost.diesel, # diesel variables
                     min_jet, max_jet, cost_jet = cost.jetfuel, # jet variables
                     min_avgas, max_avgas, cost_avgas = cost.avgas) { # av variables
  # This function estimates the cost of fuel used to complete a management action
  #
  # INPUT
  # min_gas     : minimum gas volume used by participant (participant entered)
  #               (numeric)
  # max_gas     : maximum gas used by participant (participant entered) (numeric)
  # cost_gas    : The pre-determined cost of gas (numeric)
  # min_diesel  : minimum diesel volume used by participant (participant entered)
  #               (numeric)
  # max_diesel  : maximum diesel used by participant (participant entered)
  #                (numeric)
  # cost_diesel : The pre-determined cost of diesel (numeric)
  # min_jet     : minimum jet fuel volume used by participant (participant
  #               entered)(numeric)
  # max_jet     : maximum jet fuel used by participant (participant entered)
  #             : (numeric)
  # cost_jet    : The pre-determined cost of jet fuel (numeric)
  # min_avgas   : minimum avgas volume used by participant (participant entered)
  #               (numeric)
  # max_avgas   : maximum avgas used by participant (participant entered)
  #               (numeric)
  # cost_avgas  : The pre-determined cost of avgas (numeric)
  #
  # OUTPUT
  # Cost in USD of using the specified amount of fuel (numeric)
  #
  # ASSUMPTIONS
  # * Both of the values for min and max fuel volumes are entered properly
  #   (ie non NA) The arguments are pre-sorted to correspond with the
  #   appropriate management action. If the fuel was not used, the entry is 0
  #   for both min and max of that fuel type, since the min and max variables
  #   aren't initialized to 0. If the min or max for a given fuel type is NA we
  #   assume that none of that fuel was used and the value is set to 0.
  #
  # DESCRIPTION
  # The median of the min and max fuel consumption is used to estimate
  # the total cost of using a given type of fuel. This value is multiplied by the
  # cost of that fuel type (a pre-determined global constant) to obtain the
  # cost in USD of the specified volume of the given fuel type. The totals for
  # each fuel type are then summed to obtain the total estimated cost of using
  # fuel for a given management action.
  ##

  # Check for missing variable assignments
  if (is.na(cost_gas)) {
    warning("fuelCost: cost.gas is NA - need a numerical value, assign value at beginning of document")
  }
  if (is.na(cost_diesel)) {
    warning("fuelCost: cost.diesel is NA - need a numerical value, assign value at beginning of document")
  }
  if (is.na(cost_jet)) {
    warning("fuelCost: cost.jetfuel is NA - need a numerical value, assign value at beginning of document")
  }
  if (is.na(cost_avgas)) {
    warning("fuelCost:cost.avgas is NA - need a numerical value, assign value at beginning of document")
  }

  # Set fuel type volumes to 0 if they are NA
  min_gas <- ifelse(is.na(min_gas), 0, min_gas)
  max_gas <- ifelse(is.na(max_gas), 0, max_gas)
  min_diesel <- ifelse(is.na(min_diesel), 0, min_diesel)
  max_diesel <- ifelse(is.na(max_diesel), 0, max_diesel)
  min_jet <- ifelse(is.na(min_jet), 0, min_jet)
  max_jet <- ifelse(is.na(max_jet), 0, max_jet)
  min_avgas <- ifelse(is.na(min_avgas), 0, min_avgas)
  max_avgas <- ifelse(is.na(max_avgas), 0, max_avgas)

  # find median fuel volume
  volume_gas <- median(c(min_gas, max_gas))
  volume_diesel <- median(c(min_diesel, max_diesel))
  volume_jet <- median(c(min_jet, max_jet))
  volume_avgas <- median(c(min_avgas, max_avgas))

  # Function Code
  cost_fuel <- (volume_gas * cost_gas) +
    (volume_diesel * cost_diesel) +
    (volume_jet * cost_jet) +
    (volume_avgas * cost_avgas)

  return(cost_fuel)
} # end fuelCost

laborCost <- function(hours_student, hours_volunteer, hours_seasonal_employee,
                      hours_fulltime_employee, cost_student = cost.student,
                      cost_volunteer = cost.volunteer,
                      cost_seasonal_employee = cost.seasonal.employee,
                      cost_fulltime_employee = cost.fulltime.employee) {
  # Estimates the total labor costs for participants.
  #
  # INPUT
  # hours_student           : number of hours worked by students (numeric)
  # hours_volunteer         : number of hours worked by volunteers (numeric)
  # hours_seasonal_employee : number of hours worked by seasonal employees
  #                           (numeric)
  # hours_fulltime_employee : number of hours worked by full-time employees
  #                           (numeric)
  # cost_student            : the pre-determined cost of a student (numeric)
  # cost_volunteer          : the pre-determined cost of a volunteer (numeric)
  # cost_seasonal_employee  : the pre-determined cost of a seasonal employee
  #                           (numeric)
  # cost_fulltime_employee  : the pre-determined cost of a a fulltime employee
  #                           (numeric)
  #
  # OUTPUT
  # This function returns the total cost of labor used to complete a management
  # action in USD. (numeric)
  #
  # ASSUMPTIONS
  # * This function does not consider the additional hours of "other" workers
  #   and the associated costs because there is no way to estimate the costs of
  #   "other" workers. This function assumes that a value of NA indicates 0
  #    hours of labor for that particular labor category.
  #
  # DESCRIPTION
  # This function estimates the total cost of labor by summing the cost of each
  # labor type used to complete a management action. If an hour variable is NA,
  # it is assigned the value of zero and if not it maintains its current value.
  # This allows for the summation of all labor types.
  ##

  # Check for missing variable assignment
  if (is.na(cost_volunteer)) {
    warning("laborCost: cost.volunteer is NA - need a numerical value, assign value at beginning of document")
  }
  if (is.na(cost_student)) {
    warning("laborCost: cost.student is NA - need a numerical value, assign value at beginning of document")
  }
  if (is.na(cost_seasonal_employee)) {
    warning("laborCost: cost.seasonal.employee is NA - need a numerical value, assign value at beginning of document")
  }
  if (is.na(cost_fulltime_employee)) {
    warning("laborCost: cost.fulltime.employee is NA - need a numerical value, assign value at beginning of document")
  }

  # Set labor hours to 0 if they are NA
  hours_student <- ifelse(is.na(hours_student), 0, hours_student)
  hours_volunteer <- ifelse(is.na(hours_volunteer), 0, hours_volunteer)
  hours_seasonal_employee <- ifelse(is.na(hours_seasonal_employee), 0,
    hours_seasonal_employee
  )
  hours_fulltime_employee <- ifelse(is.na(hours_fulltime_employee), 0,
    hours_fulltime_employee
  )

  # Cost calculation
  cost_labor <- (cost_student * hours_student) +
    (cost_volunteer * hours_volunteer) +
    (cost_seasonal_employee * hours_seasonal_employee) +
    (cost_fulltime_employee * hours_fulltime_employee)

  return(cost_labor)
} # end laborCost


electricalPumpCost <- function(pump_hours, min_watt, max_watt,
                               cost_electricity = cost.electricity) {
  # This estimates the electrical costs for using an electric pump.
  #
  # INPUT
  # pump_hours : the number of hours the pumps were used to create a flood
  #              participant-entered (numeric)
  # min_watt   : the minimum wattage used by the pump (numeric)
  # max_watt   : the maximum wattage used by the pump (numeric)
  # cost_electricity : the pre-determined cost of using electricity (numeric)
  #
  # OUTPUT
  # The cost in USD of electricity used to pump water during a flood. (numeric)
  #
  # ASSUMPTIONS
  # * Where pump_hours is NA, the participant did not fill out the field because
  #   the did not run an electrical pump (pump_hours is really 0)
  #
  #
  # DESCRIPTION
  # Estimates the cost of running an electric pump for completing the flood
  # management action by multiplying the cost of electricity (pre-determined) by
  # the number of hours the pump was in use.
  ##

  # Check for missing cost constant
  if (is.na(cost_electricity)) {
    print("cost.electricity is NA - need a numerical value, assign value at beginning of document (electricalPumpCost function)")
  }

  if (anyNA(c(pump_hours, min_watt, max_watt))) {
    # web hub fields are empty becase this management report is for a different
    # action
    return(0)
  } else {
    # Find median wattage
    total_wattage <- median(c(min_watt, max_watt))

    cost_electrical_pump <- cost_electricity * pump_hours * total_wattage
    return(cost_electrical_pump)
  }
} # end electricalPumpCost


## ------ Outer Functions -----

costOfContractor <- function(cost_service, treat_area, MU_area, total_area) {
  # Calculates the cost of hiring a contractor to perform the management action
  #
  # INPUT
  # cost_service : The total amount charged by the contractor (numeric)
  # treat_area   : whether or not reported costs are for the exact area of the MU
  #                or total area treated; 0 = exact area, 1 = total area
  #                (numeric)
  # MU_area      : area of the management unit (numeric)
  # total_area : the total area of the management unit (numeric)
  #
  # OUTPUT
  # The estimated cost of the contractor for the area within the MU. (numeric)
  #
  # ASSUMPTIONS
  # * The manager hired a contractor and reported the costs.cost_service
  #   is non-zero.
  #
  # DESCRIPTION
  # Based on the area proportion, this function calculates the cost of hiring
  # a contractor to carry out the management action. The cost is found by
  # multiplying the total cost of the contractor by the proportion of total area
  # located within the MU.
  ##

  # Check for missing variables
  if (is.na(cost_service)) {
    warning("costOfContractor: cost_service is NA - Setting to zero")
    cost_service <- 0
  }

  # Equation code
  cost_contractor <- cost_service * areaProportion(treat_area, MU_area, total_area)

  return(cost_contractor)
} # end costOfContractor

costOfHerbicide <- function(cost_product, concentration = 0, volume_mix = 0,
                            volume_acre = 0, # Herbicide
                            cost_add_product = 0, concentration_add = 0,
                            volume_add_mix = 0, volume_acre_add = 0, # for Glyphplus
                            surf_concentration = 0, volume_surf_mix = 0,
                            volume_acre_surf = 0, cost_surfactant = cost.surfactant, # surf
                            min_gas, max_gas, cost_gas = cost.gas, # Gas
                            min_diesel, max_diesel, cost_diesel = cost.diesel, # Diesel
                            min_jet, max_jet, cost_jet = cost.jetfuel, # Jetfuel
                            min_avgas, max_avgas, cost_avgas = cost.avgas, # avgas
                            cost_equip_rental, # renting equipment (rentcost in dataset)
                            hours_student, hours_volunteer, hours_seasonal_employee,
                            hours_fulltime_employee, # labor
                            treat_area, MU_area, total_area, # area proportion
                            treat_area_herb, total_area_herb, # herbicide area proportion
                            cost_student = cost.student, # labor costs initialized
                            cost_volunteer = cost.volunteer,
                            cost_seasonal_employee = cost.seasonal.employee,
                            cost_fulltime_employee = cost.fulltime.employee) {
  # Estimates the total cost of using an herbicide treatment in a management unit
  #
  # INPUT
  # cost_product      : the pre-determined cost of the given herbicide (numeric)
  # concentration     : The participant-entered concentration of the herbicide
  #                     product used (numeric)
  # volume_mix        : The participant-entered Volume of the mixture used to
  #                     treat Phragmites (numeric)
  # volume_acre       : The participant-entered volume (quarts) of the herbicide
  #                     used per acre to treat Phragmites (numeric)
  # cost_add_product  : the pre-determined cost of the additional product used
  #                     in the glyph-plus management action (numeric)
  # concentration_add : The participant-entered concentration of the additional
  #                     herbicide product used for the glyph-plus management
  #                     action (numeric)
  # volume_add_mix    : The participant-entered Volume of the mixture used to
  #                     treat Phragmites. This is initialized to 0 in case
  #                     glyph-plus is not used. If it is used, glyphplusvolume
  #                     is used for both volume arguments (numeric)
  # volume_acre_add   : The participant-entered volume (quarts) of the added
  #                     herbicide product used per acre to treat Phragmites
  #                     (numeric)
  # min_gas           : minimum gas volume used by participant (participant
  #                     entered) (numeric)
  # max_gas           : maximum gas used by participant (participant entered)
  #                     (numeric)
  # cost_gas          : The pre-determined cost of gas (numeric)
  # min_diesel        : minimum diesel volume used by participant
  #                     (participant entered) (numeric)
  # max_diesel        : maximum diesel used by participant (participant entered)
  #                     (numeric)
  # cost_diesel       : The pre-determined cost of diesel (numeric)
  # min_jet           : minimum jet fuel volume used by participant (participant
  #                     entered) (numeric)
  # max_jet           : maximum jet fuel used by participant (participant
  #                     entered) (numeric)
  # cost_jet          : The pre-determined cost of jet fuel (numeric)
  # min_avgas         : minimum avgas volume used by participant (participant
  #                     entered) (numeric)
  # max_avgas         : maximum avgas used by participant (participant entered)
  #                     (numeric)
  # cost_avgas        : The pre-determined cost of avgas (numeric)
  # cost_equipment    : the cost of (manager-determined rental or pre-determined
  #                     operation) for a given type of equipment per
  #                     hour USD/hour (numeric)
  # equipment_hours   : The number of hours the equipment was used for (numeric)
  # hours_student     : number of hours worked by students (numeric)
  # hours_volunteer   : number of hours worked by volunteers (numeric)
  # hours_seasonal_employee : number of hours worked by seasonal employees
  #                           (numeric)
  # hours_fulltime_employee : number of hours worked by full-time employees
  #                           (numeric)
  # cost_surfactant : The pre-determined cost of surfactant (numeric)
  # treat_area              : whether or not reported costs are for the exact
  #                           area of the MU or total area treated; 1 = exact area,
  #                           2 = total area (numeric)
  # MU_area                 : area of the management unit (numeric)
  # treat_area_herb         : whether or not reported herbicide volumes are for
  #                           the exact area of the MU or total area treated;
  #                           1 = exact area, 2 = total area (numeric)
  # total_area              : the total area managed (larger or smaller than
  #                           the management unit) (numeric)
  # total_area_herb         : the total area managed with herbicide (larger or
  #                           smaller than the management unit) (numeric)
  # surf_concentration : the participant-entered concentration of the surfactant
  #                      in the mix (numeric)
  #
  # OUTPUT
  # The total cost in USD of performing an herbicide management action (numeric)
  #
  # ASSUMPTIONS
  # * All variable inputs are properly sorted to correspond with the correct
  #   management action. This function contains all the assumptions associated
  #   with all sub-functions specified above. The number of applications is
  #   assumed to be non-zero.
  #
  # DESCRIPTION
  # This function uses the sub-functions
  #   * areaProportion()
  #   * herbicideProductCostAcre()
  #   * equipmentCost()
  #   * herbicideProductCost()
  #   * fuelCost()
  #   * laborCost()
  # to estimate the total cost of using an herbicide management action. This
  # function sums all of the individual costs and then multiplies this quantity
  # by the area-proportion and the number of applications of the treatment.
  ##

  cost_herbiciding <- (

    # Herbicide product cost
    (suppressWarnings(herbicideProductCost(
      cost_product, concentration, volume_mix
    )) * areaProportion(treat_area_herb, MU_area, total_area_herb)
    ) +

      # Additional herbicide product cost (gylphosate+)
      (suppressWarnings(herbicideProductCost(
        cost_add_product, concentration_add, volume_add_mix
      )) * areaProportion(treat_area_herb, MU_area, total_area_herb)
      ) +

      # Surfactant product cost
      (suppressWarnings(herbicideProductCost(
        cost_surfactant, surf_concentration, volume_surf_mix
      )) * areaProportion(treat_area_herb, MU_area, total_area_herb)
      ) +

      # Herbicide product cost PER ACRE
      suppressWarnings(herbicideProductCostAcre(
        cost_product, volume_acre
      ) * MU_area) +

      # Additional herbicide product cost (gylphosate+) PER ACRE
      suppressWarnings(herbicideProductCostAcre(
        cost_add_product, volume_acre_add
      ) * MU_area) +

      # Surfactant product cost PER ACRE
      suppressWarnings(herbicideProductCostAcre(
        cost_surfactant, volume_acre_surf
      ) * MU_area)) +

    ((fuelCost( # OTHER COSTS
      min_gas, max_gas, cost_gas,
      min_diesel, max_diesel, cost_diesel,
      min_jet, max_jet, cost_jet,
      min_avgas, max_avgas, cost_avgas
    ) +
      equipmentRentalCost(cost_equip_rental) +
      laborCost(
        hours_student, hours_volunteer,
        hours_seasonal_employee, hours_fulltime_employee,
        cost_student, cost_volunteer,
        cost_seasonal_employee, cost_fulltime_employee
      )) *
      areaProportion(treat_area, MU_area, total_area))


  return(cost_herbiciding)
} # end costOfHerbicide

costOfBiomassWEquipment <- function(min_gas, max_gas, cost_gas = cost.gas, # Gas
                                    min_diesel, max_diesel,
                                    cost_diesel = cost.diesel, # Diesel
                                    min_jet, max_jet, cost_jet = cost.jetfuel, # Jetfuel
                                    min_avgas, max_avgas, cost_avgas = cost.avgas, # avgas
                                    cost_equip_rental, # renting equipment (rentcost in dataset)
                                    hours_student, hours_volunteer,
                                    hours_seasonal_employee,
                                    hours_fulltime_employee, # labor
                                    treat_area, MU_area, total_area, # area proportion
                                    cost_student = cost.student, # labor costs initialized
                                    cost_volunteer = cost.volunteer,
                                    cost_seasonal_employee = cost.seasonal.employee,
                                    cost_fulltime_employee = cost.fulltime.employee) {
  # This function estimates the total cost of completing a mechanical removal or
  # mechanical and leave management action with equipment.
  #
  # INPUT
  # min_gas     : minimum gas volume used by participant (participant entered)
  #               (numeric)
  # max_gas     : maximum gas used by participant (participant entered) (numeric)
  # cost_gas    : The pre-determined cost of gas (numeric)
  # min_diesel  : minimum diesel volume used by participant (participant entered)
  #               (numeric)
  # max_diesel  : maximum diesel used by participant (participant entered)
  #               (numeric)
  # cost_diesel : The pre-determined cost of diesel (numeric)
  # min_jet     : minimum jet fuel volume used by participant (participant
  #               entered) (numeric)
  # max_jet     : maximum jet fuel used by participant (participant entered)
  #               (numeric)
  # cost_jet    : The pre-determined cost of jet fuel (numeric)
  # min_avgas   : minimum avgas volume used by participant (participant entered)
  #               (numeric)
  # max_avgas   : maximum avgas used by participant (participant entered)
  #               (numeric)
  # cost_avgas  : The pre-determined cost of avgas (numeric)
  # cost_equipment  : the cost of (manager-determined rental or pre-determined
  #                   operation) for a given type of equipment per hour USD/hour
  #                   (numeric)
  # equipment_hours : The number of hours the equipment was used for (numeric)
  # hours_student   : number of hours worked by students (numeric)
  # hours_volunteer : number of hours worked by volunteers (numeric)
  # hours_seasonal_employee : number of hours worked by seasonal employees
  #                           (numeric)
  # hours_fulltime_employee : number of hours worked by full-time employees
  #                           (numeric)
  # treat_area : whether or not reported costs are for the exact area of the MU
  #              or total area treated; 0 = exact area, 1 = total area (numeric)
  # MU_area    : area of the management unit (numeric)
  # total_area : the total area of the management unit (numeric)
  #
  #
  # OUTPUT
  # The total cost of completing a mechanical biomass manipulation as a
  # management action in USD. (numeric)
  #
  # ASSUMPTIONS
  # * All variable inputs are properly sorted to correspond with the correct
  #   management action. This function contains all the assumptions associated
  #   with all sub-functions specified above. The number of applications is
  #   assumed to be non-zero.
  #
  # DESCRIPTION
  # This function covers all non-herbicide biomass manipulations with equipment:
  # cut underwater, remove biomass, pre-flood clearing, and mechanical and leave
  # when those actions are completed with fuel using equipment.It sums all of the
  # individual costs (fuel, labor, equipment) and then multiplies this quantity
  # by the area proportion and the number of applications.
  ##

  cost_biomass_manipulation <- (fuelCost(
    min_gas, max_gas, cost_gas,
    min_diesel, max_diesel, cost_diesel,
    min_jet, max_jet, cost_jet,
    min_avgas, max_avgas, cost_avgas
  ) +
    equipmentRentalCost(cost_equip_rental) +
    laborCost(
      hours_student, hours_volunteer,
      hours_seasonal_employee,
      hours_fulltime_employee, cost_student,
      cost_volunteer,
      cost_seasonal_employee, cost_fulltime_employee
    )) *
    areaProportion(treat_area, MU_area, total_area)

  return(cost_biomass_manipulation)
} # end costOfBiomassWEquipment


costOfHandRemoval <- function(hours_student, hours_volunteer,
                              hours_seasonal_employee, hours_fulltime_employee, # labor
                              treat_area, MU_area, total_area, # area proportion
                              cost_student = cost.student, # labor costs initialized
                              cost_volunteer = cost.volunteer,
                              cost_seasonal_employee = cost.seasonal.employee,
                              cost_fulltime_employee = cost.fulltime.employee) {
  # Estimates the total cost of completing a biomass manipulation by hand.
  #
  # INPUT
  # hours_student           : number of hours worked by students (numeric)
  # hours_volunteer         : number of hours worked by volunteers (numeric)
  # hours_seasonal_employee : number of hours worked by seasonal employees
  #                           (numeric)
  # hours_fulltime_employee : number of hours worked by full-time employees
  #                           (numeric)
  # treat_area              : whether or not reported costs are for the exact
  #                           area of the MU or total area treated; 0 = exact
  #                           area, 1 = total area (numeric)
  # MU_area                 : area of the management unit (numeric)
  # total_area              : the total area of the management unit (numeric)
  #
  # OUTPUT
  # The total cost in USD of completing a biomass manipulation by hand (numeric)
  #
  # ASSUMPTIONS
  # * All variable inputs are properly sorted to correspond with the correct
  #   management action. This function contains all the assumptions associated
  #   with all sub-functions specified above. The number of applications is
  #   assumed to be non-zero.
  #
  #
  # DESCRIPTION
  # This function estimates the total cost in USD of completing a biomass
  # manipulation by hand or completing a passive flood: Pre-flood clearing,
  # remove biomass, mechanical and leave (by hand), spading, passive flooding.
  # This function only considers the cost of labor as a cost component. It
  # multiplies cost of labor by the area proportion and the number of
  # applications.
  ##

  cost_hand_manipulation <- (laborCost(
    hours_student, hours_volunteer,
    hours_seasonal_employee,
    hours_fulltime_employee,
    cost_student, cost_volunteer,
    cost_seasonal_employee,
    cost_fulltime_employee
  )) *
    areaProportion(treat_area, MU_area, total_area)

  return(cost_hand_manipulation)
} # end costOfHandRemoval

costOfActiveFlood <- function(min_gas = 0, max_gas = 0, cost_gas = cost.gas, # Gas
                              min_diesel = 0, max_diesel = 0,
                              cost_diesel = cost.diesel, # Diesel
                              min_jet = 0, max_jet = 0, cost_jet = cost.jetfuel, # Jetfuel
                              min_avgas = 0, max_avgas = 0,
                              cost_avgas = cost.avgas, # avgas
                              pump_hours = 0, min_watt = 0, max_watt = 0,
                              cost_electricity = cost.electricity, # Electricity hours initialized to 0
                              hours_student, hours_volunteer,
                              hours_seasonal_employee,
                              hours_fulltime_employee, # labor
                              treat_area, MU_area, total_area, # area proportion
                              cost_student = cost.student, # labor costs initialized
                              cost_volunteer = cost.volunteer,
                              cost_seasonal_employee = cost.seasonal.employee,
                              cost_fulltime_employee = cost.fulltime.employee) {
  # Estimates the total cost of completing an active flood on a management unit
  # in USD
  #
  # INPUT
  # min_gas     : minimum gas volume used by participant (participant entered)
  #               (numeric)
  # max_gas     : maximum gas used by participant (participant entered) (numeric)
  # cost_gas    : The pre-determined cost of gas (numeric)
  # min_diesel  : minimum diesel volume used by participant (participant entered)
  #               (numeric)
  # max_diesel  : maximum diesel used by participant (participant entered)
  #               (numeric)
  # cost_diesel : The pre-determined cost of diesel (numeric)
  # min_jet     : minimum jet fuel volume used by participant (participant
  #               entered) (numeric)
  # max_jet     : maximum jet fuel used by participant (participant entered)
  #               (numeric)
  # cost_jet    : The pre-determined cost of jet fuel (numeric)
  # min_avgas   : minimum avgas volume used by participant (participant entered)
  #               (numeric)
  # max_avgas   : maximum avgas used by participant (participant entered)
  #               (numeric)
  # cost_avgas  : The pre-determined cost of avgas (numeric)
  # pump_hours  : the number of hours an electic pump was used (participant
  #               entered) (numeric)
  # min_watt    : the minimum wattage used by the pump (numeric)
  # max_watt    : the maximum wattage used by the pump (numeric)
  # hours_student           : number of hours worked by students (numeric)
  # hours_volunteer         : number of hours worked by volunteers (numeric)
  # hours_seasonal_employee : number of hours worked by seasonal employees
  #                           (numeric)
  # hours_fulltime_employee : number of hours worked by full-time employees
  #                           (numeric)
  # treat_area : whether or not reported costs are for the exact area of the MU
  #              or total area treated; 0 = exact area, 1 = total area (numeric)
  # MU_area    : area of the management unit (numeric)
  # total_area : the total area of the management unit (numeric)
  #
  # fuel volume and pump_hours initialized to 0 so that if one technique is used,
  # the other technique simply adds 0 to the total cost. For example: if a gas
  # pump was used then the fuel volume will be entered and the pump_hours remains
  # 0
  #
  # OUTPUT
  # The total cost in UDS of conducting an active flood (numeric)
  #
  # ASSUMPTIONS
  # * All variable inputs are properly sorted to correspond with the correct
  #   management action. This function contains all the assumptions associated
  #   with all sub-functions specified above. The number of applications is
  #   assumed to be non-zero.
  # * Labor cost does not scale with MU area (it takes the same effort to turn
  #   on a pump regardless of flood size). Only one flood can be initiated per
  #   day
  #
  # DESCRIPTION
  # This function can be used for estimating the total cost of completing an
  # active flood with both electrical pumps and gas pumps. Depending on the
  # entered values either cost of fuel OR the cost of electicity is added to
  # labor costs and this sum is then multiplied by the area proportion and the
  # number of applications.
  ##

  cost_active_flood <- (fuelCost(
    min_gas, max_gas, cost_gas,
    min_diesel, max_diesel, cost_diesel,
    min_jet, max_jet, cost_jet,
    min_avgas, max_avgas, cost_avgas
  ) +
    electricalPumpCost(
      pump_hours, min_watt, max_watt,
      cost_electricity
    )) *
    areaProportion(treat_area, MU_area, total_area) +
    laborCost(
      hours_student, hours_volunteer,
      hours_seasonal_employee, hours_fulltime_employee,
      cost_student, cost_volunteer,
      cost_seasonal_employee, cost_fulltime_employee
    )

  return(cost_active_flood)
} # end costOfActiveFlood

costOfPassiveFlooding <- function(hours_student, hours_volunteer,
                                  hours_seasonal_employee,
                                  hours_fulltime_employee, # labor hours
                                  cost_student = cost.student, # labor costs initialized
                                  cost_volunteer = cost.volunteer,
                                  cost_seasonal_employee = cost.seasonal.employee,
                                  cost_fulltime_employee = cost.fulltime.employee) {
  # Estimates the total cost of completing a passive flood.
  #
  # INPUT
  # hours_student           : number of hours worked by students (numeric)
  # hours_volunteer         : number of hours worked by volunteers (numeric)
  # hours_seasonal_employee : number of hours worked by seasonal employees
  #                           (numeric)
  # hours_fulltime_employee : number of hours worked by full-time employees
  #                           (numeric)
  #
  # OUTPUT
  # The total cost in USD of completing a passive flood (numeric)
  #
  # ASSUMPTIONS
  # * All variable inputs are properly sorted to correspond with the correct
  #   management action. This function contains all the assumptions associated
  #   with all sub-functions specified above. The number of applications is
  #   assumed to be non-zero.
  #
  #
  # DESCRIPTION
  # This function estimates the total cost in USD of completing a passive flood:
  # passive flooding. This function only considers the cost of labor as a
  # cost component. The cost of labor in this case is only dependent on the time
  # it takes for the worker(s) to open/close the gates or monitor the flooding.
  # this cost does not scale directly with the area being flooded, and therefore
  # does not include areaProportion()
  ##

  cost_passive_flood <- (laborCost(
    hours_student, hours_volunteer,
    hours_seasonal_employee,
    hours_fulltime_employee, cost_student,
    cost_volunteer, cost_seasonal_employee,
    cost_fulltime_employee
  ))
  return(cost_passive_flood)
} # end costOfPassiveFlooding
