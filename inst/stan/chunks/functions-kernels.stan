// Multiplier matrix to enable variance masking
matrix STAN_kernel_base_var_mask(
  vector x1,
  vector x2,
  real steepness,
  data real[] vm_params)
{
  int n1 = num_elements(x1);
  int n2 = num_elements(x2);
  real a = steepness * vm_params[2];
  real r = inv(a)*logit(vm_params[1]);
  matrix[n1, 1] s1 = to_matrix(STAN_var_mask(x1 - r, a));
  matrix[n2, 1] s2 = to_matrix(STAN_var_mask(x2 - r, a));
  matrix[n1, n2] K = s1 * transpose(s2);
  return(K);
}

/* 
  Compute all kernel matrices. These depend on parameters and
  therefore this function needs to be evaluated repeatedly during sampling.
*/
matrix[] STAN_kernel_all(
  data int n1,
  data int n2,
  data matrix[] K_const,
  data int[,] components,
  data vector[] x1,
  data vector[] x2,
  data vector[] x1_unnorm,
  data vector[] x2_unnorm,
  real[] alpha,
  real[] ell,
  real[] wrp,
  vector[] beta,
  vector[] teff,
  data real[,] vm_params,
  data int[] idx1_expand,
  data int[] idx2_expand,
  data vector[] teff_zero)
{
  int idx_ell = 0;
  int idx_wrp = 0;
  int idx_alpha = 0;
  int num_comps = size(components);
  matrix[n1, n2] KX[num_comps];

  // Loop through components
  for(j in 1:num_comps){
    
    // 1. Initialize with constant part of the kernel matrix
    matrix[n1, n2] K = K_const[j];
    vector[n1] X1;
    vector[n2] X2;

    // 2. Get component properties
    int opts[9] = components[j];
    int ctype = opts[1];
    int idx_cont = opts[9];
    int is_heter = opts[4];
    int is_warped = opts[5];
    int is_var_masked = opts[6];
    int is_uncrt = opts[7];
    
    // 3. Pick the possible continuous covariate of this component
    if(ctype != 0){
      if(is_warped){
        X1 = x1_unnorm[idx_cont];
        X2 = x2_unnorm[idx_cont];
      }else{
        X1 = x1[idx_cont];
        X2 = x2[idx_cont];
      }
    }
    
    // 4. Handle possible nonstationarity
    if(is_warped){
      real s;
      idx_wrp += 1;
      
      // 4.1 Handle possible uncertainty
      if(is_uncrt){
        X1 = STAN_edit_x_cont(X1, idx1_expand, teff_zero[1], teff[1]);
        X2 = STAN_edit_x_cont(X2, idx2_expand, teff_zero[1], teff[1]);
      }
      
      // 4.2 Variance masking
      s = wrp[idx_wrp];
      if(is_var_masked){
        K = K .* STAN_kernel_base_var_mask(X1, X2, s, vm_params[idx_wrp]);
      }
      
      // 4.3 Input warping
      X1 = STAN_warp_input(X1, s);
      X2 = STAN_warp_input(X2, s);
    }
    
    // Compute the kernel matrix
    idx_alpha += 1;
    if(ctype != 0){
      idx_ell += 1;
      K = K .* cov_exp_quad(to_array_1d(X1), to_array_1d(X2), 
                            alpha[idx_alpha], ell[idx_ell]);
    } else {
      K = square(alpha[idx_alpha]) * K;
    }
    
    // Possible heterogeneity
    if(is_heter){
      vector[n1] b1 = STAN_expand(beta[1], idx1_expand);
      vector[n2] b2 = STAN_expand(beta[1], idx2_expand);
      matrix[n1, n2] K_beta = to_matrix(b1) * transpose(to_matrix(b2));
      K = K .* K_beta;
    }
    
    // Store kernel matrix
    KX[j] = K;
  }
  
  return(KX);
}
