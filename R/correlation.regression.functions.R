#' @export
#' @title Estimate Auto-Regressive coefficient at 1-timesetep
#' @description estimates ar1 using the arima() function
#' @author Julien Emile-Geay
#' @param X a 1-column matrix or numeric dataset
#' @return ar coefficient estimate of ar1
ar1 = function(X){
  fit = arima(x = X, order = c(1, 0, 0))
  return(fit$coef[[1]])
}

#' @export
#' @title Correlations and their significance according to AR(1) benchmarks
#' @description Fits AR(1) model to two series X & Y 
#' @author Julien Emile-Geay
#' @param X a 1-column vector
#' @param Y a 1-column vector of the same 
#' @param alpha level of the test (probability of a type I error)
#' @param nsim number of simulations
#' @return output
corrIsopersist = function(X,Y,alpha=0.05,nsim=100){
  nx = length(X)
  ny = length(Y)
  rhoXY = cor(X,Y)
  # set warning if nx != ny  
  
  tdum = 1:nx  # dummy time axis
  # generate AR(1) surrogates
  ar1X = ar1Surrogates(tdum,X,detrend_bool=TRUE,method='redfit',nens=nsim)  
  ar1Y = ar1Surrogates(tdum,Y,detrend_bool=TRUE,method='redfit',nens=nsim)
  #  compute correlations
  cor.mat1 = cor(X,ar1Y,use="pairwise.complete.obs") # X vs Y-like noise
  cor.mat2 = cor(Y,ar1X,use="pairwise.complete.obs") # Y vs X-like noise
  cor.mat = cbind(cor.mat1,cor.mat2)  # bind together
  rho = cor.mat[1,]  # take absolute value
  #  compute sampling distribution 
  rho_dens <- stats::density(rho,from=-1,to=1) # estimate density
  rho_cdf  <- spatstat::CDF.density(rho_dens) # turn into CDF
  #rho_cdf <- ecdf(rho)  # this is the empirical way; OK if large ensemble
  # estimate test p-value
  pval = 1-rho_cdf(abs(rhoXY))
  # prepare output list
  isopersist.out$p-value = pval
  isopersist.out$rho = rhoXY
  
  return(isopersist.out)
}



#' @export
#' @title Estimate effective sample size accounting for autocorrelation
#' @description Bretherton et al., 1999 estimate of effective sample size.
#' @author Nick McKay
#' @param X a 1-column matrix or numeric dataset
#' @param Y a 1-column matrix or numeric dataset of the same length as X
#' @return estimate of the effective sample size
effectiveN = function(X,Y){
  #from Bretherton 1999
  arX = ar1(X)
  n = sum(is.finite(X) & is.finite(Y))
  arY = ar1(Y)
  
  if(arX < 0 | arY < 0 ){#calculation is meaningless if either number is less than 0
    effN=n
  }else{
    effN = n *(1-arX*arY)/(1+arX*arY)
  }
  return(effN)
}

#' @export
#' @title Calculate correlation p-value given sample size. 
#' @description Calculate Pearson p-values accounting for effective sample size
#' @author Nick McKay
#' @param r correlation coefficient
#' @param n sample size
#' @return p-value based on two-tailed t-test
pvalPearsonSerialCorrected = function(r,n){
  #r is the correlation coeffient
  #n is the number of pairwise observations
  Tval = r * sqrt((n-2)/(1-r^2))
  
  #two tailed test
  p = pt(-abs(Tval),df = n-2)*2
  return(p)
  
}
#' @export
#' @title Matrix correlation
#' @description Calculates correlations and associated p-values for two ensemble matrices (or vectors) 
#' @author Nick McKay
#' @author Julien Emile-Geay
#' @param M1 matrix of age-uncertain columns to correlate and calculate p-values
#' @param M2 matrix of age-uncertain columns to correlate and calculate p-values
#' @return out list of correlation coefficients (r) p-values (p) and autocorrelation corrected p-values (pAdj)

