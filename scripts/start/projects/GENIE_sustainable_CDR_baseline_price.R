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
            #    cellular    = "rev4.119_5ff27be8_fd712c0b_cellularmagpie_c200_MRI-ESM2-0-ssp370_lpjml-8e6c5eb1.tgz",
               validation  = "rev4.119_5ff27be8_validation.tgz",
               additional  = "additional_data_rev4.62.tgz",
              #  patch       = "SSP2.tgz"
               patch       = "SSP2_old.tgz")

cfg$output <- c("output_check", "rds_report")

### Identifier and folder
###############################################
identifierFlag <- "Sustainable_CDR_baseline_rev5"
cfg$title <- "Sustainable_CDR_baseline_rev5"
###############################################

# Set the identifier flag for shiny app, and output folder.
cfg$info$flag <- identifierFlag
cfg$results_folder <- paste0("output/", identifierFlag, "/:title:")

# Set the SSP scenario in the scenario_config.csv file to SSP2.
cfg <- setScenario(cfg, "SSP2")

### Whether to use endogenous or exogenous technological change
cfg$gms$tc <- "exo"
# Cost of technological change
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

# Baseline water settings
cfg$gms$c42_env_flow_policy <- "off" 
# cfg$gms$s42_env_flow_scenario <- 2 

### Biodiversity module: baseline run, so use "bii_target" module
cfg$gms$biodiversity <- "bii_target"
### Cost of missing BII set to 10 million USD rather than 1 million as in default.cfg
cfg$gms$s44_cost_bii_missing <- 10000000
### Biodiv: BD-none only — no BII target (scalar s44_bii_target = 0 via bii_target realization)
### For spatially resolved BII targets (BD-high), use GENIE_spatially_resolved_BII_price.R instead.
cfg$gms$c44_bii_decrease <- 1
cfg$gms$s44_bii_target <- 0

# No GHG price
cfg$gms$c56_pollutant_prices <- "G0000exp2110" # def = R34M410-SSP2-NPi2025, "G0000"
cfg$gms$c56_pollutant_prices_noselect <- "G0000exp2110" # def = R34M410-SSP2-NPi2025, "G0000"

# ### BE
cfg$gms$s60_2ndgen_bioenergy_dem_min <- 0
cfg$gms$s60_bioenergy_1st_subsidy <- 0
beV <- c(0, 5, 7, 10, 15, 25, 45) # Options: 0, 5, 7, 10, 15, 25, 45

### Food
mpV <- c(0) # Options: 0, 25, 50, 75

preflag <- "SSP2_BD00"
cfg$results_folder <- paste("output", identifierFlag, preflag, ":title:", sep = "/")
cfg$info$flag2 <- preflag

for (mp in mpV) {
  cfg$gms$s15_rumdairy_scp_substitution <- mp / 100

  for (be in beV) {
    cfg$gms$s60_bioenergy_1st_price <- be
    cfg$gms$s60_bioenergy_2nd_price <- be

    runflag <- "price"
    cfg$title <- paste0(preflag, "_BE", str_pad(be, 2, pad = "0"), "_G0000_", runflag)

    start_run(cfg, codeCheck = FALSE)

  } # BE
} # MP replacement