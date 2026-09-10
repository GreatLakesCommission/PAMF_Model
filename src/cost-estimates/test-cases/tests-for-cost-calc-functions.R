
# Test the cost functions with specific variables.
# Several of these tests may be outdated: fuel cost, electricity cost and maybe
# a couple of others are now robust to NA input.
# also costOfActiveFlooding() now holds labor costs constant, regardless of
# flooded area (as passive flooding also does)

## Get functions
source("./src/cost-estimates/cost-calculation-functions.R") # the cost estimation equations
source("./src/cost-estimates/cost-helper-functions.R")      # functions that support cost calculations

# Pre-Defined Constants for Testing --------------------------------------------

# (test values as of 07/12/2019)

# These constants include known values such as the average cost of glyphosate or
# Imazapyr. They may need to be changed with some regularity depending on the
# market cost for them, and are therefore defined here for ease of editing.

# Herbicides (USD/gal) - cost of the actual product per gallon
cost.glyphosate = 5
cost.imazapyr = 10
cost.imazamox = 15  # For glyphosate+ treatments

# Fuels & Electricity (USD/gal) - cost of fuel per equipment per gallon
cost.jetfuel = 25
cost.gas = 4
cost.diesel = 5
cost.avgas = 10
cost.electricity = 2

# Labor Costs (USD/hour) - average wage per worker type
cost.student = 12
cost.volunteer = 8
cost.seasonal.employee = 20
cost.fulltime.employee = 25

# Equipment Operation Costs (USD/hour) - Cost of operating each type of equipment
# Herbicide Equipment
cost.handtools = 5
cost.backpack.sprayer = 10
cost.boom.sprayer = 15
cost.wheeled.vehicle = 30
cost.tracked.vehicle = 50
cost.aerial.vehicle = 100
cost.watercraft = 75

cost.gas.handtools = 8 # under cutequipment

# Mechanical Manipulations
cost.torches = 20
cost.gasmower = 25
cost.vehicle.attachment = 20


# Test Cases -------------------------------------------------------------------

## Area Proportion -------------------------------------------------------------

# Treatment area was exact area of MU

## Both areas entered properly (answer = 1)
areaProportion(treat_area = 1, MU_area = 10, total_area = 10)

## total area as NA (answer = 1)
areaProportion(treat_area = 1, MU_area = 10, total_area = NA)

## total area less than treatment area (answer = 1)
areaProportion(treat_area = 1, MU_area = 10, total_area = 5)

# Treatment area different from MU

## Total area greater than MU area (answer = 0.5)
areaProportion(treat_area = 2, MU_area = 10, total_area = 20)

## Total area less than MU area (should not be possible, as this would indicate
#       an incomplete management action) - answer = 2

areaProportion(treat_area = 2, MU_area = 10, total_area = 5)

# treat_area is NA - violates assumptions stated in function definition
#   * results in an error with warning message
areaProportion(treat_area = NA, MU_area = 10, total_area = 10)

# MU_area is NA - only a problem if treat_area = 2
# answer = 1
areaProportion(treat_area = 1, MU_area = NA, total_area = 10)
# answer = NA with warning
areaProportion(treat_area = 2, MU_area = NA, total_area = 10)

# total_area is NA - only a problem if treat_area = 1
# answer = 1
areaProportion(treat_area = 1, MU_area = 10, total_area = NA)
# answer = NA with warning
areaProportion(treat_area = 2, MU_area = 10, total_area = NA)

# treat_area does not equal 1 or 2 (error with warning)
areaProportion(treat_area = 4, MU_area = 10, total_area = 10)

## Herbicide Product Cost ------------------------------------------------------

# All variables entered normally (10 * 50/100 * 10 = 50)
herbicideProductCost(cost_product = 10, concentration = 50, volume_mix = 10)

# All variables entered normally (10 * 20/100 * 25 = 50)
herbicideProductCost(cost_product = 10, concentration = 20, volume_mix = 25)

# All variables entered normally (25 * 75/100 * 20 = 375)
herbicideProductCost(cost_product = 25, concentration = 75, volume_mix = 20)

