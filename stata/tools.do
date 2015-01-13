/**
 * TAX BENEFIT CALCULATORS BEFORE AND AFTER THE TAX REFORM
 *
 * @author  Max Loeffler <loeffler@zew.de>
 * @package course-it10
 */


/**
 * TAX BENEFIT SYSTEM (STATUS QUO)
 */
cap program drop taxbenefit_base
program define taxbenefit_base
	args gross tax dpi child
	
	// Small basic income, three tax brackets
	gen `dpi' = max(500 + 150 * `child', ///
					(1 - 0.1) * min(`gross', 2000) + ///
					(1 - 0.4) * max(min(`gross', 4000) - 2000, 0) + ///
					(1 - 0.7) * max(`gross' - 4000, 0))
    gen `tax' = gross - `dpi'
end


/**
 * TAX BENEFIT SYSTEM (AFTER REFORM)
 */
cap program drop taxbenefit_reform
program define taxbenefit_reform
	args gross tax dpi child
	
	// Bigger basic income, flat tax
	gen `dpi' = max(700 + 250 * `child', ///
					(1 - 0.4) * `gross')
    gen `tax' = gross - `dpi'
end


/**
 * PLOT OBSERVED (AND MAYBE PREDICTED) WORKING HOURS DISTRIBUTIONS
 */
cap program drop plot_simfit
program define plot_simfit
    tempvar   sf_hhs
    qui egen `sf_hhs' = total(choice)
    qui levelsof hours, local(hours)
    local sf_list
    foreach ch in choice `0' {
        tempvar  sf_`ch'
        qui gen `sf_`ch'' = .
        foreach o of local hours {
            qui sum `ch'                                    if hours == `o'
            qui replace `sf_`ch'' = 100 * r(sum) / `sf_hhs' if hours == `o'
        }
        local sf_list `sf_list' `sf_`ch''
    }
    graph bar `sf_list', ///
        over(hours) legend(position(6) rows(1) label(1 "Observed")) ///
        title("Weekly working hours") ///
        ytitle("Percent") b1title("Hours of work")
end


***