corMatrix = function(M1,M2){
  M1=as.matrix(M1)
  M2=as.matrix(M2)
  if(nrow(M1)!=nrow(M2)){stop("M1 and M2 must have the same number of rows")}
  
  p=matrix(NA,nrow = ncol(M1)*ncol(M2))
  pAdj=p;
  r=p
  nens=nrow(p) # number of ensemble members
  pb <- txtProgressBar(min=0,max=nens,style=3)
  print(paste("Calculating",nens,"correlations"))
  
  for(i in 1:ncol(M1)){
    for(j in 1:ncol(M2)){
      #test for singularity
      effN = try(effectiveN(M1[,i],M2[,j]),silent = TRUE)
      if(is.numeric(effN)){
        r[j+ncol(M2)*(i-1)] = cor(M1[,i],M2[,j],use="pairwise")
        pAdj[j+ncol(M2)*(i-1)] = pvalPearsonSerialCorrected(r[j+ncol(M2)*(i-1)],effN)
        p[j+ncol(M2)*(i-1)] = pvalPearsonSerialCorrected(r[j+ncol(M2)*(i-1)],sum(!is.na(M1[,i])&!is.na(M2[,j])))
      }
      setTxtProgressBar(pb, j+ncol(M2)*(i-1))
    }
  }
  
  pAdj[!is.finite(pAdj)]=1#This is for instances whenn NEff <=2. I guess this is a reasonable solution?
  
  # apply false discovery rate procedure to ADJUSTED p-values
  fdrOut =  suppressMessages(fdr(pAdj,qlevel=0.05,method="original",adjustment.method='mean'))
  sig_fdr = matrix(0,nens)
  sig_fdr[fdrOut] = 1 
 
    # Rmks:
    # 1) probably qlevel should be an optional parameter 
    # 2) could silence the FDR screen output
  # export to data frame
  out = data.frame("r"=r,"pSerial"=pAdj,"pRaw"=p,"sig_fdr"=sig_fdr)
  close(pb)
  return(na.omit(out))
}

#' @export
#' @title Simple ordinary least squeares regression
#' @description Simple regression function. Faster than lm()
#' @author Nick McKay
#' @param X a matrix of predictor data
#' @param Y a vector of predictand data
#' @return model coefficients
regress=function (X,Y){
  g=which(!apply(is.na(X),1,any) & !is.na(Y))
  X=X[g,]
  Y=Y[g]
  b=solve(t(X)%*%X)%*%(t(X)%*%Y)  # this is straight up OLS. Why not use lm? - Answer: this is a bit faster computationally. NM.
  return(b)
}


#' @export
#' @title Ensemble regression
#' @description This is the primary function for ensemble regression. It will take ensemble values in time and/or values in the predictor (X), and regress them on ensemble values in time and/or values in Y (the predictand). The function will then apply the ensemble linear model to the full length of X to create a modeled Y. Will also optionally create plots. 
#' @param timeX matrix of age/time ensembles, or single column
#' @param valuesX matrix of values ensembles, or single column
#' @param timeY matrix of age/time ensembles, or single column
#' @param valuesY matrix of values ensembles, or single column
#' @param binvec vector of bin edges for binning step
#' @param binstep spacing of bins, used to build bin step
#' @param binfun function to use during binning (mean, sd, and sum all work)
#' @param max.ens maximum number of ensemble members to regress
#' @param percentiles quantiles to calculate for regression parameters
#' @param recon.binvec bin vector to use for the modeled regression.
#' @param minObs minimum number of points required to calculate regression
#' @return list of ensemble output
#' @author Nick McKay
#' @family regress

