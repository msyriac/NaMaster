import nmtlib as lib
import numpy as np

class NmtBin(object) :
    """
    An NmtBin object defines the set of bandpowers used in the computation of the pseudo-Cl estimator. The definition of bandpowers is described in Section 3.6 of the scientific documentation.

    :param int nside: HEALPix nside resolution parameter of the maps you intend to correlate. The maximum multipole considered for bandpowers will be 3*nside-1.
    :param array-like ells: array of integers corresponding to different multipoles
    :param array-like bpws: array of integers that assign the multipoles in ells to different bandpowers
    :param array-like weights: array of floats corresponding to the weights associated to each multipole in ells. The sum of weights within each bandpower is normalized to 1.
    :param int nlb: integer value corresponding to a constant bandpower width. I.e. the bandpowers will be defined as consecutive sets of nlb multipoles from l=2 to l=3*nside-1 with equal weights. If this argument is provided, the values of ells, bpws and weights are ignored.
    """
    def __init__(self,nside,bpws=None,ells=None,weights=None,nlb=None) :
        if((bpws==None) and (ells==None) and (weights==None) and (nlb==None)) :
            raise KeyError("Must supply bandpower arrays or constant bandpower width")

        if(nlb==None) :
            if((bpws==None) and (ells==None) and (weights==None)) :
                raise KeyError("Must provide bpws, ells and weights")
            self.bin=lib.bins_create_py(bpws,ells,weights,3*nside-1)
        else :
            self.bin=lib.bins_constant(nlb,3*nside-1)
        self.lmax=3*nside-1

    def __del__(self) :
        lib.bins_free(self.bin)

    def get_n_bands(self) :
        """
        Returns the number of bandpowers stored in this object

        :return: number of bandpowers
        """
        return self.bin.n_bands

    def get_nell_list(self) :
        """
        Returns an array with the number of multipoles in each bandpower stored in this object

        :return: number of multipoles per bandpower
        """
        return lib.get_nell_list(self.bin,self.bin.n_bands)

    def get_ell_list(self,ibin) :
        """
        Returns an array with the multipoles in the ibin-th bandpower

        :param int ibin: bandpower index
        :return: multipoles associated with bandpower ibin
        """
        return lib.get_ell_list(self.bin,ibin,lib.get_nell(self.bin,ibin))

    def get_weight_list(self,ibin) :
        """
        Returns an array with the weights associated to each multipole in the ibin-th bandpower

        :param int ibin: bandpower index
        :return: weights associated to multipoles in bandpower ibin
        """
        return lib.get_weight_list(self.bin,ibin,lib.get_nell(self.bin,ibin))

    def get_effective_ells(self) :
        """
        Returns an array with the effective multipole associated to each bandpower. These are computed as a weighted average of the multipoles within each bandpower.

        :return: effective multipoles for each bandpower
        """
        return lib.get_ell_eff(self.bin,self.bin.n_bands)

    def bin_cell(self,cls_in) :
        """
        Bins a power spectrum into bandpowers. This is carried out as a weighted average over the multipoles in each bandpower.

        :param array-like cls_in: 2D array of power spectra
        :return: array of bandpowers
        """
        if(len(cls_in[0])!=self.lmax+1) :
            raise KeyError("Input Cl has wrong size")
        cl1d=lib.bin_cl(self.bin,cls_in,len(cls_in)*self.bin.n_bands)
        clout=np.reshape(cl1d,[len(cls_in),self.bin.n_bands])
        return clout

    def unbin_cell(self,cls_in) :
        """
        Un-bins a set of bandpowers into a power spectrum. This is simply done by assigning a constant value for every multipole in each bandpower (corresponding to the value of that bandpower).

        :param array-like cls_in: array of bandpowers
        :return: array of power spectra
        """
        if(len(cls_in[0])!=self.bin.n_bands) :
            raise KeyError("Input Cl has wrong size")
        cl1d=lib.unbin_cl(self.bin,cls_in,len(cls_in)*(self.lmax+1))
        clout=np.reshape(cl1d,[len(cls_in),self.lmax+1])
        return clout

