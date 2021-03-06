# Eric Crandall March 2015 - These commands should be helpful in running the scripts in DIPnet_Stats_Functions.R
# Relevant Links:
# Interesting discussion about calculating Fst in R: http://www.molecularecologist.com/2012/05/calculating-pair-wise-unbiased-fst-with-r/
#Command to install all packages except iNext: install.packages(c("seqinr","ape","pegas","heirfstat,"mmod","adegenet","plyr","strataG"))
##To install iNEXT##
# install.packages('devtools')
# library(devtools)
# install_github('JohnsonHsieh/iNEXT')
setwd("~/github/popgenDB/output")

#Load libraries and source the functions
library(seqinr)  #might have to download .tgz file directly from CRAN site and install locally, not directly from CRAN repository
library(ape)  
library(pegas)
library(hierfstat)
library(mmod)
library(adegenet)
library(plyr)
library(strataG)
library(iNEXT)


#set the working directory and source stuff

#source("DIPnet_Stats_Functions.R")
#source("config.R")
source("../DIPnet_Stats_Functions.R")
source("../config.R")

##READING IN THE DATA. ##
#need to turn off the quoting with quote="" for it to read correctly. 

ipdb<-read.table(ipdb_path,sep="\t",header=T,stringsAsFactors = F,quote="", na.strings=c("NA"," ","")) 


#read in geographical regionalizations from Treml
spatial<-read.table(spatial_path, header=T, sep="\t",stringsAsFactors = F, na.strings=c("NA"," ",""), quote="")

#read in geographical regionalizations from Beger
spatial2<-read.table(spatial2_path, header=T,sep="\t", stringsAsFactors = F, na.strings=c("NA"," ",""), quote="")

#read in ABGD groups
abgd<-read.table(abgd_path, header=T, sep="\t", stringsAsFactors = F)

#join spatial
ipdb<-join(ipdb,spatial, by = "IPDB_ID",type = "left")
ipdb<-join(ipdb,spatial2[,c(2,18:24)], by = "IPDB_ID", type = "left")

#join ABGD
ipdb<-join(ipdb,abgd[,c(1,3)], by = "IPDB_ID",type = "left")

#CHECK FOR DUPLICATES
#dups<-ipdb[duplicated(ipdb),]
#ipdb<-ipdb[!duplicated(ipdb),]  #remove duplicates if you need to


# drop IDs of highly divergient individuals likely to be hybrids, cryptic species, etc.Drop IDs are stored in DIPnet_Stats_Functions.R

ipdb<-ipdb[ipdb$IPDB_ID %in% drops == FALSE, ] 

# Remove Invasive Species and Dolphins!!!



#CHECK FOR MISSING LOCALITIES
#table(ipdb$principalInvestigator[which(is.na(ipdb$locality))])
#ipdb$locality[which(is.na(ipdb$locality))]<-"no_name"  #give "no_name" to NA localities

#subset by species (or whatever else) if necessary
#zebfla<-subset(ipdb, Genus_species_locus == "Zebrasoma_flavescens_CYB" )

####Examples###
###Diversity Stats Function###
#Computes diversity stats by species and population for a flatfile of mtDNA sequences and metadata (with required fields $Genus_species_locus and $loc_lat_long)
# minseqs = minimum sequences per sampled population, 
# minsamps = minimum sampled populations per species (after pops with n < minseqs have been removed)
# mintotalseqs = minimum sampled sequences per species (after pops with n < minseqs have been removed)
# To be added: rarefaction, Fus Fs, Fu and Li's D
divstats<-genetic.diversity.mtDNA.db(ipdb=ipdb, basic_diversity = T, sequence_diversity = T, coverage_calc = F, coverage_correction = F, minseqs = 6, minsamps = 3, mintotalseqs = 0, ABGD=F,regionalization = "sample", keep_all_gsls=F, mincoverage = 0.4, hill.number = 0)

###Pairwise Genetic Structure Function###
#Computes genetic differentiation statistics by species and population for a flatfile of mtDNA sequences and metadata (with required fields $Genus_species_locus and $loc_lat_long)
# gdist = You must choose one genetic distance to calculate: choose gdist from:"Nei GST", "Hedrick G'ST", "Jost D", "WC Theta", "PhiST", "Chi2", or "NL dA"
# minseqs = minimum sequences per sampled population, 
# minsamps = minimum sampled populations per species (after pops with n < minseqs have been removed)
# mintotalseqs = minimum sampled sequences per species (after pops with n < minseqs have been removed)
# nreps = number of resampling permutations for WC Theta, PhiST, Chi2, and NL dA (strataG package). This is working, but you will not currently see p-values in the output, so not much use for now
# num.cores = number of computer cores to devote to computations for WC Theta, PhiST, Chi2, and NL dA (strataG package)
# To be added: option to output square matrices with p-values.
diffstats<-pairwise.structure.mtDNA.db(ipdb=ipdb, gdist = "PhiST", minseqs = 5, minsamps = 3, mintotalseqs = 0, nrep = 0, num.cores = 1, ABGD = F, regionalization = "ECOREGION")