regressEns = function(timeX,valuesX,timeY,valuesY,binvec = NA,binstep = NA ,binfun=mean,max.ens=NA,percentiles=c(.025,.25,.50,.75,0.975),recon.binvec=NA,minObs=10){
  #time and values must be "column lists"
  if(!is.list(timeX) | !is.list(timeY) | !is.list(valuesX) | !is.list(valuesY)){
    stop("TimeX and Y and values X and Y must all be ``variable lists'' (output of selectData)")
  }
  
    otx=timeX
    oty=timeY
    ovx=valuesX
    ovy=valuesY

    aligned = alignTimeseriesBin(timeX,valuesX,timeY,valuesY,binvec = binvec,binstep = binstep ,binfun=binfun,max.ens=max.ens,minObs=minObs)
      

  yearX = aligned$yearBins
  binX = aligned$binX
  binY = aligned$binY
  
  #check for a reconstruction binvec
  if(all(is.na(recon.binvec))){
    recon.binvec = seq(min(timeX,na.rm=TRUE),max(timeX,na.rm=TRUE),by=abs(aligned$binstep))
  }
  
  #get full X for the reconstruction
  fullX = binEns(time = as.matrix(timeX$values),values = as.matrix(valuesX$values),binvec = recon.binvec,binfun=binfun,max.ens=max.ens)
  
  
  #how many ensemble members?
  nensPoss = NCOL(binX)*NCOL(binY)
  nens=nensPoss
  

  
  if(!is.na(max.ens)){
    if(max.ens<nensPoss){
      nens=max.ens
    }
  }
  
  randomize=FALSE
  if(nens<nensPoss){#if were examining only a subset of the possible permutations, randomize which ones we sample
    randomize=TRUE
  }
  
  #do the regression...
  m=matrix(NA,ncol = nens)
  b=m
  if(randomize){
    rX = sample.int(NCOL(binX),size = nens,replace = TRUE)
    rY = sample.int(NCOL(binY),size = nens,replace = TRUE)
  }else{
    rX = c(t(matrix(rep(seq(1,NCOL(binX)),times = NCOL(binY)),ncol = NCOL(binY))))
    rY = c(matrix(rep(seq(1,NCOL(binY)),times = NCOL(binX)),ncol = NCOL(binX)))
  }
  
  #ones columns
  ones=matrix(1,nrow = NROW(binX))
  
  #setup progress bar
  pb <- txtProgressBar(min=1,max=nens,style=3)
  print(paste("Calculating",nens,"regressions"))
  
  modeled.Y.mat = matrix(NA,ncol=nens,nrow=NROW(fullX$matrix))
  
  #do the regressions
  for(i in 1:nens){
    
    B=regress(X = cbind(binX[,rX[i]],ones),Y = binY[,rY[i]])
    m[i]=B[1]
    b[i]=B[2]
    
    #calculate reconstruction
    XC=cbind(as.matrix(fullX$matrix[,rX[i]]),matrix(1,nrow=length(as.matrix(fullX$matrix[,rX[i]]))))
    modeled.Y.mat[,i] = XC%*%B 
    
    modeled = list(values = modeled.Y.mat,units = ovy$units, variableName = ovy$variableName, variableType= "inferredVariable")
    
    
    if(i%%100==0){
      setTxtProgressBar(pb, i)
    }
  }
  close(pb)
  
  #calculate some default statistics
  if(!all(is.na(percentiles))){
    ms = sort(m)
    bs = sort(b)
    N=length(ms)
    regStats = data.frame(percentiles,"m" = ms[round(percentiles*N)],"b" = bs[round(percentiles*N)])
    row.names(regStats)=format(regStats$percentiles,digits = 2)
  }
  reg.ens.data=list("m"=m,"b"=b,"regStats"=regStats,"binX"=binX,"binY"=binY,"rX"=rX,"rY"=rY,"modeledY"=modeled.Y.mat,timeX = otx,valuesX= ovx,timeY=oty,valuesY=ovy,modeled = modeled,yearX = yearX,modeledYear = fullX$time)
  
  
  return(reg.ens.data)
  
}


