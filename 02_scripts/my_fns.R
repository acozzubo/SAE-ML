# ---
# title: "Functions Script for FH models, Anemia Markdown"
# subtitle: "SAE Estimators"
# author: "[Angelo Cozzubo] (https://sites.google.com/pucp.pe/acozz)"
# date creation: "04/05/2022"
# date last edit: "`r Sys.Date()`"
# ---

# 1. Spatial Fay-Harriot function ####

SpatialFH <- function(direct_estim, selected_vars_df, vardir, prox_matrix){
  #Run Spatial FH model. Includes MSE, CV, gammas and synthetic estimate  
  #input: direct estimates vector, predictor vars dataframe, 
  #       direct estimates variance, proximity standardized matrix
  #return: list with objects 
  
  #SFH from SAE PACKAGE
  prov.SFH.res <- eblupSFH(direct_estim~(selected_vars_df)-1,
                           vardir = vardir,
                           proxmat = prox_matrix,
                           method = "REML", MAXITER = 100, PRECISION = 0.0001)
  prov.SFH <- prov.SFH.res$eblup
  
  # Synthetic estimator 
  prov.rsyn1 <- selected_vars_df%*%prov.SFH.res$fit$estcoef[,1]
  
  # MSE and CV 
  prov.SFH.mse.res <- mseSFH(direct_estim~(selected_vars_df)-1,
                             vardir = vardir,
                             proxmat = prox_matrix, 
                             method = "REML", MAXITER = 100, PRECISION = 0.0001)
  prov.SFH.mse <- prov.SFH.mse.res$mse
  prov.SFH.cv <- 100*sqrt(prov.SFH.mse)/prov.SFH
  
  # Gammas 
  gammad <- prov.SFH.res$fit$refvar/(prov.SFH.res$fit$refvar+prov.dir.svy$se^2)
  #summary(gammad)
  
  
  newlist <- list("SFH.object" = prov.SFH.res, 
                  "SFH.estimates" = prov.SFH,
                  "SFH.synth" = prov.rsyn1,
                  "SFH.obj.mse" = prov.SFH.mse.res,
                  "SFH.mse" = prov.SFH.mse,
                  "SFH.cv" = prov.SFH.cv,
                  "gamma" = gammad)
  return(newlist)
  
}


# 2. Choropleths function ####

choropleths <- function(shape, estimates_df, estim_df_key, estimate_col, title) {
  #Draw a choropleths of provincial anemia estimates for Peru 
  #input: provinces shapefile, estimates dataframe, province ID, column in df, 
  #       title string
  #return: none, use jpg command header to save plot 
  
  shape <- transform(shape, ID_PROV = as.numeric(IDPROV)) 
  
  polygons <- merge(shape, estimates_df, 
                    by.x = "ID_PROV", 
                    by.y = estim_df_key)
  
  tm_shape(polygons) + 
    tm_fill(estimate_col, style="pretty",
            title='Prevalence (%)',
            palette= 'Oranges', 
            colorNA = 'grey50',
            textNA = 'Suppressed') + 
    tm_borders() +
    tm_layout(title = title, 
              legend.outside = FALSE, 
              legend.outside.position = "right", 
              title.position = c('0.65', '0.95'),
              title.fontface = 2,
              title.size = 1,
              legend.title.size = 1,
              legend.text.size = 0.95,
              legend.position = c("left","bottom"),
              legend.bg.color = "white",
              legend.bg.alpha = 1, 
              legend.title.fontface = 2) +
    tm_scale_bar(position=c("0.45", "0")) + 
    tm_compass(type="8star", size=4, position=c("LEFT", "center"))
}

# 3. Estimates convergence plot  ####
converplot <- function(popsize, estim_ratio_col, title, xlabel, ylabel, note) {
  #Draw a convergence plot for ratio of direct/model estimate or std errors   
  #input: domains pop size, estimates ratio column, title,labels and notes string
  #return: none, use jpg command header to save plot 
  
  par(mar = c(7, 4, 3, 3))
  
  plot(popsize, estim_ratio_col, 
       log="x", xaxt = 'n', 
       main=title,  
       xlab= xlabel,  
       ylab= ylabel, 
       pch=19)
  abline(h=100, col="red")
  
  myTicks = axTicks(1)
  axis(1, at = myTicks, labels = formatC(myTicks, format = 'd'))
  mtext(note, side = 1, line = 5, cex = 0.7, adj = 0) 
}