// *lgp.stan*
// This is the main Stan model file of the 'lgpr' package
// Author: Juho Timonen

#include /chunks/license.stan
#include /chunks/functions.stan

data {

  int<lower=1> N_tot;        // total number of individuals
  int<lower=0> N_cases;      // number of "diseased" individuals
  int<lower=2> d;            // number of covariates in the data (id and age required)
  int<lower=1> n;            // number of observations
  int<lower=1> N_trials[n];  // numbers of trials (set to all ones for bernoulli model)

  // Modeled data
  vector[n] X[d];           // covariates, X[j] is the jth covariate
  int       X_id[n];        // the id covariate as an array of integers
  int       X_notnan[n];    // X_notnan[i] tells if X_diseaseAge[i] is originally NaN
  vector[n] y;              // the response variable (as a vector of reals)
  int       y_int[n];       // the response variable (as an array of integers)

  // Observation model
  int<lower=0,upper=4> LH;          
  
  // D is an array of six integers, so that
  //   D[1] = binary value indicating if id*age is a predictor
  //   D[2] = binary value indicating if shared age is a predictor
  //   D[3] = binary value indicating if diseaseAge is a predictor
  //   D[4] = number of other continuous covariates
  //   D[5] = number of discrete covariates that interact with age
  //   D[6] = number of discrete covariates that only have an offset effect
  int<lower=0> D[6];
  
  // Modeling option switches
  int<lower=0,upper=1> UNCRT;  // tells if the diseaseAge measurements are uncertain
  int<lower=0,upper=1> HMGNS;  // tells if the diseaseAge effect is homogenous
  
  // Prior types and transforms
  int t_ID[D[1],4];         // for id*age component
  int t_A[D[2],4];          // for shared age component
  int t_D[D[3],6];          // for disease age component
  int t_CNT[D[4],4];        // for components with continuous covariates
  int t_CAT[D[5],4];        // for components with discrete covariates
  int t_OFS[D[6],2];        // for offset components
  int t_SIG[2];             // for Gaussian noise std
  int t_PHI[2];             // for precision parameter phi
  int t_ONS[N_cases,2];     // for onset, if uncertain

  // Hyperparameters of the priors and scaling factors,
  real p_ID[D[1],6];         // for id*age component
  real p_A[D[2],6];          // for shared age component
  real p_D[D[3],9];          // for disease age component
  real p_CNT[D[4],6];        // for components with continuous covariates
  real p_CAT[D[5],6];        // for components with discrete covariates
  real p_OFS[D[6],3];        // for offset components
  real p_SIG[3];             // for Gaussian noise std
  real p_PHI[3];             // for precision parameter phi
  real p_BET[2];             // hyperparameters of the beta prior of BETA
  real p_ONS[N_cases, 3];    // for onset, if uncertain
  
  // Inputs related to mapping from row index to case index and back
  int<lower=0,upper=n>        M_max;
  int<lower=0>                caseID_to_rows[N_cases, M_max];
  int<lower=0,upper=N_cases>  row_to_caseID[n]; 
  int<lower=0,upper=M_max>    caseID_nrows[N_cases];
  
  // Inputs related to uncertain disease onset
  vector[N_cases] T_observed;      // observed disease effect times
  vector[N_cases] L_ons[UNCRT];    // lower bounds for sampled disease effect times
  vector[N_cases] U_ons[UNCRT];    // upper bounds for sampled disease effect times
  int<lower=0,upper=1> backwards;  // is the prior for onset "backwards"
  int<lower=0,upper=1> relative;   // is the prior for effect time relative to observed one
  
  // Other
  real DELTA;       // jitter to ensure pos. def. kernel matrices
  real C_hat;       // C_hat parameter for poisson and NB models
  int HS[6];        // (currently not used)
  int F_is_sampled; // should the function values be sampled? 
                    // (must be 1 for non-Gaussian lh)
                    
  // Kernel types that have options
  int<lower=0,upper=1> USE_VAR_MASK;
  real vm_params[2];
  int<lower=0,upper=1> cat_interact_kernel; // {1 = categorical, 0 = binary} kernel
  
}