#' @export
#' @title Ensemble correlation
#' @description Primary function for calculating correlation ensembles
#' @author Nick McKay
#' @param time1 matrix of age/time ensembles, or single column
#' @param values1 matrix of values ensembles, or single column
#' @param time2 matrix of age/time ensembles, or single column
#' @param values2 matrix of values ensembles, or single column
#' @param binvec vector of bin edges for binning step
#' @param binstep spacing of bins, used to build bin step
#' @param binfun function to use during binning (mean, sd, and sum all work)
#' @param max.ens maximum number of ensemble members to correlate
#' @param percentiles quantiles to calculate for regression parameters
#' @param minObs minimum number of points required to calculate regression
#' @return list of ensemble output and percentile information
corEns = function(time1,values1,time2,values2,binvec = NA,binstep = NA ,binfun=mean,max.ens=NA,percentiles=c(.025,.25,.5,.75,.975),minObs=10){
  
  #check to see if time and values are "column lists"
  if(is.list(time1)){time1=time1$values}
  if(is.list(time2)){time2=time2$values}
  if(is.list(values1)){values1=values1$values}
  if(is.list(values2)){values2=values2$values}
  
  #make them all matrices
  time1 = as.matrix(time1)
  time2 = as.matrix(time2)
  values1 = as.matrix(values1)
  values2 = as.matrix(values2)
  
  if(nrow(time1) != nrow(values1)){stop("time1 and values1 must have the same number of rows (observations)")}
  if(nrow(time2) != nrow(values2)){stop("time2 and values2 must have the same number of rows (observations)")}
  
  if(all(is.na(binvec))){
    if(is.na(binstep)){
      stop("Either a binvec or binstep must be specified")
    }else{
      #look for common overlap
      binStart=floor(max(c(min(time1,na.rm=TRUE),min(time2,na.rm=TRUE))))
      binStop=ceiling(min(c(max(time1,na.rm=TRUE),max(time2,na.rm=TRUE))))
      print(paste("binning from",binStart,"to",binStop,"..."))
      binvec=seq(binStart,binStop,by=binstep)
    }
  }
  
  #create ensemble bins
  dum = binEns(time = time1,values = values1,binvec = binvec,binfun=binfun,max.ens=max.ens)
  year = dum$time
  bin1 = dum$matrix
  bin2 = binEns(time = time2,values = values2,binvec = binvec,binfun=binfun,max.ens=max.ens)$matrix
  
  #remove columns that have less than minObs datapoints
  good = which(apply(!is.na(bin1),2,sum)>=minObs)
  if(length(good)==0){
    stop(paste("none of the columns have",minObs,"or more datapoints"))
  }
  bin1 = as.matrix(bin1[,good])
  
  
  good = which(apply(!is.na(bin2),2,sum)>=minObs)
  if(length(good)==0){
    stop(paste("none of the columns have",minObs,"or more datapoints"))
  }
  bin2 = as.matrix(bin2[,good])
  
  
  
  #calculate the correlations
  #cormat=c(cor(bin1,bin2,use = "pairwise"))  #faster - but no significance...
  
  cor.df = corMatrix(bin1,bin2)

  #and the significance
  #pairwise observations
  
  
  #calculate some default statistics
  if(!all(is.na(percentiles))){
    pctl = quantile(cor.df$r,probs = percentiles)
    corStats = data.frame(percentiles,"values" = pctl)
    #row.names(corStats)=format(corStats$percentiles,digits = 2) # it appears that the rows are already well formatted
    corEns.data=list(cor.df = cor.df,corStats = corStats)
    
  }else{
    corStats=NA
    corEns.data=list(cor.df = cor.df)
  }
  
  return(corEns.data)
  
}


#' @export
#' @title Bin ensemble data
#' @description takes ensembles in time and/or values and creates a matrix of data for future analysis
#' @param time single column vector of time
#' @param values single column vector of values to bin
#' @param binvec vector of bin edges for binning step
#' @param binstep spacing of bins, used to build bin step
#' @param binfun function to use during binning (mean, sd, and sum all work)
#' @param max.ens maximum number of ensemble members to regress
#' @return list that includes matrix of binned data and binned time