# All variables entered normally (10.3333333 * 50/100 * 20.3333 = 105.0554)
herbicideProductCost(cost_product = 10.3333333, concentration = 50, volume_mix = 20.3333)
# don't know how float variables are handled by R, all of the numbers entered are read as doubles

# output seems to round to about 4 decimal places

# Cost of product = NA
herbicideProductCost(cost_product = NA, concentration = 50, volume_mix = 10)

# Concentration = NA
herbicideProductCost(cost_product = 10, concentration = NA, volume_mix = 10)

# Volume of mixture = NA
herbicideProductCost(cost_product = 10, concentration = 50, volume_mix = NA)

# Cost of product = 0 (answer = 0)
herbicideProductCost(cost_product = 0, concentration = 50, volume_mix = 10)

# Concentration = 0 (answer = 0)
herbicideProductCost(cost_product = 10, concentration = 0, volume_mix = 10)

# Volume of mixture = 0 (answer = 0)
herbicideProductCost(cost_product = 10, concentration = 50, volume_mix = 0)

# Cost of product = 1 (1 * 50/100 * 10 = 5)
herbicideProductCost(cost_product = 1, concentration = 50, volume_mix = 10)

# Concentration = 1 (10 * 100/100 * 10 = 100)
herbicideProductCost(cost_product = 10, concentration = 100, volume_mix = 10)

# Volume of mixture = 1 (10/100 * 50 * 1 = 5)
herbicideProductCost(cost_product = 10, concentration = 50, volume_mix = 1)

## Herbicide Product Cost per Acre ---------------------------------------------

# Answer =  45 * 4 * 0.25 = 45
herbicideProductCostAcre(cost_product = 45, volume_acre = 4 )

# Answer = 0
herbicideProductCostAcre(cost_product = 45, volume_acre = NA )

# Answer: error message - product cost missing
herbicideProductCostAcre(cost_product = NA, volume_acre = NA )


## Hourly Equipment Cost -------------------------------------------------------

# All variables entered normally (10 * 15 = 150)
hourlyEquipmentCost(cost = 10, equipment_hours = 15)

# All variables entered normally (5 * 15 = 75)
hourlyEquipmentCost(cost = 5, equipment_hours = 15)

# All variables entered normally with decimals (10.3333333 * 10 = 103.333333)
hourlyEquipmentCost(cost = 10.3333333, equipment_hours = 10)
# don't know how float variables are handled by R, all of the numbers entered are read as doubles
# output seems to round to about 4 decimal places

# cost = NA (answer = NA, with warning message)
hourlyEquipmentCost(cost = NA, equipment_hours = 10)

# equipment_hours = NA (answer = NA, with warning message)
hourlyEquipmentCost(cost = 10, equipment_hours = NA)

# cost = 0 (answer = 0)
hourlyEquipmentCost(cost = 0, equipment_hours = 10)

# equipment_hours = 0 (answer = 0)
hourlyEquipmentCost(cost = 10, equipment_hours = 0)

# cost = 1 (answer = 10)
hourlyEquipmentCost(cost = 1, equipment_hours = 10)

# equipment_hours = 1 (answer = 10)
hourlyEquipmentCost(cost = 10, equipment_hours = 1)

## Equipment Rental Cost -------------------------------------------------------

# Value entered normally (answer = 120)
equipmentRentalCost(cost_equip_rental = 120)

# value missing (answer = 0)
equipmentRentalCost(cost_equip_rental =  NA)

## Fuel Costs ------------------------------------------------------------------
# Predefined Costs
# cost.jetfuel = 25
# cost.gas = 4
# cost.diesel = 5
# cost.avgas = 10
# cost.electricity = 2

# Only gas
# answer = 4*((10+20)/2) + 0 + 0 + 0 = 60
fuelCost(min_gas = 10, max_gas = 20, # gas
         min_diesel = 0, max_diesel = 0, # diesel
         min_jet = 0, max_jet = 0, # jetfuel
         min_avgas = 0, max_avgas = 0) # avgas

