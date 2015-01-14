/**
 * REDISTRIBUTION IN MICROSIMULATION MODELS WITH BEHAVIORAL RESPONSES
 * (10th WINTER SCHOOL ON INEQUALITY AND SOCIAL WELFARE THEORY, CANAZEI, 2015)
 *
 * @author  Max Loeffler <loeffler@zew.de>
 * @package course-it10
 * @date    2015-01-14
 */


// Load data
qui do data


//
// A) Let's see, what we have in the data
//

// Plot distribution of hours
plot_simfit

// Plot distribution of wages
hist wage, name(wages, replace) percent ///
    xtitle("Hourly wages") title("Hourly wage rates")


//
// B) SIMULATE HYPOTHETICAL HOURS
//

// Expand data set
rename hours choice_hours
expand 7
bys id: gen hours = 10 * (_n - 1)

// Identify choice
replace choice = (hours == choice_hours)
drop choice_hours

// Generate budget set
gen gross = hours * wage * 4.33

// Get disposable income
taxbenefit_base gross tax dpi child


//
// C) RUN ESTIMATION
//

// Prepare variables
gen leisure = 80 - hours
gen ln_l    = ln(leisure)
gen ln_l2   = ln_l^2
gen ln_c    = ln(dpi)
gen ln_c2   = ln_c^2
gen ln_lc   = ln_c * ln_l

// Estimate preferences
clogit choice ln_c ln_c2 ln_lc ln_l ln_l2, group(id)

// Alright, predict choices
predict choice_sim1, pc1

// And now, plot observed and predicted hours
plot_simfit choice_sim1

// Uhh, that looks quite bad. Maybe we can control for fixed costs of working?
gen working = (hours > 0)
clogit choice ln_c ln_c2 ln_lc ln_l ln_l2 working, group(id)
predict choice_sim2, pc1
plot_simfit choice_sim1 choice_sim2

// Way better, but still. Let's control for potential shortage of part-time jobs!
gen parttime = inrange(hours, 10, 30)
clogit choice ln_c ln_c2 ln_lc ln_l ln_l2 working parttime, group(id)
predict util_sim3, xb
predict choice_sim3, pc1
plot_simfit choice_sim1 choice_sim2 choice_sim3

// That looks pretty nice!


//
// D) POLICY ANALYSIS
//

// Let's introduce the tax reform
taxbenefit_reform gross taxr dpir child

// Let's calculate the effect on tax revenue if no behavioral response
tabstat hours tax taxr [aw=choice], stat(sum)

// Let's compute inequality measures
inequal7 dpi dpir [aw=choice]

// But, our prediction was not perfect, right? So let's see how it compares
tabstat hours tax taxr [aw=choice_sim3], stat(sum)

// Let's compute inequality measures as well with predicted choices
inequal7 dpi dpir [aw=choice_sim3]

// But the session is called "with behavioral responses" - let's predict it now
replace ln_c  = ln(dpir)
replace ln_c2 = ln_c^2
replace ln_lc = ln_c * ln_l
predict util_reform, xb
predict choice_reform, pc1

// Let's see what we get in terms of working hours and tax revenues
plot_simfit choice_sim3 choice_reform
tabstat hours tax taxr [aw=choice_sim3], stat(sum)
tabstat hours taxr [aw=choice_reform], stat(sum)

// Inequality in base scenario (observed)
qui inequal7 dpi [aw=choice]
mat res = (real(r(gini)) \ real(r(mld)))

// Inequality in base scenario (predicted)
qui inequal7 dpi [aw=choice_sim3]
mat res = res, (real(r(gini)) \ real(r(mld)))

// Inequality in reform scenario (no behavioral response)
qui inequal7 dpir [aw=choice_sim3]
mat res = res, (real(r(gini)) \ real(r(mld)))

// Inequality in reform scenario (with behavioral responses)
qui inequal7 dpir [aw=choice_reform]
mat res = res, (real(r(gini)) \ real(r(mld)))

// Show results
mat rown res = "Gini" "Mean_Log_Dev"
mat coln res = "SQ_obs" "SQ_pred" "CF_static" "CF_response"
mat list res

// We imposed a specific utility structure. Can we compare expected utilites?
bys id: egen e_util_pre  = total(choice_sim3 * util_sim3)
bys id: egen e_util_post = total(choice_reform * util_reform)
gen util_diff = (e_util_post - e_util_pre)

// Show distribution of expected utility losses/gains
sum e_util_* util_diff [aw=choice]
hist util_diff if choice

// Count number of (expected) winners
count if util_diff > 0 & choice

// Count number of (expected) loosers
count if util_diff < 0 & choice

***