binEns = function(time,values,binvec,binfun=mean,max.ens=NA){
  
  time = as.matrix(time)
  values = as.matrix(values)
  
  #if it's an age ensemble only
  if(ncol(time)>1 & ncol(values)==1){
    if(!is.na(max.ens)){
      if(max.ens<ncol(time)){
        time=time[,1:max.ens]
      }
    }
    binMat = apply(time,MARGIN = 2,function(x) bin(time = x,values = values,binvec = binvec,binfun = binfun)$y)
    
    #if it's a value ensemble only
  }else if(ncol(time)==1 & ncol(values)>1){
    if(!is.na(max.ens)){
      if(max.ens<ncol(values)){
        values=values[,1:max.ens]
      }
    }
    binMat = apply(values,MARGIN = 2,function(x) bin(time = time,values = x,binvec = binvec,binfun = binfun)$y)
    
    #if it's a value AND age ensemble
  }else if(ncol(time)>1 & ncol(values)>1){
    nx = ncol(time)
    ny = ncol(values)
    if(!is.na(max.ens)){
      nens=min(max(nx,ny),max.ens)
    }else{
      nens = max(nx,ny)
    }
    if(nx>=ny){
      binMat = apply(time[,1:nens],MARGIN = 2,function(x) bin(time = x,values = values[,sample.int(ny,size=1)],binvec = binvec,binfun = binfun)$y)
    }else{
      binMat = apply(values[,1:nens],MARGIN = 2,function(x) bin(time = time[,sample.int(nx,size=1)],values = x,binvec = binvec,binfun = binfun)$y)
    }
    
    #both are single values
  }else{
    #just regular bin
    binMat = bin(time = time,values = values,binvec = binvec,binfun = binfun)$y
  }
  
  binMat = as.matrix(binMat)
  bin_x = apply(cbind(binvec[-1],binvec[-length(binvec)]),1,mean)
  binned=list("time"=bin_x,"matrix" = binMat)
  return(binned)
  
}

#' @export
#' @title Bin Data
#' @description function that puts data into appropriate bins, based on the time and the binning vector the bin vector describes the edges of the bins
#' @param time vector of time
#' @param values vector of values to bin
#' @param binvec vector of bin edges for describing where to bin
#' @param binfun function to use during binning (mean, sd, and sum all work)
#' @author Nick McKay
#' @return A data.frame of (x) binned time, and (y) binned values
bin = function(time,values,binvec,binfun = mean){
  #function that puts data into appropriate bins, based on the time and the binning vector
  #the bin vector describes the edges of the bins
  #binfun is the function to use for the binning, mean, sum, sd are all reasonable options
  bin_y = rep(NA,times = length(binvec)-1)
  bin_x = apply(cbind(binvec[-1],binvec[-length(binvec)]),1,mean)
  
  for(i in 1:length(bin_y)){
    q = which(time > binvec[i] & time <= binvec[i+1])
    bin_y[i] = binfun(values[q],na.rm=TRUE)
  }
  
  binned = data.frame(x=bin_x,y=bin_y)
  return(binned)
}


#' @export
#' @title Bin every entry in a Timeseries object
#' @description Aggregate data from a timeseries object into the same timeline through binning. 
#' @param TS LiPD timeseries object See \url{http://nickmckay.github.io/LiPD-utilities/r/index.html#what-is-a-time-series}
#' @param binvec vector of bin edges for describing where to bin
#' @param binfun function to use during binning (mean, sd, and sum all work)
#' @param max.ens Maximum number of ensemble members.
#' @param na.col.rm Remove columns that are all NAs? (TRUE or FALSE)
#' @author Nick McKay
#' @return A list of binned years and values.
binTs = function(TS,timeVar="ageEnsemble",binvec,binfun = mean,max.ens=1000,na.col.rm=TRUE){
  timeList = lapply(TS,"[[",timeVar)
  valueList = lapply(TS,"[[","paleoData_values")
  
  binMat = vector(mode="list",length = length(timeList))
  pb <- txtProgressBar(min=1,max=length(timeList),style=3)
  
  for(i in 1:length(timeList)){
    binMat[[i]]=binEns(time = timeList[[i]],values = valueList[[i]],binvec = binvec,max.ens = max.ens,binfun = binfun)
    if(na.col.rm){
      allNa=which(apply(is.na(binMat[[i]]$matrix),2,all) | apply(is.nan(binMat[[i]]$matrix),2,all) | apply(binMat[[i]]$matrix=="nan",2,all))
      if(length(allNa)>0){
        binMat[[i]]$matrix = binMat[[i]]$matrix[,-allNa]
      }
    }
    
    setTxtProgressBar(pb,i)
  }
  close(pb)
  return(binMat)  
  
}