# only diesel
# answer = 0 + 5*(20) + 0 + 0 = 100
fuelCost(min_gas = 0, max_gas = 0, # gas
         min_diesel = 20, max_diesel = 20, # diesel
         min_jet = 0, max_jet = 0, # jetfuel
         min_avgas = 0, max_avgas = 0) # avgas

# only jetfuel
# answer = 0 + 0 + 25*((50+60)/2) + 0 = 1375
fuelCost(min_gas = 0, max_gas = 0, # gas
         min_diesel = 0, max_diesel = 0, # diesel
         min_jet = 50, max_jet = 60, # jetfuel
         min_avgas = 0, max_avgas = 0) # avgas

# Only avgas
# answer = 0 + 0 + 0 + 10*((30 + 40)/2) = 350
fuelCost(min_gas = 0, max_gas = 0, # gas
         min_diesel = 0, max_diesel = 0, # diesel
         min_jet = 0, max_jet = 0, # jetfuel
         min_avgas = 30, max_avgas = 40) # avgas

# All of the fuel types
# answer = 4*(10) + 5*((30+40)/2) + 25*((10+20)/2) + 10*((30 + 40)/2)
# = 40 + 175 + 375 + 350 = 940
fuelCost(min_gas = 10, max_gas = 10, # gas
         min_diesel = 30, max_diesel = 40, # diesel
         min_jet = 10, max_jet = 20, # jetfuel
         min_avgas = 30, max_avgas = 40) # avgas

# All of the fuel types
# answer = 4*(10) + 5*(40) + 25*(20) + 10*(40)
# = 40 + 200 + 240 + 500 + 400 = 1140
fuelCost(min_gas = 10, max_gas = 10, # gas
         min_diesel = 40, max_diesel = 40, # diesel
         min_jet = 20, max_jet = 20, # jetfuel
         min_avgas = 40, max_avgas = 40) # avgas

# Change one cost value to NA
# answer = NA with a warning printed out
fuelCost(min_gas = 10, max_gas = 10, cost_gas = NA, # gas
         min_diesel = 30, max_diesel = 40, # diesel
         min_jet = 10, max_jet = 20, # jetfuel
         min_avgas = 30, max_avgas = 40) # avgas

# Test warning messages
# answer = NA with a warning printed out
fuelCost(min_gas = 10, max_gas = 10, cost_gas = NA, # gas
         min_diesel = 30, max_diesel = 40, cost_diesel = NA, # diesel
         min_jet = 10, max_jet = 20, cost_jet = NA, # jetfuel
         min_avgas = 30, max_avgas = 40, cost_avgas = NA) # avgas

## Labor Costs -----------------------------------------------------------------

# wage constants were set as below
# cost_student = 12
# cost_volunteer = 8
# cost_seasonal_employee = 20
# cost_fulltime_employee = 25


# all variables entered appropriately
# (12 * 2) + (8*4) + (20*6) + (25*10) = 24 + 32 + 120 + 250 = 426
laborCost(hours_student = 2, hours_volunteer = 4,
          hours_seasonal_employee = 6, hours_fulltime_employee = 10)

# No student workers
# student hours = NA => student hours = 0 =>
# (12 * 0) + (8*4) + (20*6) + (25*10) = 0 + 32 + 120 + 250 = 402
laborCost(hours_student = NA, hours_volunteer = 4,
          hours_seasonal_employee = 6, hours_fulltime_employee = 10)

# No volunteers
# volunteer hours = NA => volunteer hours = 0 =>
# (12 * 2) + (8*0) + (20*6) + (25*10) = 24 + 0 + 120 + 250 = 394
laborCost(hours_student = 2, hours_volunteer = NA,
          hours_seasonal_employee = 6, hours_fulltime_employee = 10)

# No seasonal employees
# seasonal employee hours = NA => seasonal employee hours = 0 =>
# (12 * 2) + (8*4) + (20*0) + (25*10) = 24 + 32 + 0 + 250 = 306
laborCost(hours_student = 2, hours_volunteer = 4,
          hours_seasonal_employee = NA, hours_fulltime_employee = 10)

