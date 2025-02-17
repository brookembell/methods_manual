# Gitanjali Singh - original
# HSPH
# Fred Cudhea - new better version
# Tufts
# Age extrapolation of dietary relative risks based on single RR and median age at event.
# Code last updated 07.09.13 by GMS; edited to remove irrelevant parts 09.28.15 by GMS

rm(list=ls(all=TRUE))
#setwd("C:\\Users\\gsingh04\\Documents\\Kingston backup 061909\\Nutrition\\Dietary RRs\\")
#setwd("C:\\Users\\Fred Cudhea\\Box Sync\\new life\\USmortality\\")
setwd("C:\\Users\\Fred Cudhea\\Box Sync\\US Diet-CVD CRA\\3. Diet-Disease Pairs & RRs\\2. RRs\\Direct RRs\\")

original = read.csv("revised RRs_v9_01-20-17.csv")

set.seed(2015) 


perchange = c(0, 0.040895015,	0.186361622,	0.325799165,	0.440785566,	0.572297214,	0.774534956) # vector of the average percent changes in logRR by age in comparison to the youngest age group across metabolic risks
age.group.lower.bounds<-c(25, 35, 45, 55, 65, 75, 85)
# for example 0.04089 is the percent change for age group 35-44  in comparison to age group 25-34
# similaryl 0.1863 is the percent change for age group 45-54 in comparison to age group 25-34
# if a is age group 25-34 and b is any other age group, then percent change is calculated as ABSVAL((a-b)/a)

rflist = original$risk.factor
outcomelist = original$outcome

### Run through calculation for each RF-outcome pair in the dietary RR dataset

