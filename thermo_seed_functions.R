#first, we create a function that lets us check how well different GAMS fit the data
predict_perf <- function(gam_model) {
  print(summary(gam_model))
  y <- gam_model$model[[1]]
  y_h <- predict(gam_model, type='response')
  rmse <- sqrt( sum((y - y_h)^2) / length(y))
  R2 <- cor(y, y_h)
  plot(y, y_h, xlab = paste0("observed germination: ", 'RMSE (% germ): ', round(rmse, 4)), 
       ylab = "predicted germination", main = gam_model$formula)
  abline(0,1)
  print(gratia::draw(gam_model, dist = 0.15))
  #print(paste0('RMSE (% germ): ', round(rmse, 2)))
  invisible(c(rmse,R2))
}

# First make the resampling function - there's lots of options, but a monte carlo leaving a few samples out is probably sufficient for this data sets with fairly low `n`. `fraction=` input controls how much of the data is used to trian the model on each run, and `n=` contorls the number of resampling iterations
fit_mc_resampling <-
  function(mod_formula = formula(prop_germ ~ s(day_temp, bs = 'cr', k = 4)),
           # default formula (for testing)
           mod_family = binomial(),
           mod_data,
           fraction = 0.9,
           # default fraction of 90%
           n = 10,
           weights) {
    # first check if the input formula can be run
    run_check <- try(expr = {
      num_rows <- 1:nrow(mod_data)
      train_rows <-
        sample(num_rows, as.integer(length(num_rows) * fraction), FALSE)
      test_rows <- num_rows[!num_rows %in% train_rows]
      # copy sampel to weights
      mod_weights <- weights[train_rows]
      # fit the model
      cand_model <- do.call(
        "gam",
        list(
          formula = mod_formula,
          family = mod_family,
          weights = mod_weights,
          method = 'REML',
          data = mod_data[train_rows, ]
        )
      )
    })
    
    if (!is.null(attr(run_check, "condition"))) {
      message(paste0(
        "Formula: ",
        paste0(deparse(mod_formula), collapse = ""),
        " could not be fitted (error message above)."
      ))
      return(
        data.frame(
          formula = paste0(deparse(mod_formula), collapse = ""),
          mean_error = NA,
          lower95 = NA,
          upper95 = NA,
          full_rmse = NA,
          stringsAsFactors = F
        )
      )
    }
    
    mc_reps <- list()
    
    for (i in 1:n) {
      # i would usually use replicate() or some other lapply() variant, but for some reason the weights argument stuff with function scoping, so i used a for loop
      
      # set up sampling
      num_rows <- 1:nrow(mod_data)
      train_rows <-
        sample(num_rows, as.integer(length(num_rows) * fraction), FALSE)
      test_rows <- num_rows[!num_rows %in% train_rows]
      # copy sampel to weights
      mod_weights <- weights[train_rows]
      # fit the model
      cand_model <- do.call(
        "gam",
        list(
          formula = mod_formula,
          family = mod_family,
          weights = mod_weights,
          method = 'REML',
          data = mod_data[train_rows, ]
        )
      )
      # predict the model
      test_preds <-
        predict(cand_model, newdata = mod_data[test_rows, ], type = "response")
      # get the error
      mc_reps[[i]] <-
        sum((abs(mod_data[[as.character(mod_formula)[2]]][test_rows] - test_preds))) / length(test_rows) # returns the mean prediction error
    }
    
    mc_reps <- unlist(mc_reps)
    #print(mc_reps)
    
    # get the full RMSE of the model too
    full_model <- do.call(
      "gam",
      list(
        formula = mod_formula,
        family = mod_family,
        weights = weights,
        method = 'REML',
        data = mod_data
      )
    )
    
    full_mod_stats <- predict_perf(full_model)
    rmse <- full_mod_stats[1]
    R2 <- full_mod_stats[2]
    
    data.frame(
      formula = paste0(deparse(mod_formula), collapse = ""),
      mean_error = round(sum(mc_reps) / length(mc_reps), 3),
      lower95 = round(quantile(mc_reps, 0.025), 3),
      upper95 = round(quantile(mc_reps, 0.975), 3),
      full_rmse = rmse,
      full_cor = R2,
      stringsAsFactors = F
    )
  }



