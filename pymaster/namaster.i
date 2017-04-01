%module nmtlib

%{
#define SWIG_FILE_WITH_INIT
#include "../src/namaster.h"
%}

%include "numpy.i"
%init %{
  import_array();
%}

%rename("%(strip:[nmt_])s") "";

%include "../src/namaster.h"

%apply (int* ARGOUT_ARRAY1, int DIM1) {(int* iout, int niout)};
%apply (double* ARGOUT_ARRAY1, int DIM1) {(double* dout, int ndout)};
%apply (int DIM1,double *IN_ARRAY1) {(int npix_1,double *mask),
                                     (int nell3,double *weights)};
%apply (int DIM1,int *IN_ARRAY1) {(int nell1,int *bpws),
                                  (int nell2,int *ells)};
%apply (int DIM1,int DIM2,double *IN_ARRAY2) {(int nmap_2,int npix_2,double *mps),
                                              (int ncl1  ,int nell1 ,double *cls1),
                                              (int ncl2  ,int nell2 ,double *cls2),
                                              (int ncl3  ,int nell3 ,double *cls3)};
%apply (int DIM1,int DIM2,int DIM3,double *IN_ARRAY3) {(int ntmp_3,int nmap_3,int npix_3,double *tmp)};

%inline %{
void get_nell_list(nmt_binning_scheme *bins,int *iout,int niout)
{
  assert(bins->n_bands==niout);

  memcpy(iout,bins->nell_list,bins->n_bands*sizeof(int));
}

int get_nell(nmt_binning_scheme *bins,int ibin)
{
  assert(ibin<bins->n_bands);
  
  return bins->nell_list[ibin];
}

void get_ell_list(nmt_binning_scheme *bins,int ibin,int *iout,int niout)
{
  assert(ibin<bins->n_bands);
  assert(bins->nell_list[ibin]==niout);

  memcpy(iout,bins->ell_list[ibin],bins->nell_list[ibin]*sizeof(int));
}

void get_weight_list(nmt_binning_scheme *bins,int ibin,double *dout,int ndout)
{
  assert(ibin<bins->n_bands);
  assert(bins->nell_list[ibin]==ndout);

  memcpy(dout,bins->w_list[ibin],bins->nell_list[ibin]*sizeof(double));
}

void get_ell_eff(nmt_binning_scheme *bins,double *dout,int ndout)
{
  assert(ndout==bins->n_bands);
  nmt_ell_eff(bins,dout);
}

nmt_binning_scheme *bins_create_py(int nell1,int *bpws,
				   int nell2,int *ells,
				   int nell3,double *weights,
				   int lmax)
{
  assert(nell1==nell2);
  assert(nell2==nell3);
  
  return nmt_bins_create(nell1,bpws,ells,weights,lmax);
}

void bin_cl(nmt_binning_scheme *bins,
	    int ncl1,int nell1,double *cls1,
	    double *dout,int ndout)
{
  int i;
  assert(ndout==ncl1*bins->n_bands);
  double **cls_in,**cls_out;
  cls_in=malloc(ncl1*sizeof(double *));
  cls_out=malloc(ncl1*sizeof(double *));
  for(i=0;i<ncl1;i++) {
    cls_in[i]=&(cls1[i*nell1]);
    cls_out[i]=&(dout[i*bins->n_bands]);
  }
  nmt_bin_cls(bins,cls_in,cls_out,ncl1);
  free(cls_in);
  free(cls_out);
}

void unbin_cl(nmt_binning_scheme *bins,
	      int ncl1,int nell1,double *cls1,
	      double *dout,int ndout)
{
  int i;
  int nellout=ndout/ncl1;
  assert(nell1==bins->n_bands);
  double **cls_in,**cls_out;
  cls_in=malloc(ncl1*sizeof(double *));
  cls_out=malloc(ncl1*sizeof(double *));
  for(i=0;i<ncl1;i++) {
    cls_in[i]=&(cls1[i*nell1]);
    cls_out[i]=&(dout[i*nellout]);
    memset(cls_out[i],0,nellout*sizeof(double));
  }
  nmt_unbin_cls(bins,cls_in,cls_out,ncl1);
  free(cls_in);
  free(cls_out);
}

nmt_field *field_alloc_new(int npix_1,double *mask,
			   int nmap_2,int npix_2,double *mps,
			   int ntmp_3,int nmap_3,int npix_3,double *tmp,
			   int nell3,double *weights,int pure_e,int pure_b)
{
  int ii,jj;
  long nside=1;
  int pol=0,ntemp=0;
  double **maps;
  double ***temp=NULL;
  nmt_field *fl;
  assert(npix_1==npix_2);
  assert(npix_2==npix_3);
  assert(nmap_2==nmap_3);
  assert((nmap_2==1) || (nmap_2==2));

  while(npix_1!=12*nside*nside)
    nside*=2;

  assert(nell3!=3*nside);

  if(nmap_2==2) pol=1;

  if(tmp!=NULL) {
    ntemp=ntmp_3;
    temp=malloc(ntmp_3*sizeof(double **));
    for(ii=0;ii<ntmp_3;ii++) {
      temp[ii]=malloc(nmap_3*sizeof(double *));
      for(jj=0;jj<nmap_3;jj++)
	temp[ii][jj]=tmp+npix_3*(jj+ii*nmap_3);
    }
  }
  
  maps=malloc(nmap_2*sizeof(double *));
  for(ii=0;ii<nmap_2;ii++)
    maps[ii]=mps+npix_2*ii;

  fl=nmt_field_alloc(nside,mask,pol,maps,ntemp,temp,weights,pure_e,pure_b);

  if(tmp!=NULL) {
    for(ii=0;ii<ntmp_3;ii++)
      free(temp[ii]);
    free(temp);
  }
  free(maps);

  return fl;
}

nmt_field *field_alloc_new_notemp(int npix_1,double *mask,
				  int nmap_2,int npix_2,double *mps,
				  int nell3,double *weights,int pure_e,int pure_b)
{
  int ii;
  long nside=1;
  int pol=0,ntemp=0;
  double **maps;
  nmt_field *fl;
  assert(npix_1==npix_2);
  assert(npix_2==npix_3);
  assert(nmap_2==nmap_3);
  assert((nmap_2==1) || (nmap_2==2));

  while(npix_1!=12*nside*nside)
    nside*=2;

  assert(nell3!=3*nside);

  if(nmap_2==2) pol=1;

  maps=malloc(nmap_2*sizeof(double *));
  for(ii=0;ii<nmap_2;ii++)
    maps[ii]=mps+npix_2*ii;

  fl=nmt_field_alloc(nside,mask,pol,maps,ntemp,NULL,weights,pure_e,pure_b);

  free(maps);

  return fl;
}

void get_map(nmt_field *fl,int imap,double *dout,int ndout)
{
  assert(imap<fl->nmaps);
  assert(ndout==fl->npix);
  memcpy(dout,fl->maps[imap],fl->npix*sizeof(double));
}

void get_temp(nmt_field *fl,int itemp,int imap,double *dout,int ndout)
{
  assert(itemp<fl->ntemp);
  assert(imap<fl->nmaps);
  assert(ndout==fl->npix);
  memcpy(dout,fl->temp[itemp][imap],fl->npix*sizeof(double));
}

void apomask(int npix_1,double *mask,
	     double *dout,int ndout,double aposize,char *apotype)
{
  long nside=1;
  assert(ndout==npix_1);

  while(npix_1!=12*nside*nside)
    nside*=2;

  nmt_apodize_mask(nside,mask,dout,aposize,apotype);
}

void comp_deproj_bias(nmt_field *fl1,nmt_field *fl2,
		      int ncl1,int nell1,double *cls1,
		      double *dout,int ndout)
{
  int i;
  double **cl_bias,**cl_guess;
  assert(fl1->nside==fl2->nside);
  assert(ncl1==fl1->nmaps*fl2->nmaps);
  assert(nell1==fl1->lmax+1);
  assert(ndout==nell1*ncl1);
  cl_bias=malloc(ncl1*sizeof(double *));
  cl_guess=malloc(ncl1*sizeof(double *));
  for(i=0;i<ncl1;i++) {
    cl_guess[i]=&(cls1[nell1*i]);
    cl_bias[i]=&(dout[nell1*i]);
  }

  nmt_compute_deprojection_bias(fl1,fl2,cl_guess,cl_bias);

  free(cl_bias);
  free(cl_guess);
}

void comp_pspec_coupled(nmt_field *fl1,nmt_field *fl2,
			double *dout,int ndout,int iter)
{
  int i;
  double **cl_out;
  assert(fl1->nside==fl2->nside);
  assert(ndout==fl1->nmaps*fl2->nmaps*(fl1->lmax+1));
  cl_out=malloc(fl1->nmaps*fl2->nmaps*sizeof(double *));
  for(i=0;i<fl1->nmaps*fl2->nmaps;i++)
    cl_out[i]=&(dout[i*(fl1->lmax+1)]);

  nmt_compute_coupled_cell(fl1,fl2,cl_out,iter);

  free(cl_out);
}

void decouple_cell_py(nmt_workspace *w,
		      int ncl1,int nell1,double *cls1,
		      int ncl2,int nell2,double *cls2,
		      int ncl3,int nell3,double *cls3,
		      double *dout,int ndout)
{
  int i;
  double **cl_in,**cl_noise,**cl_bias,**cl_out;
  assert(ncl1==ncl2);
  assert(ncl2==ncl3);
  assert(ncl1==w->ncls);
  assert(nell1==nell2);
  assert(nell2==nell3);
  assert(nell1==w->lmax+1);
  assert(ndout==w->bin->n_bands);
  cl_in=   malloc(ncl1*sizeof(double *));
  cl_noise=malloc(ncl2*sizeof(double *));
  cl_bias= malloc(ncl3*sizeof(double *));
  cl_out=  malloc(ncl3*sizeof(double *));
  for(i=0;i<ncl1;i++) {
    cl_in[i]   =&(cls1[i*nell1]);
    cl_noise[i]=&(cls2[i*nell2]);
    cl_bias[i] =&(cls3[i*nell3]);
    cl_out[i]  =&(dout[i*w->bin->n_bands]);
  }

  nmt_decouple_cl_l(w,cl_in,cl_noise,cl_bias,cl_out);

  free(cl_in);
  free(cl_noise);
  free(cl_bias);
}

void couple_cell_py(nmt_workspace *w,
		    int ncl1,int nell1,double *cls1,
		    double *dout,int ndout)
{
  int i;
  double **cl_in,**cl_out;
  assert(ncl1==w->ncls);
  assert(nell1=w->lmax+1);
  assert(ncl1*nell1=ndout);
  cl_in=malloc(ncl1*sizeof(double *));
  cl_out=malloc(ncl1*sizeof(double *));
  for(i=0;i<ncl1;i++) {
    cl_in[i]=&(cls1[i*nell1]);
    cl_out[i]=&(dout[i*nell1]);
  }
  nmt_couple_cl_l(w,cl_in,cl_out);
  free(cl_in);
  free(cl_out);
}

void comp_pspec(nmt_field *fl1,nmt_field *fl2,
		nmt_binning_scheme *bin,nmt_workspace *w0,
		int ncl1,int nell1,double *cls1,
		int ncl2,int nell2,double *cls2,
		double *dout,int ndout)
{
  int i;
  double **cl_noise,**cl_guess,**cl_out;
  nmt_workspace *w;
  assert(fl1->nside==fl2->nside);
  assert(ncl1==fl1->nmaps*fl2->nmaps);
  assert(nell1==fl1->lmax+1);
  assert(ndout==bin->n_bands*ncl1);
  assert(nell1==nell2);
  assert(ncl1==ncl2);
  cl_noise=malloc(ncl1*sizeof(double *));
  cl_guess=malloc(ncl1*sizeof(double *));
  cl_out=malloc(ncl1*sizeof(double *));
  for(i=0;i<ncl1;i++) {
    cl_noise[i]=&(cls1[nell1*i]);
    cl_guess[i]=&(cls2[nell1*i]);
    cl_out[i]=&(dout[i*bin->n_bands]);
  }

  w=nmt_compute_power_spectra(fl1,fl2,bin,w0,cl_noise,cl_guess,cl_out);

  free(cl_out);
  free(cl_guess);
  free(cl_noise);
  if(w0==NULL)
    nmt_workspace_free(w);
}
%}

/*
%extend nmt_binning_scheme {
  void print_bins() {
    printf("%d\n",$self->n_bands);
  }
  int get_nbands() {
    return $self->n_bands;
  }
 };
*/