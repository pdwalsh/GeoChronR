#'@export
#'@author Deborah Khider
#'@author Andrew Parnell
#'@author Nick McKay
#'@family Bchron
#'@title Generate a Bayesian Reconstruction Age Model  (Bacon) and add it into a LiPD object
#'@description This is a high-level function that uses Bchron to simulate an age model, and stores this as an age-ensemble in a model in chronData. If needed input variables are not entered, and cannot be deduced, it will run in interactive mode. See Haslett and Parnell (2008) doi:10.1111/j.1467-9876.2008.00623.x for details.
#'@param L a single LiPD object
#'@param which.chron the number of the chronData object that you'll be working in
#'@param site.name the name of the site
#'@param modelNum which chronModel do you want to use?
#'@param calCurves The calibration curves to be used. Enter either "marine13", intcal13", "shcal13" or "normal". Will prompt if not provided.
#'@return L. The single LiPD object that was entered, with methods, ensembleTable, summaryTable and distributionTable added to the chronData model.
#'@import Bchron
#'@examples
#'Run in interactive mode:
#'L = runBchron(L)
#'
#'Run in noninteractive mode:
#'L = runBchron(L,which.chron = 1, site.name = "MyWonderfulSite", modelNum = 3, calCurves = "marine13") 

runBchron =  function(L,which.chron=NA,which.table = NA,site.name=L$dataSetName,modelNum=NA, calCurves = NA,reject = NA,interpolate = NA,iter = NA,extractDate = NA,labIDVar="labID", age14CVar = "age14C", age14CuncertaintyVar = "age14CUnc", ageVar = "age",ageUncertaintyVar = "ageUnc", depthVar = "depth", reservoirAge14CVar = "reservoirAge",reservoirAge14CUncertaintyVar = "reservoirAge14C",rejectedAgesVar="rejected",paleoDepthVar = "depth"){
  
  
  cur.dir = getwd()
  
  #initialize which.chron
  if(is.na(which.chron)){
    if(length(L$chronData)==1){
      which.chron=1
    }else{
      which.chron=as.integer(readline(prompt = "Which chronData do you want to run Bchron for? "))
    }
  }
  
  
  #initialize model number
  if(is.na(modelNum)){
    if(is.null(L$chronData[[which.chron]]$model[[1]])){
      #no models, this is first
      modelNum=1
    }else{
      print(paste("You already have", length(L$chronData[[which.chron]]$model), "chron model(s) in chronData" ,which.chron))
      modelNum=as.integer(readline(prompt = "Enter the number for this model- will overwrite if necessary "))
    }
  }
  
  #pull out chronology
  C=L$chronData[[which.chron]]
  
  # Prompt the user for the calibration curve
  if(is.na(calCurves)){
    possible_curve = c("marine13","intcal13","shcal13","normal")
    print("You haven't specified a calibration curve")
    for (i in seq(from=1, to=length(possible_curve), by =1)){
      print(paste(i,": ",possible_curve[i]))}
    calCurves = possible_curve[as.integer(readline(prompt = "Enter the number of the calibration curve you'd like to use: "))]
  }
  
  #check for measurementTables
  #initialize table number
  if(is.na(which.table)){
    if(length(C$measurementTable)==1){
      #no models, this is first
      which.table=1
    }else if(length(C$measurementTable)>=1){
      which.table=as.integer(readline(prompt = "Which chron measurementTable do you want to use?"))
    }else{
      stop("Bchron requires at least one measurementTable")
    }
  }
  
  
  MT=C$measurementTable[[which.table]]
  
  #go through required fields for BChron
  
  #14C age
  print("Looking for radiocarbon ages...")
  print("If using the normal calibration option, point to the U/Th ages")
  c14i = getVariableIndex(MT,age14CVar)
  if (is.na(c14i)){
    stop("Bchron requires ages.")
  }else{
    age14C <- MT[[c14i]]$values}
  # Make sure this is in yr BP and not kyr
  if (mean(age14C, na.rm = TRUE)<10){
    age14C = 1000*age14C
  }
  
  #14C age uncertainty
  print("Looking for radiocarbon age uncertainty...")
  print("If using the normal calibration option, point to the U/Th ages uncertainty")
  c14unci = getVariableIndex(MT,age14CuncertaintyVar,altNames = c("age","uncertainty"))
  
  #check if they want to estimate from a range
  if (is.na(c14unci)){
    print("There is still no uncertainty entered. Would you like to estimate uncertainty from a high/low range?")
    est = readline(prompt = "There is still no uncertainty entered. Would you like to estimate uncertainty from a high/low range? (y/n) ")
    if(est == "y"){
      hi.in <- getVariableIndex(MT,"age14CuncertaintyHigh",altNames = c("hi"))
      hi <- MT[[hi.in]]$values
      lo.in <- getVariableIndex(MT,"age14CuncertaintyLow",altNames = c("lo"))
      lo <- MT[[lo.in]]$values
      age14Cuncertainty <- estimateUncertaintyFromRange(MT,hi.in,lo.in)$unc.estimate$values
    }else{
      print("No radiocarbon age uncertainty given in the chron measurement table, please enter an estimate")
      age14Cuncertainty = as.numeric(readline(prompt = "Enter the radiocarbon age uncertainty in years: "))
    }
  }else{
    age14Cuncertainty <- MT[[c14unci]]$values
  }
  
  
  
  # Make sure the uncertainties are reported in years as well
  if (mean(age14Cuncertainty, na.rm = TRUE)<5){
    age14Cuncertainty = 1000*age14Cuncertainty
  }
  
  #age (calibrated)
  print("Looking for calibrated ages...")
  agei = getVariableIndex(MT,ageVar,altNames = "age")
  if (is.na(agei)){
    print("No calibrated age given in the chron measurement table")
  }else{
    calibratedAge <- MT[[agei]]$values} 
  
  #age uncertainty (calibrated)
  print("Looking for calibrated age uncertainty...")
  ageunci = getVariableIndex(MT,ageUncertaintyVar,altNames = c("age","uncertainty"))
  if (is.na(ageunci)){
    print("No calibrated age uncertainty given in the chron measurement table")
  }else{
    calibratedAgeU <- MT[[ageunci]]$values}
  
  #depth
  print("Looking for depth...")
  depthi = getVariableIndex(MT,depthVar)
  if(is.na(depthi)){
    stop("Depth is required for Bchron")
  }else{
    depth=MT[[depthi]]$values
  }
  
  # #check for duplicate depths
  # while(length(depth)>length(unique(depth))){
  #   i.d <- duplicated(depth)
  #   depth[i.d] <- depth[i.d]+rnorm(n = length(i.d),sd = 0.1)
  # }
  # 
  
  #reservoir age
  # only for marine13
  if (calCurves == 'marine13'){
    which.resi = readline(prompt = "Would you like to use the study's reservoir age (s) or use your own (o)? ")
    if(which.resi == "s"){                      
      print("Looking for radiocarbon reservoir age offsets (deltaR)...")
      print("can also use radiocarbon reservoir ages if need be...")
      resi = getVariableIndex(MT,reservoirAge14CVar,altNames = "reservoir")
      reservoir <-MT[[resi]]$values
      if(is.na(resi)){
        print("The chron measurement table does not contain information about a reservoir age. Please enter your own")
        print("If you don't wish to apply an additional reservoir age correction, please enter 0. The marine 13 curve alreay contains a 400yr reservoir age correction.")
        reservoir = as.numeric(readline(prompt = "Enter the reservoir age in years: "))
      }else{
        print("Below are the values for the reservoir age correction applied in the study: ")
        print(MT[resi]$reservoirAge14C$values)
        subtract.standard = readline(prompt = "Do these values include the standard age correction of 400 years (y/n)?: ")
        if (subtract.standard == 'y'){
          reservoir = reservoir - 400
        }else if(subtract.standard != 'y' && subtract.standard != 'n'){
          stop("Please enter 'y' or 'n'")
        }
      }
    }else if(which.resi=="o"){
      reservoir = as.numeric(readline(prompt = "Enter the reservoir age in years: "))
    }else{stop("Only enter 's' or 'o'")}
  }
  
  #reservoir uncertainty
  # only for marine 13
  if (calCurves == 'marine13'){
    which.resUnci = readline(prompt = "Would you like to use the study's reservoir age uncertainty (s) or use your own (o)? ")
    if(which.resUnci == "s"){                      
      print("Looking for radiocarbon reservoir age uncertainties...")
      resUnci = getVariableIndex(MT,reservoirAge14CUncertaintyVar,altNames = c("reservoir","unc"))
      reservoirUnc <- MT[[resUnci]]$values
      if(is.na(resUnci)){
        print("The chron measurement table does not contain information about reservoir age uncertainty. Please enter your own")
        print("If you don't wish to apply an additional reservoir age correction, please enter 0.")
        reservoirUnc = as.numeric(readline(prompt = "Enter the reservoir age uncertainty in years: "))}
    }else if(which.resUnci == "o"){
      reservoirUnc = as.numeric(readline(prompt = "Enter the reservoir age uncertainty in years: "))
    }else{stop("Only enter 's' or 'o'")}
  }
  
  #rejected ages
  print("Looking for column of reject ages, or ages not included in age model")
  rejeci = getVariableIndex(MT,rejectedAgesVar,altNames = c("reject","ignore"))
  if (is.na(rejeci)){
    print("No ages were rejected in the original study")
    print(age14C)
    print("Warning: Bchron will return an error message if the ages are outside of the calibration curve.")
    if(is.na(reject)){
    reject.anyway  = as.logical(readline(prompt = "Would you like to reject any ages (T/F)? "))
    }else{
      reject.anyway <- reject
    }
    if (reject.anyway){
      rejindex <- c()
      which.rejindex = as.integer(readline(prompt = "Enter the index of the first date you want to ignore: "))
      rejindex <- c(rejindex,which.rejindex)
      while (which.rejindex!=0){
        which.rejindex = as.integer(readline(prompt = "Enter the index of the of the other dates you want to ignore one by one. Enter zero when done: "))
      }
      age14C = age14C[-rejindex]
      age14Cuncertainty = age14Cuncertainty[-rejindex]
      depth = depth[-rejindex]
      if (length(reservoir)>1){
        reservoir = reservoir[-rejindex]
      }
      if (length(reservoirUnc)>1){
        reservoir = reservoirUnc[-rejindex]
      }
    } 
  }
  # ask user if they would rather use the depth from the paleo table
  if(is.na(interpolate)){
  which.depth = readline(prompt = "Would you like to interpolate the age model at the depth horizons for the paleoproxy data? (T/F): " )
  }else{
    which.depth = as.logical(interpolate)
  }
  if (!which.depth){
    depth_predict = depth
  }else if (which.depth){
    if(length(L$paleoData)==1){
      which.paleo=1
    }else if(is.na(which.paleo)){
      which.paleo=as.integer(readline(prompt = "Which paleoData do you want to run Bacon for? "))}
    P = L$paleoData[[which.paleo]]
    PT=P$measurementTable[[1]]
    if(is.null(P)){
      stop("No paleo data measurement table available, please choose another option")}
    print("Looking for depth")
    depthip = getVariableIndex(PT,paleoDepthVar)
    depth_predict <- PT[[depthip]]$values
    if (is.na(depthip)){
      stop("No depth in the measurement table available, please choose another option")}
  }else{stop("Please enter only 'T' or 'F'")}
  
  # Ask the user for the number of iterations
  if(is.na(iter)){
  print("How many iterations would you like to perform?")
  iter = as.integer(readline(prompt = "Enter the number of iterations: "))
  }
  if (iter<10000){
    iter =10000
  }else if (iter>1000000){
    print("This is a large number of iterations!!!")
    are_you_sure = readline(prompt = "Do you want to continue (y/n)?: ")
    if (are_you_sure == 'n'){
      stop("Ok, let's get a more reasonable number of iterations.")
    }else if (are_you_sure != 'n' && are_you_sure != 'y'){
      stop("Enter 'y' or 'n'")
    }
  }
  # Ask the user for the year the core has been extracted
  if(is.na(extractDate)){
  extractDate = as.numeric(readline(prompt = "When was this sample taken in years BP? Enter 0 if unknown: "))
  }
  # check that people actually used years BP as asked
  #if (extractDate>1900){extractDate=1950-extractDate}
  
  # Set up everything for the Bchron run
  # if marine13 is selected, make the necessary adjustmenet
  if (calCurves == "marine13"){
    #remove the reservoir age correction from the 14C ages
    ages = age14C - reservoir
    # calculate the uncertainty due to the radiocarbon measurement and the reservoir age correction
    age_sds = sqrt(age14Cuncertainty^2 + reservoirUnc^2)
    
    # perform one more check to make sure that the dates are in the calibration range of the selected 
    max_ages = ages-3*age_sds
    min_ages = ages+3*age_sds
    index_out = which(max_ages<=400 | min_ages>=35000)
    
    if (!is.null(index_out)){
      ages = ages[-index_out]
      age_sds = age_sds[-index_out]
      depth = depth[-index_out]
    } 
  }else {
    ages = age14C
    age_sds = age14Cuncertainty
  }
  
  # Perfom the run (finally)
  if (extractDate !=0){
    run = Bchron::Bchronology(ages = ages, ageSds = age_sds, calCurves = c(rep(calCurves,length(depth))), positions = depth, predictPositions = depth_predict, iterations = iter, extractDate = extractDate,positionThicknesses = c(rep(1,length(depth))),jitterPositions = TRUE )
  } else {
    run = Bchron::Bchronology(ages = ages, ageSds = age_sds, calCurves = c(rep(calCurves,length(depth))), positions = depth, predictPositions = depth_predict, iterations = iter,positionThicknesses = rep(1,length(depth)),jitterPositions = TRUE)
  }
  
  # Write back into a LiPD file
  
  # Create the place holder for the LiPD fil
  # Grab the methods first
  methods = list()
  methods$algorithm = 'Bchron'
  
  
  #write it out
  
  L$chronData[[which.chron]]$model[[modelNum]]=list(methods=methods)
  
  
  # Ensemble table since it's easy to access in Bchron
  ageEns = list()
  ageEns$ageEnsemble$values = t(run$thetaPredict)
  ageEns$ageEnsemble$units = 'yr BP'
  ageEns$depth$values = depth_predict
  ageEns$depth$units = MT[[depthi]]$units
  
  L$chronData[[which.chron]]$model[[modelNum]]$ensembleTable[[1]]=ageEns
  
  #Probability distribution table
  for (i in seq(from=1, to=length(run$calAges), by =1)){
    distTable=list()
    distTable$depth = run$calAges[[i]]$positions
    distTable$depthunits ='cm'
    distTable$calibrationCurve = calCurves
    distTable$age14C = run$calAges[[i]]$ages
    distTable$sd14C = run$calAges[[i]]$ageSds
    distTable$probabilityDensity$variableName = "probabilityDensity"
    distTable$probabilityDensity$values = run$calAges[[i]]$densities
    distTable$probabilityDensity$units = NA
    distTable$probabilityDensity$description = "probability density that for calibrated ages at specific ages"
    distTable$age$values = run$calAges[[i]]$ageGrid
    distTable$age$units = "yr BP"
    distTable$age$variableName <- "age"
    
    # write it out
    L$chronData[[which.chron]]$model[[modelNum]]$distributionTable[[i]]=distTable
  }
  
  # Summary Table
  sumTable = list()
  sumTable$depth$values = depth
  sumTable$depth$units = "cm"
  
  sumTable$meanCalibratedAge$values = rowMeans(t(run$theta))
  sumTable$meanCalibratedAge$units = "yr BP"
  
  L$chronData[[which.chron]]$model[[modelNum]]$summaryTable[[1]]=sumTable
  
  return(L)
  
}