# No fulltime employees
# fulltime employees hours = NA => fulltime employees hours = 0 =>
# (12 * 2) + (8*4) + (20*6) + (25*0) = 24 + 32 + 120 + 0 = 176
laborCost(hours_student = 2, hours_volunteer = 4,
          hours_seasonal_employee = 6, hours_fulltime_employee = NA)

# All zeros (answer = 0)
laborCost(hours_student = 0, hours_volunteer = 0,
          hours_seasonal_employee = 0, hours_fulltime_employee = 0)

# All ones
# 12 + 8 + 20 + 25 = 65
laborCost(hours_student = 1, hours_volunteer = 1,
          hours_seasonal_employee = 1, hours_fulltime_employee = 1)

# All NA (answer = 0)
laborCost(hours_student = NA, hours_volunteer = NA,
          hours_seasonal_employee = NA, hours_fulltime_employee = NA)

## Electrical Pump Cost --------------------------------------------------------

# cost_electricity = 2

# Pump Hours entered normally (10 * 2 = 20)
electricalPumpCost(10)

# Test decimals
electricalPumpCost(10.2572737375) # seems to round

# Pump hours = 0 (answer = 0)
electricalPumpCost(0)

# Pump hours = NA (answer = NA, with warning)
electricalPumpCost(NA)

## Cost of Contractor ----------------------------------------------------------

# Treat_area = 1 (exact area) normal entries
# 45 * 1= 45
costOfContractor(cost_service = 45, treat_area = 1, MU_area = 10,
                 total_area = NA)

# Treat_area = 1 (exact area) normal entries
# 45 * 1 = 45
costOfContractor(cost_service = 45, treat_area = 1, MU_area = 10,
                 total_area = NA)

# Treat_area = 1 (exact area) normal entries
# 45 * 1 = 45
costOfContractor(cost_service = 45, treat_area = 1, MU_area = 10,
                 total_area = 10)

# Treat_area = 1 (exact area) cost_service = 0
# answer = 0
costOfContractor(cost_service = 0, treat_area = 1, MU_area = 10,
                 total_area = 10)

# Treat_area = 2 (different areas) normal entries
# 45 * 10/20 = 45 * 0.5 = 22.5
costOfContractor(cost_service = 45, treat_area = 2, MU_area = 10,
                 total_area = 20)

# Treat_area = 2 (diff areas) total_area = NA
# answer = NA with warning
costOfContractor(cost_service = 45, treat_area = 2, MU_area = 10,
                 total_area = NA)

# Treat_area = 2 (diff areas) cost_service = NA
# answer = NA with warning
costOfContractor(cost_service = NA, treat_area = 2, MU_area = 10,
                 total_area = 20)

## Cost of Herbicide Action ----------------------------------------------------

# All variables entered normally without extra herbicide product
# [(25*50/100*10) + (4*20) + (40*2) + (12*4 + 8*2 + 20*8 + 25*2)]* 1 * 1
# = 125 + 80 + 80 + 274 = 559
costOfHerbicide(cost_product = 25, concentration = 50, volume_mix = 10,
                min_gas = 20, max_gas = 20,
                min_diesel = 0, max_diesel = 0,
                min_jet = 0, max_jet = 0,
                min_avgas = 0, max_avgas = 0,
                cost_equip_rental = 80, volume_surf_mix = 10,
                hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                hours_fulltime_employee = 2, treat_area = 1,
                MU_area = 10, total_area = NA)

# jet fuel used with gas
# [(25*50/100*10) + ((4*20) + 25*((20+ 30)/2)) + (40*2) + (12*4 + 8*2 + 20*8 + 25*2)]* 1 * 1
# = 125 + 705 + 80 + 274 = 1184
costOfHerbicide(cost_product = 25, concentration = 50, volume_mix = 10,
                min_gas = 20, max_gas = 20,
                min_diesel = 0, max_diesel = 0,
                min_jet = 20, max_jet = 30,
                min_avgas = 0, max_avgas = 0,
                cost_equip_rental = 80, volume_surf_mix = 10,
                hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                hours_fulltime_employee = 2, treat_area = 1,
                MU_area = 10, total_area = NA)


