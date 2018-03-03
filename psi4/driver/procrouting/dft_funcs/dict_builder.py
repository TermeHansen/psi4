#
# @BEGIN LICENSE
#
# Psi4: an open-source quantum chemistry software package
#
# Copyright (c) 2007-2017 The Psi4 Developers.
#
# The copyrights for code used from other parties are included in
# the corresponding files.
#
# This file is part of Psi4.
#
# Psi4 is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, version 3.
#
# Psi4 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with Psi4; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# @END LICENSE
#
"""
Builder function
"""
from psi4 import core
from psi4.driver.p4util.exceptions import *
from psi4.driver.qcdb.dashparam import dashcoeff

import copy

from . import dict_xc_funcs
from . import dict_lda_funcs
from . import dict_gga_funcs
from . import dict_mgga_funcs
from . import dict_hyb_funcs
from . import dict_dh_funcs

dict_functionals = {}
dict_functionals.update(dict_xc_funcs.functional_list)
dict_functionals.update(dict_lda_funcs.functional_list)
dict_functionals.update(dict_gga_funcs.functional_list)
dict_functionals.update(dict_mgga_funcs.functional_list)
dict_functionals.update(dict_hyb_funcs.functional_list)
dict_functionals.update(dict_dh_funcs.functional_list)

def get_functional_aliases(functional_dict):
    if "alias" in functional_dict.keys():
        aliases = [each.upper() for each in functional_dict["alias"]]
        aliases.append(functional_dict["name"].upper())
    else:
        aliases = [functional_dict["name"].upper()]
    return aliases

# alias table for dispersion
dispersion_names = {}
dispersion_names["d2p4"] = "d2p4"
dispersion_names["d2gr"] = "d2gr"
dispersion_names["d3zero"] = "d3zero"
dispersion_names["d3bj"] = "d3bj"
dispersion_names["d3mzero"] = "d3mzero"
dispersion_names["d3mbj"] = "d3mbj"
dispersion_names["d"] = "d2p4"
dispersion_names["d2"] = "d2p4"
dispersion_names["d3"] = "d3zero"
dispersion_names["d3m"] = "d3mzero"

functionals = {}
for functional_name in dict_functionals.keys():
    functional_aliases = get_functional_aliases(dict_functionals[functional_name])
    # first process aliases of parent functional
    for alias in functional_aliases:
        functionals[alias] = dict_functionals[functional_name]
    # if the functional is already dispersion corrected, skip to next
    if "dispersion" in dict_functionals[functional_name].keys():
        continue
    # loop through dispersion types in dashparams incl aliases 
    # and build dispersion corrected version incl aliases
    for dispersion_name in dispersion_names.keys():
        dispersion_type = dispersion_names[dispersion_name]
        for dispersion_functional in dashcoeff[dispersion_type].keys():
            if dispersion_functional.upper() in functional_aliases:
                func = copy.deepcopy(dict_functionals[functional_name])
                func["name"] = func["name"] + "-" + dispersion_type
                func["dispersion"] = dict()
                if "citation" in dashcoeff[dispersion_type][dispersion_functional].keys():
                    func["dispersion"]["citation"] = dashcoeff[dispersion_type][dispersion_functional]["citation"]
                func["dispersion"]["type"] = dispersion_type
                func["dispersion"]["params"] = dashcoeff[dispersion_type][dispersion_functional]
                for alias in functional_aliases:
                    alias = alias + "-" + dispersion_name.upper()
                    functionals[alias] = func

def check_consistency(func_dictionary, func_name):
    """
    This checks the consistency of the definitions of exchange and correlation components
    of the functional, including detecting duplicate requests for LibXC params, inconsistent
    requests for HF exchange and missing correlation.
    """
    # 1a) sanity checks definition of xc_functionals
    if "xc_functionals" in func_dictionary.keys():
        if "x_functionals" in func_dictionary.keys() or "x_hf" in func_dictionary.keys():
            raise ValidationError("SCF: Duplicate specification of exchange (XC + X) in functional %s." % (name))
        elif "c_functionals" in func_dictionary.keys() or "c_mp2" in func_dictionary.keys():
            raise ValidationError("SCF: Duplicate specification of correlation (XC + C) in functional %s." % (name))
    # 1b) require at least an empty exchange functional entry or X_HF
    elif "x_functionals" not in func_dictionary.keys() and "x_hf" not in func_dictionary.keys():
        raise ValidationError("SCF: No exchange specified in functional %s." % (name))
    # 1c) require at least an empty correlation functional entry or C_MP2
    elif "c_functionals" not in func_dictionary.keys() and "c_mp2" not in func_dictionary.keys():
        raise ValidationError("SCF: No correlation specified in functional %s." % (name))
    use_libxc = 0
    if "x_functionals" in func_dictionary.keys():
        for item in func_dictionary["x_functionals"]:
            if "use_libxc" in func_dictionary["x_functionals"].keys(
            ) and func_dictionary["x_functionals"][item]["use_libxc"]:
                use_libxc += 1
    # 2a) only 1 component in x_functionals can have "use_libxc": True to prevent libxc conflicts
    if use_libxc > 1:
        raise ValidationError("SCF: Duplicate request for libxc exchange parameters in functional %s." % (name))
    # 2b) if "use_libxc" is defined in x_functionals, there shouldn't be "x_hf"
    elif use_libxc == 1 and "x_hf" in func_dictionary.keys():
        raise ValidationError("SCF: Inconsistent definition of exchange in functional %s." % (name))
    # 2c) ensure requested libxc params are for a functional that is included in "x_functionals"
    elif "x_hf" in func_dictionary.keys(
    ) and "use_libxc" in func_dictionary["x_hf"] and func_dictionary["x_hf"]["use_libxc"] not in func_dictionary["x_functionals"].keys(
    ):
        raise ValidationError(
            "SCF: Libxc parameters requested for an exchange functional not defined as a component of functional %s." %
            (name))