###Hierarchical Genetic Structure Function###
#Computes heigenetic differentiation statistics by species and population for a flatfile of mtDNA sequences and metadata (with required fields $Genus_species_locus and $loc_lat_long)
# minseqs = minimum sequences per sampled population, 
# minsamps = minimum sampled populations per species (after pops with n < minseqs have been removed)
# mintotalseqs = minimum sampled sequences per species (after pops with n < minseqs have been removed)
# nperm = number of AMOVA permutations
# model= model of molecular evolution to be passed to dna.dist() = c("raw", "N", "TS", "TV", "JC69", "K80", "F81", "K81", "F84", "BH87", "T92", "TN93", "GG95", "logdet", "paralin", "indel", "indelblock")
# model defaults to "N" which is the raw count of differences ("raw" is the proportion- same thing). If you use model = "none" you will get all distances between haplotypes = 1, which is the same as "regular" FST
# levels can be one of c("sample","fn100id", "fn500id", "ECOREGION", "PROVINCE", "REALM", "EEZ") or new regionalizations as they are added.
hierstats<-hierarchical.structure.mtDNA.db(ipdb = ipdb,level1 = "sample",level2="ECOREGION",model="raw",nperm=1)


#Save diversity stats to file(s)
save(divstats,file="DIPnet_stats_samples_060815.Rdata")
write.stats(divstats,filename="DIPnet_stats_samples_060815.csv",structure=F) # for an excel-readable csv. Ignore warnings. Note this function will not overwrite, it will append to existing files
#write.stats(divstats,"DIPnet_stats_ecoregions_032415.csv",structure=F)

#Save differentiation stats to files
save(diffstats,file="DIPnet_structure_ecoregions_PhiST_072215.Rdata") # for an R object
write.stats(diffstats,filename="DIPnet_structure_ecoregions_PhiST_072215.csv",structure=T) # for an excel-readable csv. Ignore warnings. structure=T for triangular matrices. Note this function will not overwrite, it will append to existing files

#Summarize diversity stats and save to file (loop through a bunch of stats and transpose the matrices)
for(s in c("HaploDiv","SWdiversity","localFST","NucDivLocus","ThetaS","TajD")){
  summary<-summarize_divstats(s,divstats_veron)
  summary2<-as.data.frame(t(summary[,-1]))
  colnames(summary2)<-summary$popname
  write.csv(summary2,file=paste("veron_",s,".csv",sep=""),quote=F)
}


# Loop through all regionalizations and calculate the statistics
for(r in c("sample","ECOREGION", "PROVINCE", "REALM", "EEZ", "fn100id", "fn500id")){
  divstats<-genetic.diversity.mtDNA.db(ipdb=ipdb, basic_diversity = T, sequence_diversity = T, coverage_calc = T, coverage_correction = T, minseqs = 6, minsamps = 3, mintotalseqs = 0, ABGD=F,regionalization = r, keep_all_gsls=F, mincoverage = 0.4, hill.number = 0)
  dir.create(file.path("./",r))
  save(divstats,file=file.path("./",r,paste("DIPnet_stats_Hill0_072115_",r,".Rdata",sep="")))
  write.stats(divstats,filename=file.path("./",r,paste("DIPnet_stats_Hill0_072115_",r,".csv",sep="")),structure=F) # for an excel-readable csv. Ignore warnings. Note this function will not overwrite, it will append to existing files
}


for(r in c("sample","ECOREGION", "PROVINCE", "REALM", "EEZ", "fn100id", "fn500id")){
  for(g in c("WC Theta","PhiST", "Jost D")){
  diffstats<-pairwise.structure.mtDNA.db(ipdb=ipdb, gdist = g, regionalization = r, minseqs = 6, minsamps= 3, mintotalseqs= 0, num.cores = 2)
  #dir.create(file.path("./",r))
  save(diffstats,file=file.path("./",r,paste("DIPnet_structure_060315_",g,"_",r,".Rdata",sep="")))
  write.stats(diffstats,filename=file.path("./",r,paste("DIPnet_structure_060315_",g,"_",r,".csv",sep="")),structure=T) # for an excel-readable csv. Ignore warnings. Note this function will not overwrite, it will append to existing files
  }
}


#AMOVA Loops

## remove anything not included in the ecoregions scheme (some dolphins, some COTS from Kingman and Madagascar(?), some A. nigros from Kiribati, som C. auriga from Fakareva, hammerheads from Western Australia, and West Africa, and some dolphins from the middle of the eastern tropical pacific

ipdb_ecoregions<-ipdb[-which(is.na(ipdb$ECOREGION)),]

## remove anything that doesn't occur in the 3 Indo-Pacific realms
ipdb_ip<-ipdb_ecoregions[which(ipdb_ecoregions$REALM %in% c("Central Indo-Pacific","Western Indo-Pacific","Eastern Indo-Pacific")),]


## Loop through hypotheses, calculating AMOVA
hypotheses<-c("ECOREGION", "PROVINCE","REALM","Bowen","Keith","Kulbicki_r","Kulbicki_b", "VeronDivis")
amova_list<-list()

for(h in hypotheses){
  hierstats<-hierarchical.structure.mtDNA.db(ipdb = ipdb_ip,level1 = "sample",level2=h,model="none",nperm=1)
  amova_list[[h]]<-hierstats
}
  

## Summarize AMOVA results
amovastats<-summarize_AMOVA(amova_list,hypotheses,specieslist=unique(ipdb$Genus_species_locus))


## write them to a spreadsheet
library(xlsx)
for(sheet in names(amovastats)){
  write.xlsx(x=amovastats[[sheet]], file="FST_AMOVA.xlsx",sheetName=sheet,append=T)
}

save(amova_list,file="FST_raw_amova_output.R")
save(amovastats,file="FST_table_amova_output.R")