for (r in 1:length(original$risk.factor)) {  
# for (r in 1: 1) {  ### this is just for testing.
#setwd("C:\\Documents and Settings\\GSINGH\\My Documents\\Current Files\\Kingston backup 061909\\Nutrition\\Dietary RRs")

#original = read.csv("RR_diet_080813.csv")
  
  cat("r: ", r, "\n")

orig.subset <- subset(original, risk.factor==rflist[r] & outcome == outcomelist[r])


# number of simulations
nsim = 1000

# generate empty vectors and matrices
sim.logRR = c()
orig.subset$draw.logRR= c()

# for logRRs calculated from percent change by age across metabolic risk logRRs
logRR.perc.30 = c()
logRR.perc.40 = c()
logRR.perc.50 = c()
logRR.perc.60 = c()
logRR.perc.70 = c()
logRR.perc.80 = c()
logRR.perc.92 = c()
#Is above even necessary? Might make sense to just skip it. and put the values directly into matrix.perchange matrix

matrix.perchange = matrix(NA, length(age.group.lower.bounds), nsim)
matrix.perchange.exp = matrix(NA, length(age.group.lower.bounds), nsim)

condensemean2 = c()
condensesd2 = c()

condensemean2.exp = c()
condensesd2.exp = c()

sim.logRR=rnorm(nsim, mean=orig.subset$logRR, sd=(orig.subset$logCI.upper-orig.subset$logCI.lower)/3.92)

for (j in 1:nsim) {
  # generate a vector of nsim number of dietary logRRs by drawing from the diet logRR distribution
  orig.subset$draw.logRR<- sim.logRR[j]          # sample one from the nsim number of simulated logRRs

### apply the percent changes, calculated accross metabolic risks, to each dietary factor to produce the age pattern.

#perchange.prot = c(0, 0.040895015,	0.186361622,	0.325799165,	0.440785566,	0.572297214,	0.774534956)
#perchange.harm = c(0, -0.040895015,	-0.186361622,	-0.325799165,	-0.440785566,	-0.572297214,	-0.774534956)

# first calculate the logRR for youngest age group (25-34) based on RR at age of event
# if a is the logRR for youngest age group, b is the logRR at the age of event, and c is the percent change for the age group including the age at event, then:
# for harmful risks: a = b/(1+(-c))
# for protective risks: a = b/(1-c)
## c is negative for harmful risks and positive for protective risks
## logRRs become less negative with increasing age for protective risks; RRs become larger, i.e. closer to the null for protective risks (0 --> 1)
## logRRs become more negative with increasing age for harmful risks: RRs become smaller, i.e. closer to null for harmful risks with increasing age (inf --> 1)

#if(orig.subset$event.age >= 45 & orig.subset$event.age < 55) change = 0.186361622      else
#if(orig.subset$event.age >= 55 & orig.subset$event.age <=65) change = 0.325799165      else
#if(orig.subset$event.age >= 65 & orig.subset$event.age <=74) change = 0.440785566      else
#if(orig.subset$event.age >= 75 & orig.subset$event.age <=84) change = 0.572297214

change <- perchange[findInterval(x=orig.subset$event.age, vec=age.group.lower.bounds)]

#if(orig.subset$event.age >= 25 & orig.subset$event.age < 35) change = perchange[1]                else
#if(orig.subset$event.age >= 35 & orig.subset$event.age < 45) change = perchange[2]      else
#if(orig.subset$event.age >= 45 & orig.subset$event.age < 55) change = perchange[3]     else
#f(orig.subset$event.age >= 55 & orig.subset$event.age <=65) change = perchange[4]      else
#if(orig.subset$event.age >= 65 & orig.subset$event.age <=74) change = perchange[5]     else
#if(orig.subset$event.age >= 75 & orig.subset$event.age <=84) change = perchange[6]      else
#if(orig.subset$event.age >= 85 & orig.subset$event.age <=100) change = perchange[7]

# if (orig.subset$risk.factor == "red.meat.unproc" | orig.subset$risk.factor == "red.meat.proc"| orig.subset$risk.factor == "ssb" | orig.subset$risk.factor == "sodium") a =  orig.subset$draw.logRR/(1+(-change)) else
# a =  orig.subset$draw.logRR/(1-change)            ####gms: change here if adding more harmful dietary factors

##As stated above by Gita, the age patterin is such that the effect of food on disease decreases as age increases. if the a si the log(RR) for
##the youngest age group, then the log(RR) for the oldest age group is actually a*(1-.7745). That's why we are using (1-change) rather than (1+change)
a <- orig.subset$draw.logRR/(1-change) 

# next, using the logRR for youngest age group, use the perchange vector to compute the logRRs for other ages
# if a is the logRR for youngest age group, and c is the percent change from perchange vector for age group x, 
#and n is the logRR for age group x, then
# for protective risks: n = a(1-c) for age group x
# for harmful risks: n = a(1+(-c))   for age group x

# if (orig.subset$risk.factor == "red.meat.unproc" | orig.subset$risk.factor == "red.meat.proc"| orig.subset$risk.factor == "ssb" | orig.subset$risk.factor == "sodium") logRR.perc.30 = a*(1+perchange.harm[1]) else
# logRR.perc.30 = a*(1-perchange.prot[1])
# 
# if (orig.subset$risk.factor == "red.meat.unproc" | orig.subset$risk.factor == "red.meat.proc"| orig.subset$risk.factor == "ssb"| orig.subset$risk.factor == "sodium") logRR.perc.40 = a*(1+perchange.harm[2]) else
# logRR.perc.40 = a*(1-perchange.prot[2])
# 
# if (orig.subset$risk.factor == "red.meat.unproc" | orig.subset$risk.factor == "red.meat.proc"| orig.subset$risk.factor == "ssb"| orig.subset$risk.factor == "sodium") logRR.perc.50 = a*(1+perchange.harm[3]) else
# logRR.perc.50 = a*(1-perchange.prot[3])
# 
# if (orig.subset$risk.factor == "red.meat.unproc" | orig.subset$risk.factor == "red.meat.proc"| orig.subset$risk.factor == "ssb"| orig.subset$risk.factor == "sodium") logRR.perc.60 = a*(1+perchange.harm[4]) else
# logRR.perc.60 = a*(1-perchange.prot[4])
# 
# if (orig.subset$risk.factor == "red.meat.unproc" | orig.subset$risk.factor == "red.meat.proc"| orig.subset$risk.factor == "ssb"| orig.subset$risk.factor == "sodium") logRR.perc.70 = a*(1+perchange.harm[5]) else
# logRR.perc.70 = a*(1-perchange.prot[5])
# 
# if (orig.subset$risk.factor == "red.meat.unproc" | orig.subset$risk.factor == "red.meat.proc"| orig.subset$risk.factor == "ssb"| orig.subset$risk.factor == "sodium") logRR.perc.80 = a*(1+perchange.harm[6]) else
# logRR.perc.80 = a*(1-perchange.prot[6])
# 
# if (orig.subset$risk.factor == "red.meat.unproc" | orig.subset$risk.factor == "red.meat.proc"| orig.subset$risk.factor == "ssb"| orig.subset$risk.factor == "sodium") logRR.perc.92.5 = a*(1+perchange.harm[7]) else
# logRR.perc.92.5 = a*(1-perchange.prot[7])
# 
# # compile the coefficients from the "percentchange" method as rows of a matrix
# matrix.perchange[1,j] = logRR.perc.30
# matrix.perchange[2,j] = logRR.perc.40
# matrix.perchange[3,j] = logRR.perc.50
# matrix.perchange[4,j] = logRR.perc.60
# matrix.perchange[5,j] = logRR.perc.70
# matrix.perchange[6,j] = logRR.perc.80
# matrix.perchange[7,j] = logRR.perc.92.5

for(ll in 1:dim(matrix.perchange)[1])
{
  matrix.perchange[ll,j] <- a*(1-perchange[ll])
}



}
# exponentiate the matrices of logRRs

matrix.perchange.exp= exp(matrix.perchange)
#matrix.fits.exp = exp(matrix.fits)

for (k in 1:7)  {

#condensemean[k]= mean(matrix.fits[k,], na.rm=TRUE)
#condensesd[k] = sd(matrix.fits[k,], na.rm = TRUE)
#condensemean.exp[k]= mean(matrix.fits.exp[k,], na.rm=TRUE)
#condensesd.exp[k] = sd(matrix.fits.exp[k,], na.rm = TRUE)

condensemean2[k]= mean(matrix.perchange[k,], na.rm=TRUE)
condensesd2[k] = sd(matrix.perchange[k,], na.rm = TRUE)
condensemean2.exp[k]= mean(matrix.perchange.exp[k,], na.rm=TRUE)
condensesd2.exp[k] = sd(matrix.perchange.exp[k,], na.rm = TRUE)           
}

age = c(30, 40, 50, 60, 70, 80, 92.5)

final = matrix(NA, length(age), 5)
final[,1] = age
#final[,2] = condensemean
#final[,3] = condensesd
final[,2] = condensemean2
final[,3] = condensesd2
#final[,6] = condensemean.exp
#final[,7] = condensesd.exp
final[,4] = condensemean2.exp
final[,5] = condensesd2.exp


final=data.frame(final)
final$midage= final$X1
#final$logRR.avslope=final$X2  ### note, you may have to edit the code here a bit to put the appropriate varname on the correct column since the avslope method is no longer used, and the related output vars are irrelevant.
#final$se.avslope=final$X3
final$logRR.perchange=final$X2
final$se.perchange=final$X3
#final$logRR.avslope.exp=final$X6
#final$se.avslope.exp=final$X7
final$logRR.perchange.exp=final$X4
final$se.perchange.exp=final$X5
final$riskfactor=orig.subset$risk.factor
final$outcome=orig.subset$outcome
final$event.age= orig.subset$event.age
final$origlogRR = orig.subset$logRR

final=subset(final, select=c(riskfactor, outcome, midage, logRR.perchange, se.perchange, logRR.perchange.exp, se.perchange.exp, event.age, origlogRR))
#} # close loop here just for testing purposes


####################Simulate values for 75-100 group, cut the 75-85 group, and kill the 85+ group.
n.sims<-5000
n.draws<-1
#pred<-list()
#mean.est<-c()
se.est<-c()
#estimates<-c()
predicted<-c()
  for(ii in 1:n.sims)
  {
    draws<-c()
    age<-c()
    for(jj in 1:dim(final)[1])
    {
      draws<-c(draws, rnorm(n=n.draws, mean=final[["logRR.perchange"]][jj], 
                            sd=final[["se.perchange"]][jj]))
      age<-c(age, rep(final$midage[jj], times=n.draws))
    }
    model<-lm(draws~age)
    predicted[ii]<-model$coeff %*% c(1, 87.5)
  }
  #pred[[ii]]<-predicted
  mean.est<-mean(predicted)
  se.est<-sd(predicted)
  mean.est.exp<-exp(mean.est)
  se.est.exp<-se.est*exp(mean.est)
  #estimates<-c(estimates, mean.est[ii], se.est[ii])

  final$midage[final$midage==80]<-87.5
  final$logRR.perchange[final$midage==87.5]<-mean.est
  final$se.perchange[final$midage==87.5]<-se.est
  final$logRR.perchange.exp[final$midage==87.5]<-mean.est.exp
  final$se.perchange.exp[final$midage==87.5]<-se.est.exp

  final<-final[final$midage!=92.5,]

##########################################################

### make sure to make a new "intermediatesX" folder before rerunning.
setwd("C:\\Users\\Fred Cudhea\\Box Sync\\new life\\USmortality\\RRsByFoodAndDisease")
write.csv(final, file = paste(rflist[r], "-", outcomelist[r], "-RRextrapolated.csv", sep='') )

} # close loop here when actually running the code

