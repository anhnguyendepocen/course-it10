/**
 * CREATE PROGRAMS AND TEST DATA SET FOR LABOR SUPPLY ESTIMATIONS
 *
 * @author  Max Loeffler <loeffler@zew.de>
 * @package course-it10
 * @date    2015-01-14
 */


// Initialize
set seed 1234567
qui do tools
clear
set obs 1000
gen id = _n

// Impute preferences and fixed costs
gen alpha_l  = rnormal(0.1, 0.02)
gen alpha_c  = rnormal(0.6, 0.02)
gen alpha_l2 = runiform() *  0.10
gen alpha_c2 = runiform() * -0.05
gen alpha_cl = runiform() *  0.02
gen fixcosts = runiform() *  0.50

// Imppute number of children
gen child = round(3 * runiform(), 1)

// Impute wages
gen wage = exp(2.25 + 0.05 * child - 0.05 * fixcosts + rnormal(0, 0.4))

// Create choice set
expand 7
bys id: gen hours = (_n - 1) * 10
gen leisure = 80 - hours
gen gross = hours * wage * 4.33
taxbenefit_base gross tax dpi child
gen parttime = inrange(hours, 10, 30)
gen working = (hours > 0)

// Simulate utility and choice
gen epsilon = - ln(- ln(runiform()))
gen ln_l = ln(leisure)
gen ln_c = ln(dpi)
gen util = (alpha_l * ln_l + alpha_l2 * c.ln_l#c.ln_l + ///
            alpha_c * ln_c + alpha_c2 * c.ln_c#c.ln_c + ///
                             alpha_cl * c.ln_l#c.ln_l + ///
            fixcosts * working - 0.5 * parttime) * 2.5 + epsilon
gen expu = exp(util)
bys id: egen totu = total(expu)
gen prob = expu / totu
bys id: egen maxu = max(prob)
gen choice = (maxu == prob)

// Clean up data set
keep if choice == 1
keep id child wage hours choice

***