# All variables entered normally without extra herbicide product - different treatment area
# [(25*50/100*10) + (80) + (40*2) + (12*4 + 8*2 + 20*8 + 25*2)]* 1 * (10/20)
# = (125 + 80 + 80 + 274)*0.5 = 559*0.5 = 279.5
costOfHerbicide(cost_product = 25, concentration = 50, volume_mix = 10,
                min_gas = 20, max_gas = 20,
                min_diesel = 0, max_diesel = 0,
                min_jet = 0, max_jet = 0,
                min_avgas = 0, max_avgas = 0,
                cost_equip_rental = 80, volume_surf_mix = 10,
                hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                hours_fulltime_employee = 2, treat_area = 2,
                MU_area = 10, total_area = 20)

# Using Glyph+ add extra herbicide cost
# [(25*50/100*10) + (15*0.2*15) + (4*20) + (40*2) + (12*4 + 8*2 + 20*8 + 25*2)]* 1 * 1
# = 125 + 45 + 80 + 80 + 274 = 604
costOfHerbicide(cost_product = 25, concentration = 50, volume_mix = 10,
                cost_add_product = 15, concentration_add = 0.2, volume_add_mix = 10,
                min_gas = 20, max_gas = 20,
                min_diesel = 0, max_diesel = 0,
                min_jet = 0, max_jet = 0,
                min_avgas = 0, max_avgas = 0,
                cost_equip_rental = 80, volume_surf_mix = 10,
                hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                hours_fulltime_employee = 2, treat_area = 1,
                MU_area = 10, total_area = NA)

# Missing rental cost
# [(25*50/100*10) + (0) + (4*20) + (12*4 + 8*2 + 20*8 + 25*2)]* 1 * (10/20)
# = (125 + 80 + 274)*0.5 = 239.5
costOfHerbicide(cost_product = 25, concentration = 50, volume_mix = 10,
                min_gas = 20, max_gas = 20,
                min_diesel = 0, max_diesel = 0,
                min_jet = 0, max_jet = 0,
                min_avgas = 0, max_avgas = 0,
                cost_equip_rental = NA, volume_surf_mix = 10,
                hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                hours_fulltime_employee = 2, treat_area = 2,
                MU_area = 10, total_area = 20)

# Mixed gas usage
# [(25*50/100*10) + (80) + (4*20 + 5*(10) + 25*((20 + 30)/2) + 10*15) + (12*4 + 8*2 + 20*8 + 25*2)]* 1 * (10/20)
# = (125 + 80 + 905 + 274)*0.5 = 692
costOfHerbicide(cost_product = 25, concentration = 50, volume_mix = 10,
                min_gas = 20, max_gas = 20,
                min_diesel = 10, max_diesel = 10,
                min_jet = 20, max_jet = 30,
                min_avgas = 15, max_avgas = 15,
                cost_equip_rental = 80, volume_surf_mix = 10,
                hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                hours_fulltime_employee = 2, treat_area = 2,
                MU_area = 10, total_area = 20)

# YOU ARE HERE 
# New herbicide function test
(25 * 0 * 0 * 0.5) + # product conc
  (25* 0 * 0 * 0.5) +  # added product conc
  ((25 * 5 * 0.25 ) * 10)  + # product / acre
  ((25 * 0 * 0.25 ) * 10) + # added product / acre
  0 + # fuel cost
  0 + # equipmentRentalCost
  (laborCost( 4, 2, 8, 2) *
     areaProportion(2, 10, 20))

costOfHerbicide(cost_product = 25, 
                            volume_acre = 5,  volume_acre_add = 0, 
                            min_gas = 0, max_gas = 0, 
                            min_diesel = 0, max_diesel = 0, 
                            min_jet = 0, max_jet = 0, 
                            min_avgas= 0, max_avgas= 0, 
                            cost_equip_rental = 0, 
                hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                hours_fulltime_employee = 2, treat_area = 2,
                MU_area = 10, total_area = 20,
                treat_area_herb = 2, total_area_herb = 20, # herbicide area proportion
      )


