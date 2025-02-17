##Get RRs for 75+ group via regressing simulated log(RRs) multiple times
set.seed(15)

setwd("C:\\Users\\Fred Cudhea\\Box Sync\\US Diet-CVD CRA\\3. Diet-Disease Pairs & RRs\\2. RRs\\Mediated RRs_BMI-SBP")

SBP_RRs<-read.csv("rr_sbp_edited.csv")
SBP_RRs<-SBP_RRs[1:(dim(SBP_RRs)[1]/2),]
n.sims<-5000
n.draws<-1
pred<-list()
mean.est<-c()
se.est<-c()
estimates<-c()
disease.names<-names(SBP_RRs)[seq(from=4, to=(dim(SBP_RRs)[2]-1), by=2)]
disease.names.se<-names(SBP_RRs)[seq(from=5, to=(dim(SBP_RRs)[2]-1), by=2)] 
for(k in 1:length(disease.names))
{
  predicted<-c()
  for(i in 1:n.sims)
  {
    draws<-c()
    age<-c()
    for(j in 1:dim(SBP_RRs)[1])
    {
      draws<-c(draws, rnorm(n=n.draws, mean=SBP_RRs[[disease.names[k]]][j], 
                            sd=SBP_RRs[[disease.names.se[k]]][j]))
      age<-c(age, rep(SBP_RRs$agemid[j], times=n.draws))
    }
    model<-lm(draws~age)
    predicted[i]<-model$coeff %*% c(1, 87.5)
  }
  pred[[k]]<-predicted
  mean.est[k]<-mean(predicted)
  se.est[k]<-sd(predicted)
  estimates<-c(estimates, mean.est[k], se.est[k])
}
SBP_RRs[6,3]<-87.5
SBP_RRs[6,3+1:length(estimates)]<-estimates
SBP_RRs<-SBP_RRs[SBP_RRs$agemid!=92.5,]
write.csv(x=SBP_RRs, file="rr_sbp_edited_SimulatedBetas75Plus.csv")


##############################same but for bmi##########
BMI_RRs<-read.csv("rr_bmi_cvd_diab_newformat.csv")
BMI_RRs<-BMI_RRs[1:(dim(BMI_RRs)[1]/2),]
n.sims<-5000
n.draws<-1
pred<-list()
mean.est<-c()
se.est<-c()
estimates<-c()
disease.names<-names(BMI_RRs)[seq(from=4, to=length(names(BMI_RRs)), by=2)]
disease.names.se<-names(BMI_RRs)[seq(from=5, to=length(names(BMI_RRs)), by=2)] 
for(k in 1:length(disease.names))
{
  predicted<-c()
  for(i in 1:n.sims)
  {
    draws<-c()
    age<-c()
    for(j in 1:dim(BMI_RRs)[1])
    {
      draws<-c(draws, rnorm(n=n.draws, mean=BMI_RRs[[disease.names[k]]][j], 
                            sd=BMI_RRs[[disease.names.se[k]]][j]))
      age<-c(age, rep(BMI_RRs$agemid[j], times=n.draws))
    }
    model<-lm(draws~age)
    predicted[i]<-model$coeff %*% c(1, 87.5)
  }
  pred[[k]]<-predicted
  mean.est[k]<-mean(predicted)
  se.est[k]<-sd(predicted)
  estimates<-c(estimates, mean.est[k], se.est[k])
}
BMI_RRs[6,3]<-87.5
BMI_RRs[6,3+1:length(estimates)]<-estimates
BMI_RRs<-BMI_RRs[BMI_RRs$agemid!=92.5,]
write.csv(x=BMI_RRs, file="rr_bmi_edited_SimulatedBetas75Plus.csv")

BMI_RRs_sensitivity<-BMI_RRs
BMI_RRs_sensitivity$DIAB<-0
BMI_RRs_sensitivity$DIABse<-0
write.csv(x=BMI_RRs_sensitivity, file="rr_bmi_edited__sensitivity_SimulatedBetas75Plus.csv")


#BMI_RRs[6:7,]

#names(SBP_RRs)[seq(from=4, to=(dim(SBP_RRs)[2]-1), by=2)]
