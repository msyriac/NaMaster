#ifndef _NAMASTER_H_
#define _NAMASTER_H_

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <time.h>
#include <complex.h>
#include <omp.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_linalg.h>
#include <gsl/gsl_blas.h>
#ifdef _WITH_NEEDLET
#include <gsl/gsl_integration.h>
#include <gsl/gsl_spline.h>
#endif //_WITH_NEEDLET
#include <fftw3.h>

#define NMT_MAX(a,b)  (((a)>(b)) ? (a) : (b)) // maximum
#define NMT_MIN(a,b)  (((a)<(b)) ? (a) : (b)) // minimum

#ifdef _SPREC
typedef float flouble;
typedef float complex fcomplex;
#else //_SPREC
typedef double flouble;
typedef double complex fcomplex;
#endif //_SPREC

//Defined in bins.c
typedef struct {
  int n_bands;
  int *nell_list;
  int **ell_list;
  flouble **w_list;
} nmt_binning_scheme;
nmt_binning_scheme *nmt_bins_constant(int nlb,int lmax);
nmt_binning_scheme *nmt_bins_create(int nell,int *bpws,int *ells,flouble *weights,int lmax);
nmt_binning_scheme *nmt_bins_read(char *fname,int lmax);
void nmt_bins_free(nmt_binning_scheme *bin);
void nmt_bin_cls(nmt_binning_scheme *bin,flouble **cls_in,flouble **cls_out,int ncls);
void nmt_unbin_cls(nmt_binning_scheme *bin,flouble **cls_in,flouble **cls_out,int ncls);
void nmt_ell_eff(nmt_binning_scheme *bin,flouble *larr);

//Defined in field.c
typedef struct {
  int nx;
  int ny;
  long npix;
  flouble lx;
  flouble ly;
  flouble pixsize;
  int n_ell;
  flouble i_dell;
  flouble dell;
  flouble *ell_min;
  int *n_cells;
} nmt_flatsky_info;

typedef struct {
  long nside;
  long npix;
  int lmax;
  int pure_e;
  int pure_b;
  flouble *mask;
  int pol;
  int nmaps;
  flouble **maps;
  fcomplex **alms;
  int ntemp;
  flouble ***temp;
  fcomplex ***a_temp;
  gsl_matrix *matrix_M;
  flouble *beam;
  int is_flatsky;
  nmt_flatsky_info *fs;
} nmt_field;
void nmt_flatsky_info_free(nmt_flatsky_info *fs);
nmt_flatsky_info *nmt_flatsky_info_alloc(int nx,int ny,flouble lx,flouble ly);
void nmt_field_free(nmt_field *fl);
nmt_field *nmt_field_alloc_sph(long nside,flouble *mask,int pol,flouble **maps,
			       int ntemp,flouble ***temp,flouble *beam,int pure_e,int pure_b);
nmt_field *nmt_field_read(char *fname_mask,char *fname_maps,char *fname_temp,char *fname_beam,
			  int pol,int pure_e,int pure_b);
void nmt_apodize_mask(long nside,flouble *mask_in,flouble *mask_out,flouble aposize,char *apotype);

//Defined in master.c
typedef struct {
  int lmax;
  int ncls;
  flouble *pcl_masks;
  flouble **coupling_matrix_unbinned;
  nmt_binning_scheme *bin;
  gsl_matrix *coupling_matrix_binned;
  gsl_permutation *coupling_matrix_perm;
} nmt_workspace;
nmt_workspace *nmt_compute_coupling_matrix(nmt_field *fl1,nmt_field *fl2,nmt_binning_scheme *bin);
void nmt_workspace_write(nmt_workspace *w,char *fname);
nmt_workspace *nmt_workspace_read(char *fname);
void nmt_workspace_free(nmt_workspace *w);
void nmt_compute_deprojection_bias(nmt_field *fl1,nmt_field *fl2,flouble **cl_proposal,flouble **cl_bias);
void nmt_couple_cl_l(nmt_workspace *w,flouble **cl_in,flouble **cl_out);
void nmt_decouple_cl_l(nmt_workspace *w,flouble **cl_in,flouble **cl_noise_in,
		       flouble **cl_bias,flouble **cl_out);
void nmt_compute_coupled_cell(nmt_field *fl1,nmt_field *fl2,flouble **cl_out,int iter);
nmt_workspace *nmt_compute_power_spectra(nmt_field *fl1,nmt_field *fl2,
					 nmt_binning_scheme *bin,nmt_workspace *w0,
					 flouble **cl_noise,flouble **cl_proposal,flouble **cl_out);

#endif //_NAMASTER_H_
