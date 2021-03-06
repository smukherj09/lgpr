if(is_f_sampled){
  
  // Compute total signal + offset c_hat
  vector[num_obs] f_sum = STAN_vectorsum(f_latent[1], num_obs) + c_hat;

  // Compute likelihood
  if(obs_model==2){
    // 2. Poisson
    real LOG_MU[num_obs] = to_array_1d(f_sum); // means (log-scale)
    target += poisson_log_lpmf(y_disc[1] | LOG_MU);
  }else if(obs_model==3){
    // 3. Negative binomial
    real LOG_MU[num_obs] = to_array_1d(f_sum); // means (log-scale)
    real PHI[num_obs] = to_array_1d(rep_vector(phi[1], num_obs)); // dispersion
    target += neg_binomial_2_log_lpmf(y_disc[1] | LOG_MU, PHI);
  }else if(obs_model==4){
    // 4. Binomial
    real LOGIT_P[num_obs] = to_array_1d(f_sum); // p success (logit-scale)
    target += binomial_logit_lpmf(y_disc[1] | y_num_trials[1], LOGIT_P);
  }else if(obs_model==5){
    // 5. Beta-binomial
    real tgam = inv(gamma[1]) - 1.0;
    vector[num_obs] P = inv_logit(f_sum); // p success
    real aa[num_obs] = to_array_1d(P * tgam);
    real bb[num_obs] = to_array_1d((1.0 - P) * tgam);
    target += beta_binomial_lpmf(y_disc[1] | y_num_trials[1], aa, bb);
  }else{
    // 1. Gaussian observation model (obs_model should be 1)
    real MU[num_obs] = to_array_1d(f_sum); // means
    real SIGMA[num_obs] = to_array_1d(rep_vector(sigma[1], num_obs)); // stds
    target += normal_lpdf(y_cont[1] | MU, SIGMA);
  }

}else{
  // F NOT SAMPLED
  vector[num_obs] sigma2_vec = rep_vector(square(sigma[1]), num_obs);
  matrix[num_obs, num_obs] Ky = diag_matrix(num_comps * delta_vec);
  matrix[num_obs, num_obs] KX[num_comps] = STAN_kernel_all(num_obs, num_obs,
      K_const, components, x_cont, x_cont, x_cont_unnorm, x_cont_unnorm,
      alpha, ell, wrp, beta, teff,
      vm_params, idx_expand, idx_expand, teff_zero);

  for(j in 1:num_comps){
    Ky += KX[j];
  }
  Ky = Ky + diag_matrix(sigma2_vec);
  y_cont[1] ~ multi_normal_cholesky(c_hat, cholesky_decompose(Ky));
}