#add TSTK rows with aribtrary food outcome with 0s. Otherwise, code won't run.
TSTK.file.empty<-read.csv(paste(rflist[1], "-", outcomelist[1], "-RRextrapolated.csv", sep='')) 
TSTK.file.empty$outcome<-"TSTK"
start<-which(names(TSTK.file.empty)=="logRR.perchange")
TSTK.file.empty[,start:dim(TSTK.file.empty)[2]]<-0

filenames <- list.files(path = "C:\\Users\\Fred Cudhea\\Box Sync\\new life\\USmortality\\RRsByFoodAndDisease")
diet.rr.final = do.call("rbind", lapply(filenames, read.csv, header = TRUE))

##tack on tstk TSKT.file.empty to diet.rr.final so that final RR file will have TSTK columns
diet.rr.final<-rbind(diet.rr.final, TSTK.file.empty)




#get rid of non-fatal outcomes we don't use them here.
#diet.rr.final<-diet.rr.final[diet.rr.final$outcome != "IHD-nFTL",]
#diet.rr.final$outcome[diet.rr.final$outcome=="IHD-FTL"]<-"IHD"
##For get, just did it all by hand.

#rename DIAB.adiposity.adj to DIAB for outcome name consistency, for main analysis
#also get rid of DIAB.adiposity.unadj as they will not be used for main analysis

