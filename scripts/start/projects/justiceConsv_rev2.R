# |  (C) 2008-2024 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de

# ----------------------------------------------------------
# description: Base test runs
# ----------------------------------------------------------

rev <- "rev2"

cres <- "c200"

######################################
#### Script to start a MAgPIE run ####
######################################

library(gms)
library(lucode2)
library(magclass)
library(gdx2)

# Load start functions
source("scripts/start_functions.R")

# ====================
# Calibration
# ====================

# source("config/default.cfg")

# cfg$title <- "calib_run"
# cfg$output <- c("rds_report")

# cfg$recalibrate <- TRUE
# cfg$gms$s14_use_yield_calib <- 1
# cfg$recalibrate_landconversion_cost <- TRUE
# cfg$restart_landconversion_cost <- TRUE

# cfg$force_download <- FALSE

# cfg$repositories <- append(
#     list(
#       "https://rse.pik-potsdam.de/data/magpie/public" = NULL,
#       "../patch_inputdata/" = NULL
#     ),
#     getOption("magpie_repos")
#   )

# cfg$input["patch"] <- "jung_consv_y1750.tgz"

# # cc is new default
# cfg <- setScenario(cfg, c("nocc_hist", "NPI", "SSP2EU"))

# # sticky
# cfg$gms$factor_costs <- "sticky_feb18"

# start_run(cfg = cfg)
# calib_tgz <- magpie4::submitCalibration(paste(rev, "JustConsv", sep = "_"))

# ====================
# Scenario runs
# ====================

prefix <- paste(rev, "JustConsv", cres, sep = "_")

scenarios <- c(
  "SSP2-REF",
  "SSP2-JungGlobalGBFCarbon-1750", "SSP2-JungGlobalGBFCarbon-1950",
  "SSP2-JungGlobalGBFCarbon-1990", "SSP2-JungGlobalGBFCarbon-2020",
  "SSP2-JungGlobalGBF-1750", "SSP2-JungGlobalGBF-1950",
  "SSP2-JungGlobalGBF-1990", "SSP2-JungGlobalGBF-2020",
  "SSP2-JungGlobalGBFCarbon-1750-ExoTC", "SSP2-JungGlobalGBFCarbon-1950-ExoTC",
  "SSP2-JungGlobalGBFCarbon-1990-ExoTC", "SSP2-JungGlobalGBFCarbon-2020-ExoTC",
  "SSP2-JungGlobalGBF-1750-ExoTC", "SSP2-JungGlobalGBF-1950-ExoTC",
  "SSP2-JungGlobalGBF-1990-ExoTC", "SSP2-JungGlobalGBF-2020-ExoTC"
)

for (scen in scenarios) {
  scen <- unlist(strsplit(scen, "-"))
  ssp <- scen[grepl("SSP", scen)]

  if (length(ssp) == 0 || ssp == "SSP2") {
    ssp <- "SSP2EU"
  }

  source("config/default.cfg")
  
  cfg$gms$s14_use_yield_calib <- 1

  cfg$results_folder <- "output/:title::date:"

  cfg$output <- c(
    "output_check", "extra/disaggregation", "rds_report"
  )

  cfg$repositories <- append(
    list(
      "https://rse.pik-potsdam.de/data/magpie/public" = NULL,
      "../patch_inputdata/" = NULL
    ),
    getOption("magpie_repos")
  )
    cfg$input["calibration"] <- "calibration_rev1_JustConsv_17Jul24.tgz"
#    cfg$input["calibration"] <- calib_tgz

  cfg$input["patch"] <- "jung_consv_y1750.tgz"

  if ("1950" %in% scen) {
    cfg$input["patch"] <- "jung_consv_y1950.tgz"
  } else if ("1990" %in% scen) {
    cfg$input["patch"] <- "jung_consv_y1990.tgz"
  }

  if ("ExoTC" %in% scen){
       cfg$gms$tc <- "exo"
  }

  if ("2020" %in% scen) {
    cfg$gms$s22_restore_land <- 0
  }

   cfg$qos <- "priority"

  # Climate change switched off for these runs
  cfg <- setScenario(cfg, c("nocc_hist", "NPI", ssp))

  # sticky
  cfg$gms$factor_costs <- "sticky_feb18"

  if ("30by30" %in% scen) {
    cfg$gms$c22_protect_scenario <- "30by30"
  }

  if ("JungGlobalGBF" %in% scen) {
    cfg$gms$c22_protect_scenario <- "JungGlobalGBF"
  }

  if ("JungGlobalGBFCarbon" %in% scen) {
    cfg$gms$c22_protect_scenario <- "JungGlobalGBFCarbon"
  }

  if ("JungGlobalGBFVertebrate" %in% scen) {
    cfg$gms$c22_protect_scenario <- "JungGlobalGBFVertebrate"
  }

  if ("KBA" %in% scen) {
    cfg$gms$c22_protect_scenario <- "KBA"
  }

  if ("CCA" %in% scen) {
    cfg$gms$c22_protect_scenario <- "CCA"
  }

  if ("BH" %in% scen) {
    cfg$gms$c22_protect_scenario <- "BH"
  }

  cfg$title <- paste0(prefix, "_", paste(scen, collapse = "-"))
  start_run(cfg = cfg, codeCheck = FALSE)
}