(25 * 0.5 * 10 * 0.5) + # product conc
  (25* 0 * 0 * 0.5) +  # added product conc
  ((25 * 0 * 0.25 ) * 10)  + # product / acre
  ((25 * 0 * 0.25 ) * 10) + # added product / acre
  0 + # fuel cost
  0 + # equipmentRentalCost
  (laborCost( 4, 2, 8, 2) *
     areaProportion(2, 10, 20))
# 197.5

costOfHerbicide(cost_product = 25, concentration = 0.5, volume_mix = 10,
                min_gas = 0, max_gas = 0, 
                min_diesel = 0, max_diesel = 0, 
                min_jet = 0, max_jet = 0, 
                min_avgas= 0, max_avgas= 0, 
                cost_equip_rental = 0, 
                hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                hours_fulltime_employee = 2, treat_area = 2,
                MU_area = 10, total_area = 20,
                treat_area_herb = 2, total_area_herb = 20, # herbicide area proportion
)
# 197.5

## Cost of Biomass Actions with Equipment --------------------------------------

# All variables entered normally
# [(4*20) + (4*20) + (12*4 + 8*2 + 20*8 + 25*2)]* 1 * 1
# = 80 + 80 + 274 = 434
costOfBiomassWEquipment(min_gas = 20, max_gas = 20,
                        min_diesel = 0, max_diesel = 0,
                        min_jet = 0, max_jet = 0,
                        min_avgas = 0, max_avgas = 0,
                        cost_equip_rental = 80,
                        hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                        hours_fulltime_employee = 2, treat_area = 1,
                        MU_area = 10, total_area = NA)

# All variables entered normally with different treatment areas
# [(4*20) + (4*20) + (12*4 + 8*2 + 20*8 + 25*2)]* 1 * 0.5
# = (80 + 80 + 274)*0.5 = 434*0.5 = 217
costOfBiomassWEquipment(min_gas = 20, max_gas = 20,
                        min_diesel = 0, max_diesel = 0,
                        min_jet = 0, max_jet = 0,
                        min_avgas = 0, max_avgas = 0,
                        cost_equip_rental = 80,
                        hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                        hours_fulltime_employee = 2, treat_area = 2,
                        MU_area = 10, total_area = 20)


# Mixed fuel use
# [(4*20 + 5*(10) + 25*((20 + 30)/2) + 10*15) + 80 + (12*4 + 8*2 + 20*8 + 25*2)] * 0.5
# (905 + 80 + 274)*0.5 = 629.5
costOfBiomassWEquipment(min_gas = 20, max_gas = 20,
                        min_diesel = 10, max_diesel = 10,
                        min_jet = 20, max_jet = 30,
                        min_avgas = 15, max_avgas = 15,
                        cost_equip_rental = 80,
                        hours_student = 4, hours_volunteer = 2, hours_seasonal_employee = 8,
                        hours_fulltime_employee = 2, treat_area = 2,
                        MU_area = 10, total_area = 20)

# Without some forms of labor
# [(4*20) + (40*2) + (12*0 + 8*0 + 20*8 + 25*2)] * 0.5
# = (80 + 80 + 210)*0.5 = 185
costOfBiomassWEquipment(min_gas = 20, max_gas = 20,
                        min_diesel = 0, max_diesel = 0,
                        min_jet = 0, max_jet = 0,
                        min_avgas = 0, max_avgas = 0,
                        cost_equip_rental = 80,
                        hours_student = 0, hours_volunteer = 0, hours_seasonal_employee = 8,
                        hours_fulltime_employee = 2, treat_area = 2,
                        MU_area = 10, total_area = 20)

## Cost of Hand Removal --------------------------------------------------------

# All variables entered normally
# (12*4 + 8*2 + 20*8 + 25*2)* 1 * 1 = 274
costOfHandRemoval(hours_student = 4, hours_volunteer = 2,
                             hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                             treat_area = 1, MU_area = 10,
                             total_area = NA)

