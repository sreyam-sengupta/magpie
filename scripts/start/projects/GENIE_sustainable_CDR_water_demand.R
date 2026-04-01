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

### Biodiversity: use spatially resolved BII realization and switch
###############################################
cfg$gms$biodiversity <- "bii_spatially_resolved"
###############################################

### Identifier and folder
###############################################
identifierFlag <- "Sustainable_CDR_water"
cfg$title <- "Sustainable_CDR_water"
###############################################

# Set the identifier flag for shiny app, and output folder.
cfg$info$flag <- identifierFlag
cfg$results_folder <- paste0("output/", identifierFlag, "/:title:")

cfg <- setScenario(cfg, ssp_flag)

# Cost of technological change
cfg$gms$c13_tccost <- "high"

# Yields scenario should not reflect climate change
cfg$gms$c14_yields_scenario <- "nocc"

# No changes with respect to endogenously generated BMI
cfg$gms$c15_kcal_scen <- "endo"

# Capping the annual max cropland growth per year per region, relative to current level
cfg$gms$s30_annual_max_growth <- 0.02

# Water switch: consider environmental flows
cfg$gms$s42_env_flow_scenario <- 2

### Cost of missing BII set to 10 million USD rather than 1 million as in default.cfg
cfg$gms$s44_cost_bii_missing <- 10000000

# No GHG price for initialization; overwritten in the loop below.
cfg$gms$c56_pollutant_prices <- "G0000exp2110"
cfg$gms$c56_pollutant_prices_noselect <- "G0000exp2110"

# ### BE
cfg$gms$s60_2ndgen_bioenergy_dem_min <- 0
cfg$gms$s60_bioenergy_1st_subsidy <- 0

beV  <- c(0, 45) # 0, 5, 7, 10, 15, 25, 45
gV   <- c(0, 4000) # 0, 10, 20, 50, 100, 200, 400, 600, 1000, 2000, 3000, 4000
blV  <- c("none")
mpV  <- c(0)

cfg$gms$s32_max_aff_cell_2025 <- 0.005

for (bl in blV) {
  bd <- if (bl == "none") 1 else 0
  pa <- "none"

  cfg$gms$c44_bii_decrease <- bd
  cfg$gms$s44_bii_target <- 0
  cfg$gms$c44_use_spatially_resolved_bii_target <- if (bl == "high") 1 else 0
  cfg$gms$c22_protect_scenario <- pa

  for (mp in mpV) {
    cfg$gms$s15_rumdairy_scp_substitution <- mp / 100

    preflag <- paste0("SSP2_BD-", bl)
    cfg$results_folder <- paste("output", identifierFlag, preflag, ":title:", sep = "/")
    cfg$info$flag2 <- preflag

    for (be in beV) {
      be_str <- str_pad(be, 2, pad = "0")

      # Demand input column: extracted from Sustainable_CDR_water price-driven runs
      cfg$gms$c60_2ndgen_biodem <- paste0("SSP2_Water_BD-none_BE", be_str, "_G0000price_rev3")

      for (g in gV) {
        g_str <- str_pad(g, 4, pad = "0")
        cfg$gms$c56_pollutant_prices <- paste0("G", g_str, "exp2110")

        cfg$title <- paste0(preflag, "_BE", be_str, "_G", g_str, "demand_rev3")

        start_run(cfg, codeCheck = FALSE)
      } # GHG
    } # BE
  } # MP replacement
} # BII (BD-none / BD-high)