transformed data{
  int nf = 1 + D[3] + D[5] + D[6];     // number of fixed kernel matrices
  int sum_D = sum(D);                  // total number of covariates
  matrix[n,n] KF[nf] = STANFUNC_compute_fixed_kernel_matrices(X, X, X_notnan, X_notnan, D, cat_interact_kernel);
  vector[n] mu = rep_vector(C_hat, n); // GP mean
    
  
  // Print some info (mostly for debugging)
  print(" ")
  print("* Observation model = ", LH);
  print("* Number of data points = ", n);
  print("* Number of model components = ", sum_D);
  print("* Number of individuals = ", N_tot);
  print("* Additional model info:")
  if(LH==2 || LH==3){
    print("  - C_hat = ", C_hat);
  }
  print("  - D = ", D);
  print("  - F_is_sampled = ", F_is_sampled)
  print("  - cat_interact_kernel = ", cat_interact_kernel)
  if(D[3]==1){
    print("* Disease modeling info: ");
    print("  - Number of cases = ", N_cases);
    print("  - UNCRT = ", UNCRT);
    print("  - HMGNS = ", HMGNS);
    print("  - USE_VAR_MASK = ", USE_VAR_MASK);
    if(USE_VAR_MASK==1){
      print("      o vm_params = ", vm_params);
    }
  }
  print(" ")
  
}

parameters {

  // Magnitude params
  real<lower=0> alpha_idAge[D[1]];
  real<lower=0> alpha_sharedAge[D[2]];
  real<lower=0> alpha_diseaseAge[D[3]];
  real<lower=0> alpha_continuous[D[4]];
  real<lower=0> alpha_categAge[D[5]];
  real<lower=0> alpha_categOffset[D[6]];

  // Lengthscale parameters
  real<lower=0> lengthscale_idAge[D[1]];
  real<lower=0> lengthscale_sharedAge[D[2]];
  real<lower=0> lengthscale_diseaseAge[D[3]];
  real<lower=0> lengthscale_continuous[D[4]];
  real<lower=0> lengthscale_categAge[D[5]];

  // Miscellaneous
  real<lower=0> warp_steepness[D[3]];       // steepness of input warping
  real<lower=0> sigma_n[LH==1 || LH==0];    // noise std for Gaussian likelihood
  vector[n] ETA[F_is_sampled, sum_D];       // isotropic versions of F
  real<lower=0> phi[LH==3 || LH==0];        // overdispersion parameter for NB likelihood

  // Parameters related to diseased individuals
  vector<lower=0,upper=1>[N_cases] beta[HMGNS==0];  // individual-specific magnitude
  vector<lower=0,upper=1>[N_cases] T_raw[UNCRT==1];

}

transformed parameters {
  vector[N_cases] T_onset[UNCRT];
  vector[n] F[F_is_sampled, sum_D];
  if(UNCRT){
    T_onset[1] = L_ons[1] + (U_ons[1] - L_ons[1]) .* T_raw[1];
  }
  if(F_is_sampled){
    matrix[n,n] KX[sum_D] = STANFUNC_compute_kernel_matrices(X, X, caseID_to_rows, caseID_to_rows, row_to_caseID, row_to_caseID, caseID_nrows, caseID_nrows, KF, T_onset, T_observed, D, UNCRT, HMGNS, USE_VAR_MASK, vm_params, alpha_idAge, alpha_sharedAge,  alpha_diseaseAge, alpha_continuous, alpha_categAge, alpha_categOffset, lengthscale_idAge, lengthscale_sharedAge, lengthscale_diseaseAge, lengthscale_continuous, lengthscale_categAge, warp_steepness, beta);
    for(r in 1:sum_D){
      matrix[n,n] EYE = diag_matrix(rep_vector(DELTA, n));
      matrix[n,n] Lxr = cholesky_decompose(KX[r] + EYE);
      F[1,r,] = Lxr*ETA[1,r,];
    }
  }
}