diet.rr.final.main.analysis<-diet.rr.final
diet.rr.final.main.analysis$outcome[diet.rr.final.main.analysis$outcome=="DIAB.adiposity.adj"]<-"DIAB"
diet.rr.final.main.analysis$outcome[diet.rr.final.main.analysis$outcome=="IHD.adiposity.adj"]<-"IHD"
diet.rr.final.main.analysis<-diet.rr.final.main.analysis[diet.rr.final.main.analysis$outcome!="DIAB.adiposity.unadj",]

diet.rr.final.sensitivity.analysis<-diet.rr.final
diet.rr.final.sensitivity.analysis$outcome[diet.rr.final.sensitivity.analysis$outcome=="DIAB.adiposity.unadj"]<-"DIAB"
diet.rr.final.sensitivity.analysis$outcome[diet.rr.final.sensitivity.analysis$outcome=="IHD.adiposity.adj"]<-"IHD"
diet.rr.final.sensitivity.analysis<-diet.rr.final.sensitivity.analysis[diet.rr.final.sensitivity.analysis$outcome!="DIAB.adiposity.adj",]

setwd("C:\\Users\\Fred Cudhea\\Box Sync\\new life\\USmortality\\")
write.csv(diet.rr.final, file="final_diet_RRs_agePatterns.csv") #not used as input, just for show
write.csv(diet.rr.final.main.analysis, file="final_diet_RRs_MainAnalysis.csv")    # note: need to put this file in another folder before rerunning code due to the rbind command above
write.csv(diet.rr.final.sensitivity.analysis, file="final_diet_RRs_SensitivityAnalysis.csv")    # note: need to put this file in another folder before rerunning code due to the rbind command above