# All variables entered normally with didfferent treatment areas
# (12*4 + 8*2 + 20*8 + 25*2)* 1 * (10/20) = 274*0.5 = 137
costOfHandRemoval(hours_student = 4, hours_volunteer = 2,
                             hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                             treat_area = 2, MU_area = 10,
                             total_area = 20)



# (12*4 + 8*2 + 20*8 + 25*2)* 1 * (10/20) = 274*0.5 = 137
costOfHandRemoval(hours_student = 4, hours_volunteer = 2,
                             hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                             treat_area = 2, MU_area = 10, total_area = 20)

# some of the labor chategories = NA
# (12*0 + 8*2 + 20*0 + 25*2)* 1 * (10/20) = 66*0.5 = 33
costOfHandRemoval(hours_student = NA, hours_volunteer = 2,
                             hours_seasonal_employee = NA, hours_fulltime_employee = 2,
                             treat_area = 2, MU_area = 10,
                             total_area = 20)

## Cost of Active Flooding -----------------------------------------------------

# Electric pumps (cost_electricity = 2)
# (2*20 + (12*4 + 8*2 + 20*8 + 25*2))* 1 * 1 = (40 + 274) = 314
costOfActiveFlood(pump_hours = 20, hours_student = 4, hours_volunteer = 2,
                  hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                  treat_area = 1, MU_area = 10, total_area = NA)

# Electric pumps (cost_electricity = 2) different treatment areas
# (2*20 + (12*4 + 8*2 + 20*8 + 25*2))* 0.5 * 1 = (40 + 274)*0.5 = 314*0.5 = 157
costOfActiveFlood(pump_hours = 20, hours_student = 4, hours_volunteer = 2,
                  hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                  treat_area = 2, MU_area = 10, total_area = 20)

# Electric pumps (cost_electricity = 2) different treatment areas and number of apps = 2
# (2*20 + (12*4 + 8*2 + 20*8 + 25*2))* 0.5 = (40 + 274) * 0.5 = 314*0.5 = 157
costOfActiveFlood(pump_hours = 20, hours_student = 4, hours_volunteer = 2,
                  hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                  treat_area = 2, MU_area = 10, total_area = 20)


# Gas Pumps (cost_gas = 4)
# (4*10 + (12*4 + 8*2 + 20*8 + 25*2))* 1 * 1 = (40 + 274) = 314
costOfActiveFlood(min_gas = 10, max_gas = 10,
                  min_diesel = 0, max_diesel = 0,
                  min_jet = 0, max_jet = 0,
                  min_avgas = 0, max_avgas = 0,
                  hours_student = 4, hours_volunteer = 2,
                  hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                  treat_area = 1, MU_area = 10, total_area = NA)

# Gas Pumps (cost_gas = 4) with different treatment areas
# (4*10 + (12*4 + 8*2 + 20*8 + 25*2))* 0.5 * 1 = (40 + 274)*0.5 = 334*0.5 = 157
costOfActiveFlood(min_gas = 10, max_gas = 10,
                  min_diesel = 0, max_diesel = 0,
                  min_jet = 0, max_jet = 0,
                  min_avgas = 0, max_avgas = 0,
                  hours_student = 4, hours_volunteer = 2,
                  hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                  treat_area = 2, MU_area = 10, total_area = 20)

# treat_area not the proper number (warning message and error)
costOfActiveFlood(min_gas = 10, max_gas = 10,
                  min_diesel = 0, max_diesel = 0,
                  min_jet = 0, max_jet = 0,
                  min_avgas = 0, max_avgas = 0,
                  hours_student = 4, hours_volunteer = 2,
                  hours_seasonal_employee = 8, hours_fulltime_employee = 2,
                  treat_area = 3, MU_area = 10, total_area = 20)

## Cost of Passive Flood -------------------------------------------------------

# (SEE Labor Costs TEST CASES)
# This function only uses the cost of labor, therefore all test cases for the
# laborCost function apply to this function as well.

