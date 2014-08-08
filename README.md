pretty_print
============

%If a command (local function call) is not recognized by the shell, 
%an attempt is first made to find the function in the module user_default, 
%where customized local commands can be placed. If found, then the function is evaluated. 
%Otherwise, an attempt is made to evaluate the function in the module shell_default. 
%The module user_default must be explicitly loaded.

%There is some support for reading and printing records in the shell. 
%During compilation record expressions are translated to tuple expressions. 
%In runtime it is not known whether a tuple actually represents a record. 
%Nor are the record definitions used by compiler available at runtime. 
%So in order to read the record syntax and print tuples as records when possible, 
%record definitions have to be maintained by the shell itself. The shell commands for reading, 
%defining, forgetting, listing, and printing records are described below. 
%Note that each job has its own set of record definitions. 
%To facilitate matters record definitions in the modules shell_default and user_default (if loaded) are read each time a new job is started.


%% Author sorawa 2013-2-4

%% this module load the record 

%% pretty print

%% How to use this module:

%% First include all record to this file

%% use -include("record.hrl")

%% compile this module by debug model

%% pretty_print:init() to load module info

%% use pp(Record) to pretty print the Record
