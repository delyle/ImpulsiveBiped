# ImpulsiveBiped

This code solves optimal bipedal locomotion with Symmetrical contacts, inspired by [Srinivasan
and Ruina 2006](https://www.nature.com/articles/nature04113), using GPOPS-II in MATLAB.

The optimal control problem is to determine the work-minimizing
symmetrical bipedal gait for a given step length ($D$) and average speed
($U$). All variables are normalized to leg length, body mass, and
gravitational acceleration.

The problem starts with contact after flight phase, with an impulsive
contact. Stance is simulated until midstance, and the behaviour is
reflected (in reverse) through the rest of stance and the next flight
phase.

## Dependencies

The optimization requires [GPOPS-II](https://www.gpops2.com/) and [SNOPT](https://ccom.ucsd.edu/~optimizers/solvers/snopt/) and has been tested on MATLAB 2019a.

## Simple useage

Start by running the script `ImpulsiveBipedHalfStanceMAIN`. $U$ and $D$ can be altered in the script.

Documentation for various functions can be found by typing `help {functionName}` in the MATLAB terminal.