def build_superfunctional_from_dictionary(name, npoints, deriv, restricted):
    check_consistency(functionals[name], name)
    if "xc_functionals" in functionals[name].keys():
        for xc_key in functionals[name]["xc_functionals"].keys():
            xc_name = "XC_" + xc_key
        sup = core.SuperFunctional.XC_build(xc_name, restricted)
        descr = "    " + name.upper() + " "
        if sup.is_gga():
            if sup.x_alpha() > 0:
                descr += "Hyb-GGA "
            else:
                descr += "GGA "
        descr += "Exchange-Correlation Functional\n"
        sup.set_description(descr)
    else:
        sup = core.SuperFunctional.blank()
        descr = []
        citation = []
        x_HF = {"ALPHA": 0.0, "OMEGA": 0.0, "BETA": 0.0}
        if "x_functionals" in functionals[name].keys():
            x_funcs = functionals[name]["x_functionals"]
            for x_key in x_funcs.keys():
                x_name = "XC_" + x_key
                x_func = core.LibXCFunctional(x_name, restricted)
                x_params = x_funcs[x_key]
                if "use_libxc" in x_params and x_params["use_libxc"]:
                    x_HF = x_func.query_libxc("XC_HYB_CAM_COEF")
                    x_func.set_alpha(1.0)
                if "tweak" in x_params.keys():
                    x_func.set_tweak(x_params["tweak"])
                if "alpha" in x_params.keys():
                    x_func.set_alpha(x_params["alpha"])
                if "omega" in x_params.keys():
                    x_func.set_omega(x_params["omega"])
                sup.add_x_functional(x_func)
                if x_func.citation() not in citation:
                    citation.append(x_func.citation())
                if x_func.description() not in descr:
                    descr.append(x_func.description())
        if "x_hf" in functionals[name].keys():
            x_params = functionals[name]["x_hf"]
            if "use_libxc" in x_params.keys():
                x_name = "XC_" + x_params["use_libxc"]
                x_HF = core.LibXCFunctional(x_name, restricted).query_libxc("XC_HYB_CAM_COEF")
            if "alpha" in x_params.keys():
                sup.set_x_alpha(x_params["alpha"])
            else:
                x_params["alpha"] = 0.0
            if "beta" in x_params.keys():
                sup.set_x_beta(x_params["beta"])
            if "omega" in x_params.keys():
                sup.set_x_omega(x_params["omega"])
        else:
            sup.set_x_alpha(x_HF["ALPHA"] + x_HF["BETA"])
            sup.set_x_beta(x_HF["ALPHA"] - x_HF["BETA"])
            sup.set_x_omega(x_HF["OMEGA"])
        if "c_functionals" in functionals[name].keys():
            c_funcs = functionals[name]["c_functionals"]
            for c_key in c_funcs.keys():
                c_name = "XC_" + c_key
                c_func = core.LibXCFunctional(c_name, restricted)
                c_params = functionals[name]["c_functionals"][c_key]
                if "tweak" in c_params.keys():
                    c_func.set_tweak(c_params["tweak"])
                if "alpha" in c_params.keys():
                    c_func.set_alpha(c_params["alpha"])
                else:
                    c_func.set_alpha(1.0)
                sup.add_c_functional(c_func)
                if c_func.citation() not in citation:
                    citation.append(c_func.citation())
                if c_func.description() not in descr:
                    descr.append(c_func.description())
        if "c_mp2" in functionals[name].keys():
            c_params = functionals[name]["c_mp2"]
            if "alpha" in c_params.keys():
                sup.set_c_alpha(c_params["alpha"])
            else:
                sup.set_c_alpha(0.0)
            if "ss" in c_params:
                sup.set_c_ss_alpha(c_params["ss"])
            if "os" in c_params:
                sup.set_c_os_alpha(c_params["os"])
        descr = "\n".join(descr)
        citation = "\n".join(citation)
        sup.set_citation(citation)
        sup.set_description(descr)

    if "citation" in functionals[name].keys():
        sup.set_citation(functionals[name]["citation"])
    if "description" in functionals[name].keys():
        sup.set_description(functionals[name]["description"])

    dispersion = False
    if "dispersion" in functionals[name].keys():
        d_params = functionals[name]["dispersion"]
        if "citation" not in d_params.keys():
            d_params["citation"] = False
        dispersion = d_params

    sup.set_max_points(npoints)
    sup.set_deriv(deriv)
    sup.set_name(name.upper())
    sup.allocate()
    return (sup, dispersion)
