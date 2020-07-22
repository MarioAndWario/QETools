#!/usr/bin/env python
import numpy as np
import io
import os
import sys

omega_threshold=4.09;
file=io.open("./jdos_Si.dat","rb");
rawdata=np.genfromtxt(file,comments='#');
omega=np.zeros((len(rawdata)),dtype='float');
jdos=np.zeros((len(rawdata)),dtype='float');
omega[:]=rawdata[:,0]
jdos[:]=rawdata[:,1]
file.close()

omega_threshold_position=np.ravel(np.where(omega[:]==omega_threshold))[0];
print("omega_threshold_position = ", omega_threshold_position)

# manually calculate the integral by summation \sum w_i eps_2(w_i) Delta w_i
area=np.trapz(jdos[0:omega_threshold_position+1],omega[0:omega_threshold_position+1]);
print("area = ", area);
