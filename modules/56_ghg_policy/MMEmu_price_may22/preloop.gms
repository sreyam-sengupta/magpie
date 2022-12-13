*** |  (C) 2008-2021 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

* starting value of above ground carbon stocks 1995 is only an estimate.
* ATTENTION: emissions in 1995 are not meaningful
vm_carbon_stock.l(j,land,ag_pools,stockType) = fm_carbon_density("y1995",j,land,ag_pools)*pcm_land(j,land);

v56_emis_pricing.fx(i,emis_oneoff,pollutants)$(not sameas(pollutants,"co2_c")) = 0;

**** Linearly implement pollution prices between s56_ghgprice_start and 2100
* 44/12 conversion from USD per tCO2 to USD per tC
* 28 and 265 Global Warming Potentials from AR5 WG1 CH08 Table 8.7, conversion from USD per tCO2 to USD per tCH4 and USD per tN2O
* 44/28 conversion from USD per tN2O to USD per tN

loop(t_all,
 if(m_year(t_all) <= s56_ghgprice_start,
    p56_co2_price(t_all) = 0;
elseif (m_year(t_all) >= 2100),
    p56_co2_price(t_all) = s56_ghgprice_target;
else
    p56_co2_price(t_all) = s56_ghgprice_target / (2100 - s56_ghgprice_start) * (m_year(t_all) - s56_ghgprice_start);
 );
);
im_pollutant_prices(t_all,i,pollutants,emis_source) = 0;
im_pollutant_prices(t_all,i,"co2_c",emis_source) = (44 / 12) * p56_co2_price(t_all);
im_pollutant_prices(t_all,i,"ch4",emis_source) = 28 * p56_co2_price(t_all);
im_pollutant_prices(t_all,i,"n2o_n_direct",emis_source) = 265 * (44 / 28) * p56_co2_price(t_all);
im_pollutant_prices(t_all,i,"n2o_n_indirect",emis_source) = 265 * (44 / 28) * p56_co2_price(t_all);

***save im_pollutant_prices to parameter
p56_pollutant_prices_input(t_all,i,pollutants,emis_source) = im_pollutant_prices(t_all,i,pollutants,emis_source);

***limit CH4 and N2O GHG prices based on s56_limit_ch4_n2o_price
*12/44 conversion from USD per tC to USD per tCO2
*28 and 265 Global Warming Potentials from AR5 WG1 CH08 Table 8.7, conversion from USD per tCO2 to USD per tCH4 and USD per tN2O
*44/28 conversion from USD per tN2O to USD per tN
im_pollutant_prices(t_all,i,"ch4",emis_source)$(im_pollutant_prices(t_all,i,"ch4",emis_source) > s56_limit_ch4_n2o_price*12/44*28) = s56_limit_ch4_n2o_price*12/44*28;
im_pollutant_prices(t_all,i,"n2o_n_direct",emis_source)$(im_pollutant_prices(t_all,i,"n2o_n_direct",emis_source) > s56_limit_ch4_n2o_price*12/44*265*44/28) = s56_limit_ch4_n2o_price*12/44*265*44/28;
im_pollutant_prices(t_all,i,"n2o_n_indirect",emis_source)$(im_pollutant_prices(t_all,i,"n2o_n_indirect",emis_source) > s56_limit_ch4_n2o_price*12/44*265*44/28) = s56_limit_ch4_n2o_price*12/44*265*44/28;

***apply reduction factor on CO2 price to account for potential negative side effects
***lowers the economic incentive for CO2 emission reduction (avoided deforestation) and afforestation
im_pollutant_prices(t_all,i,"co2_c",emis_source) = im_pollutant_prices(t_all,i,"co2_c",emis_source)*s56_cprice_red_factor;

***multiply GHG prices with development state to account for institutional requirements needed for implementing a GHG pricing scheme
im_pollutant_prices(t_all,i,pollutants,emis_source)$(s56_ghgprice_devstate_scaling = 1) = im_pollutant_prices(t_all,i,pollutants,emis_source)*im_development_state(t_all,i);

***GHG emission policy
im_pollutant_prices(t_all,i,pollutants,emis_source) = im_pollutant_prices(t_all,i,pollutants,emis_source) * f56_emis_policy("%c56_emis_policy%",pollutants,emis_source);

***construct age-class dependent C price for afforestation incentive
***this is needed because time steps (t) and age-classes (ac) can differ. ac and t_all are always in 5-year time steps.
*For missing years in t_all use C price of previous time step. This step makes sure that C prices for every 5-year time step are available.
loop(t_all$(m_year(t_all)>=s56_ghgprice_start),
	im_pollutant_prices(t_all,i,"co2_c",emis_source)$(im_pollutant_prices(t_all,i,"co2_c",emis_source) = 0) = im_pollutant_prices(t_all-1,i,"co2_c",emis_source);
);

*Linear interpolation of C price for missing time steps
loop(t,
 s56_timesteps = m_yeardiff(t)/5;
  if (s56_timesteps > 1,
   s56_counter = 0;
    repeat(
       s56_counter = s56_counter + 1;
       s56_offset = s56_timesteps-s56_counter;
       im_pollutant_prices(t_all-s56_offset,i,"co2_c",emis_source)$(m_year(t_all) = m_year(t)) =
       im_pollutant_prices(t-1,i,"co2_c",emis_source) +
       (im_pollutant_prices(t,i,"co2_c",emis_source) - im_pollutant_prices(t-1,i,"co2_c",emis_source))*s56_counter/(s56_timesteps);
    until s56_counter = s56_timesteps-1);
  );
);

*initialize age-class dependent C price with same C price for all age-classes
p56_c_price_aff(t_all,i,ac) = im_pollutant_prices(t_all,i,"co2_c","forestry_vegc");
*Shift C prices in age-classes for reflecting foresight.
*e.g. ac5 in 2020 should have the C price of ac0 in 2025, and ac20 in 2020 equals to ac0 in 2040
p56_c_price_aff(t_all,i,ac)$(ord(t_all)+ac.off<card(t_all)) = p56_c_price_aff(t_all+ac.off,i,"ac0");
*limit foresight of C prices to X years; constant C price after X years.
ac_exp(ac)$(ac.off = s56_c_price_exp_aff/5) = yes;
p56_c_price_aff(t_all,i,ac)$(ac.off >= s56_c_price_exp_aff/5) = sum(ac_exp, p56_c_price_aff(t_all,i,ac_exp));
*zero C price before starting year
p56_c_price_aff(t_all,i,ac)$(m_year(t_all)<s56_ghgprice_start) = 0;

* Pollutant caps, cumulative or not 
p56_pollutant_cap(t_all,i) = 0;
p56_pollutant_cap_cum(t_all,i) = 0;
loop(t,
    p56_pollutant_cap(t,i) $ (m_year(t) >= s56_ghgprice_start) = f56_pollutant_cap(t,i,"%c56_emis_cap%");
    p56_pollutant_cap_cum(t,i) $ (m_year(t) = s56_ghgprice_start) = f56_pollutant_cap(t,i,"%c56_emis_cap%") * m_yeardiff(t);
    p56_pollutant_cap_cum(t,i) $ (m_year(t) > s56_ghgprice_start) = f56_pollutant_cap(t,i,"%c56_emis_cap%") + (p56_pollutant_cap(t-1,i) * m_yeardiff(t));
);
* Initialize CO2eq emissions counter
p56_emissions_taxed_cumulative(i) = 0;