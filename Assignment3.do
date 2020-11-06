* set working directory
cd "/Users/jp4096/Documents/RMCodingAssignments/mrktb9708_assignment3"

* upload file
import delimited "/Users/jp4096/Documents/RMCodingAssignments/mrktb9708_assignment3/sports-and-education.csv"

* install packages
ssc install table1
ssc install outreg
ssc install estout

* relabel the variable descriptions 
label variable collegeid "College ID"
label variable academicquality "Academic Quality"
label variable athleticquality "Athletic Quality"
label variable nearbigmarket "Near Big Market (1=Near)"
label variable ranked2017 "Ranked 2017 (1=Ranked)"
label variable alumnidonations2018 "Alumni Donations 2018"

* Create Balance Table 
* easier way using iebaltab 
iebaltab academicquality athleticquality nearbigmarket, grpvar(ranked2017) save(assignment3)

* more complicated way that takes too long
* make tables of descriptive statistics 
global DESCVARS academicquality athleticquality nearbigmarket
mata: mata clear

* First test of differences
local i = 1


foreach var in $DESCVARS {
    reg `var' ranked2017
    outreg, keep(ranked2017)  rtitle("`: var label `var''") stats(b) ///
        noautosumm store(row`i')  starlevels(10 5 1) starloc(1)
    outreg, replay(diff) append(row`i') ctitles("",Difference ) ///
        store(diff) note("")
    local ++i
}
outreg, replay(diff)

* then summary statistics 
local count: word count $DESCVARS
mat sumstat = J(`count',6,.)

local i = 1
foreach var in $DESCVARS {
    quietly: summarize `var' if ranked2017==0
    mat sumstat[`i',1] = r(N)
    mat sumstat[`i',2] = r(mean)
    mat sumstat[`i',3] = r(sd)
    quietly: summarize `var' if ranked2017==1
    mat sumstat[`i',4] = r(N)
    mat sumstat[`i',5] = r(mean)
    mat sumstat[`i',6] = r(sd)
    local i = `i' + 1
}
frmttable, statmat(sumstat) store(sumstat) sfmt(g,f,f,g,f,f)

* Export 
outreg using "assignment3.tex", ///
    replay(sumstat) merge(diff) tex nocenter note("") fragment plain replace ///
    ctitles("", Control, "", "", Treatment, "", "", "" \ "", N, Mean, SD, N, Mean, SD, Diff) ///
    multicol(1,2,3;1,5,3) 
	
* Question 4 
logit ranked2017 academicquality athleticquality nearbigmarket
predict propensityscore, pr
label variable propensityscore "Propensity Score"

* Question 5 : Histogram 
twoway (histogram propensityscore if ranked2017 == 1, color(green%20)) ///
(histogram propensityscore if ranked2017 == 0, color(red%20)), ///
legend(order(1 "Ranked College" 2 "Unranked College"))
* drop non-overlapping 
preserve
drop if propensityscore <= 0.2 
drop if propensityscore >= 0.8
* regraph histogram 
twoway (histogram propensityscore if ranked2017 == 1, color(green%20)) ///
(histogram propensityscore if ranked2017 == 0, color(red%20)), ///
legend(order(1 "Ranked College" 2 "Unranked College"))


* Question 6
sort propensityscore 
gen block = floor(_n/4)


* Question 7 
reg alumnidonations2018 ranked2017 athleticquality academicquality nearbigmarket i.block

* export the table 
eststo Regression1

esttab Regression1 using Assignment3Table.tex, $tableoptions keep(ranked2017 academicquality athleticquality nearbigmarket _cons) star(* 0.10 ** 0.05 *** 0.01) collabels(none) stats(r2 N, fmt(%9.4f %9.0f %9.0fc) labels("R-squared" "Number of observations")) plain noabbrev nonumbers lines parentheses fragment








