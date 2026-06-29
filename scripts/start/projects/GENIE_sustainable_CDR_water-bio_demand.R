library(lucode2)
library(magclass)
library(gms)
library(stringr)

# Load start_run(cfg) function which is needed to start MAgPIE runs
source("scripts/start_functions.R") #nolinter
# Source the default config and then over-write it before starting the run.
source("config/default.cfg") #nolinter

cfg$repositories <- append(list("https://rse.pik-potsdam.de/data/magpie/public" = NULL,
                                "./patch_input" = NULL),
                           getOption("magpie_repos"))

# Folder creation and SLURM queue settings.
cfg$force_replace <- TRUE
cfg$qos <- "priority"

# Setting the time horizon to what we expect for MESSAGE: 2110.
cfg$gms$c_timesteps <- "coup2110"

###############################################################
# SSP2: "MIDDLE OF THE ROAD" = BUSINESS AS USUAL.
###############################################################

ssp_flag <- "SSP2"

cfg$input <- c(regional    = "rev4.119_5ff27be8_magpie.tgz",
               cellular    = "rev4.119_5ff27be8_1b5c3817_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1.tgz",
               validation  = "rev4.119_5ff27be8_validation.tgz",
               additional  = "additional_data_rev4.62.tgz",
               patch       = "SSP2_old.tgz")

cfg$output <- c("output_check", "rds_report")

### Identifier and folder
###############################################
identifierFlag <- "Sustainable_CDR_water-bio_rev6"
cfg$title <- "Sustainable_CDR_water-bio_rev6"
###############################################

cfg$info$flag <- identifierFlag
cfg$results_folder <- paste0("output/", identifierFlag, "/:title:")

# Set the SSP scenario in the scenario_config.csv file to SSP2.
cfg <- setScenario(cfg, "SSP2")

# Demand-driven step (GENIE step 3): endogenous tau — do not set cfg$gms$tc to "exo"
# (exo is for price-driven runs only; see GENIE_sustainable_CDR_water-bio_price.R)
cfg$gms$c13_tccost <- "high"

# Yields scenario should not reflect climate change
cfg$gms$c14_yields_scenario  <- "nocc"

# Food settings for baseline scenario:
# cfg$gms$food <- "anthro_iso_jun22"
cfg$gms$s15_elastic_demand <- 0.0
cfg$gms$s15_exo_diet <- 0.0
# cfg$gms$c15_kcal_scen <- "healthy_BMI"

# Additional land conservation target: none
cfg$gms$c22_protect_scenario <- "none"

# Capping the annual max cropland growth per year per region, relative to current level
cfg$gms$s30_annual_max_growth <- 0.02

# Water settings for sustainable CDR water use scenario:
cfg$gms$c42_env_flow_policy <- "on"
cfg$gms$s42_env_flow_scenario <- 2

### Biodiversity module: baseline run, so use "bii_target" module
cfg$gms$biodiversity <- "bii_target"
### Cost of missing BII set to 10 million USD rather than 1 million as in default.cfg
cfg$gms$s44_cost_bii_missing <- 10000000
### Biodiv: BD78 only — global BII target = 0.78
cfg$gms$c44_bii_decrease <- 0
cfg$gms$s44_bii_target <- 0.78

# No GHG price
cfg$gms$c56_pollutant_prices <- "G0000exp2110" # def = R34M410-SSP2-NPi2025, "G0000"
cfg$gms$c56_pollutant_prices_noselect <- "G0000exp2110" # def = R34M410-SSP2-NPi2025, "G0000"

# ### BE — demand from f60 columns (see BE_demand_readout + add_BE_columns)
cfg$gms$s60_2ndgen_bioenergy_dem_min <- 0
cfg$gms$s60_bioenergy_1st_subsidy <- 0

beV <- c(0, 5, 7, 10, 15, 25, 45) # Options: 0, 5, 7, 10, 15, 25, 45

### GHG — US$2005 labels for run names; inflate CO2 via s56_cprice_red_factor
g_labelV <- c(0, 10, 20, 50, 100, 200, 400, 600, 1000, 2000, 3000, 4000)
inflation_2005_to_2017 <- 1.23

### Food
mpV <- c(0) # Options: 0, 25, 50, 75

preflag <- "SSP2_BD78"
cfg$results_folder <- paste("output", identifierFlag, preflag, ":title:", sep = "/")
cfg$info$flag2 <- preflag

for (mp in mpV) {
  cfg$gms$s15_rumdairy_scp_substitution <- mp / 100

  for (be in beV) {
    be_str <- str_pad(be, 2, pad = "0")

    # f60 column from rev6 price-driven readout (SSP2_old.tgz)
    cfg$gms$c60_2ndgen_biodem <- paste0("SSP2_water_bio_BD78_BE", be_str, "_G0000_price_rev6")

    for (g_label in g_labelV) {
      g_str <- str_pad(g_label, 4, pad = "0")
      cfg$gms$c56_pollutant_prices <- paste0("G", g_str, "exp2110")
      cfg$gms$c56_pollutant_prices_noselect <- paste0("G", g_str, "exp2110")
      cfg$gms$s56_cprice_red_factor <- if (g_label == 0) 1 else inflation_2005_to_2017

      cfg$title <- paste0(preflag, "_BE", be_str, "_G", g_str, "_demand")

      start_run(cfg, codeCheck = FALSE)
    } # GHG
  } # BE
} # MP replacement