model {
  
  //Priors
#include /chunks/priors.stan

  // Likelihood model
  if(LH==0){
    
  }else{
    
    if(F_is_sampled){
      
      //  F IS SAMPLED
      // Compute f 
      vector[n] F_sum = rep_vector(0, n);
      for (i in 1:n){
        F_sum[i] += sum(F[1,,i]); 
      }
    
      // Compute likelihood
      if(LH==1){
        // 1. Gaussian observation model
        real SIGMA[n] = to_array_1d(rep_vector(sigma_n[1], n)); // means
        real MU[n] = to_array_1d(F_sum[1:n]);                   // stds 
        target += normal_lpdf(y | MU, SIGMA);
      }else if(LH==2){
        // 2. Poisson observation model
        real LOG_MU[n] = to_array_1d(F_sum[1:n] + C_hat); // means (rate parameters) on log-scale
        target += poisson_log_lpmf(y_int | LOG_MU);
      }else if(LH==3){
        // 3. Negative binomial observation model
        real LOG_MU[n] = to_array_1d(F_sum[1:n] + C_hat); // means on log-scale
        real PHI[n] = to_array_1d(rep_vector(phi[1], n)); // inverse dispersion parameters
        target += neg_binomial_2_log_lpmf(y_int | LOG_MU, PHI);
      }else if(LH==4){
        // 4. Bernoulli or binomial observation model
        real LOGIT_P[n] = to_array_1d(F_sum[1:n]); // probabilities of success on log-scale
        target += binomial_logit_lpmf(y_int | N_trials, LOGIT_P);
      }
      else{
        reject("Unknown observation model!")
      }
    
    }else{
      // F NOT SAMPLED
      matrix[n,n] Ky;
      matrix[n,n] Ly;
      matrix[n,n] Kx = diag_matrix(rep_vector(DELTA, n));
      matrix[n,n] KX[sum_D] = STANFUNC_compute_kernel_matrices(X, X, caseID_to_rows, caseID_to_rows, row_to_caseID, row_to_caseID, caseID_nrows, caseID_nrows, KF, T_onset, T_observed, D, UNCRT, HMGNS, USE_VAR_MASK, vm_params, alpha_idAge, alpha_sharedAge,  alpha_diseaseAge,  alpha_continuous, alpha_categAge, alpha_categOffset, lengthscale_idAge, lengthscale_sharedAge, lengthscale_diseaseAge, lengthscale_continuous, lengthscale_categAge, warp_steepness, beta);
      if(LH!=1){
        reject("Likelihood must be Gaussian if F is not sampled!")
      }
      for(j in 1:sum_D){
        Kx += KX[j]; 
      }
      Ky = Kx + diag_matrix(rep_vector(square(sigma_n[1]), n));
      Ly = cholesky_decompose(Ky);
      y ~ multi_normal_cholesky(mu, Ly);
    }
  }
}

generated quantities {
   vector[n] F_mean_cmp[1 - F_is_sampled, sum_D];
   vector[n] F_var_cmp[ 1 - F_is_sampled, sum_D];
   vector[n] F_mean_tot[1 - F_is_sampled];
   vector[n] F_var_tot[ 1 - F_is_sampled];
                  
   if(F_is_sampled==0){
     matrix[n,n] A;
     vector[n] v;
     matrix[n,n] Ky;
     matrix[n,n] Ly;
     matrix[n,n] Kx = diag_matrix(rep_vector(DELTA, n));
     matrix[n,n] KX[sum_D] = STANFUNC_compute_kernel_matrices(X, X, caseID_to_rows, caseID_to_rows, row_to_caseID, row_to_caseID, caseID_nrows, caseID_nrows, KF, T_onset, T_observed, D, UNCRT, HMGNS, USE_VAR_MASK, vm_params, alpha_idAge, alpha_sharedAge,  alpha_diseaseAge,  alpha_continuous, alpha_categAge, alpha_categOffset, lengthscale_idAge, lengthscale_sharedAge, lengthscale_diseaseAge, lengthscale_continuous, lengthscale_categAge, warp_steepness, beta);
     for(j in 1:sum_D){
       Kx += KX[j]; 
     }
     Ky = Kx + diag_matrix(rep_vector(square(sigma_n[1]), n));
     Ly = cholesky_decompose(Ky);
     v = mdivide_left_tri_low(Ly, y);
     for(j in 1:sum_D){
       A  = mdivide_left_tri_low(Ly, transpose(KX[j]));
       F_mean_cmp[1,j] = transpose(A)*v;
       F_var_cmp[1,j] = diagonal(KX[j] - crossprod(A));
     }
     A = mdivide_left_tri_low(Ly, transpose(Kx));
     F_mean_tot[1] = transpose(A)*v;
     F_var_tot[1] = diagonal(Kx - crossprod(A));
   }
}

