
// BASIS FUNCTION
vector STAN_phi(vector x, int m, real L){
  real A = 1.0/(sqrt(L));
  real B = pi()*m/(2.0*L);
  return(A*sin(B*(x-L)));
}

// EIGENVALUE
real STAN_lambda(int m, real L){
  real A = pi()*m/(2*L);
  return(square(A));
}

// SPECTRAL DENSITY OF EQ KERNEL
real STAN_spd_eq(real w, real alpha, real ell){
  real A = square(alpha)*ell*sqrt(2*pi());
  real B = 2*square(pi()*ell);
  return(A*exp(-B*square(w)));
}

// COMPUTE QUADRATIC FORM OF INVERSE
real STAN_quad_form_inv(vector x, matrix A){
  int n = num_elements(x);
  matrix[n, n] L = cholesky_decompose(A);
  vector[n] a = mdivide_left_tri_low(L, x);
  return dot_self(a);
}

// LOG PROB OF MULTIVARIATE NORMAL WITH LOW RANK COVARIANCE
real STAN_multi_normal_bf_lpdf(vector y, matrix V, vector D_diag, real sigma){
  int n = num_elements(y);
  int L = num_elements(D_diag);
  real t1 = n*log(2*pi());
  real t2; // log det
  real t3; // quadratic form
  real inv_s2 = inv_square(sigma);
  vector[n] z = transpose(V)*y;
  matrix[L,L] Z = diag_matrix(inv(D_diag)) + inv_s2*crossprod(V);
  t2 = inv_s2*dot_self(y) + square(inv_s2)*STAN_quad_form_inv(z, Z);
  t3 = log_determinant(Z) + sum(log(D_diag)) + 2*n*log(sigma);
  return(-0.5*(t1 + t2 + t3));
}
