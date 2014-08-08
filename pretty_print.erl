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

-module(pretty_print).
-include("../include/ige.hrl").
-export([ start_link/0,
 init/0,
 reload/0,
 get_meta/0,
 read_file_records/2,
 pretty_print/2,
 record_size/1,
 record_cols/1,
 pp/1]).

-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(ETS_RECORD,ets_record).
-define(LINEMAX,30).
%% ============================================
%% API Functions
%% ============================================
start_link()->
gen_server:start_link( {local,?MODULE},?MODULE,[],[]).

init()->
{ok, _} = supervisor:start_child(
ige_sup, {pretty_print,
{pretty_print, start_link,[]},
permanent, infinity, worker, [pretty_print]}).

reload()->
code:load_abs(?MODULE).

get_meta() -> 
user_default:module_info().


record_attrs(Forms) ->
    [begin
insert_into_ets(RecordName,ColInfo),
A
end || A = {attribute,_,record,{RecordName,ColInfo} } <- Forms].

read_file_records(File, _Opts) ->
    case filename:extension(File) of
        ".beam" ->
            case beam_lib:chunks(File, [abstract_code,"CInf"]) of
                {ok,{_Mod,[{abstract_code,{Version,Forms}},{"CInf",_CB}]}} ->
                    case record_attrs(Forms) of
                        [] when Version =:= raw_abstract_v1 ->
                            [];
                        [] -> 
                            %% If the version is raw_X, then this test
                            %% is unnecessary.
                            [];
                        Records -> 
                            Records
                    end;
                {ok,{_Mod,[{abstract_code,no_abstract_code},{"CInf",_CB}]}} ->
                    {error,no_abstract_code};
                Error ->
                    %% Could be that the "Abst" chunk is missing (pre R6).
                    Error
            end;
        _ ->
            {error,notbeam}
    end.

insert_into_ets(Key,Info)->
ets:insert(?ETS_RECORD, {Key,Info}).

pretty_print(Format,Argv) when is_list(Argv)->
Format,
ok.

pp(Rec) -> 
    RF = fun(R,L) -> 
  Flds = record_cols(R),
  %io:fwrite(" R = ~p REC = ~p~n L = ~p l2 = ~p~n",[R,record_cols(Rec),L,length(Flds)]),
       true = (L == length(Flds)), 
       Flds 
    end, 
case record_size(Rec) of
0 -> io:fwrite("~p",[Rec]);
    _ -> io_lib:format("~s",[io_lib_pretty:print(Rec,?LINEMAX,RF)])
end.

%example:
%{record_field,262,{atom,262,gold},{integer,262,0}},

record_size(R) when is_tuple(R)->
RN = element(1, R),
record_size(RN);

record_size(R) when is_atom(R)->
case ets:lookup(?ETS_RECORD, R) of
[] -> 0;
[{_Key,Cols}]	-> length(Cols)
end.


record_cols(R) when is_tuple(R) ->
RN = element(1, R),
record_cols(RN);

record_cols(R) when is_atom(R) ->
[{_Key,Cols}] = ets:lookup(?ETS_RECORD, R),
[begin
if 
size(EL) > 3  ->	%have a default value
{record_field,_,{_,_,L},_} = EL,
L;
 	true	->  %%
{record_field,_,{_,_,L}} = EL,
L
end
end || EL <-Cols].


%% ============================================
%% OTP Callbacks
%% ============================================


% --------------------------------------------------------------------
% Function: init/1
% Description: Initiates the server
% Returns: {ok, State}          |
%          {ok, State, Timeout} |
%          ignore               |
%          {stop, Reason}
% --------------------------------------------------------------------
init([]) ->
?DEBUG(" ~p OTP INIT ~n" ,[?MODULE]),
ets:new(?ETS_RECORD, [named_table , public ,set] ),
BeamName = atom_to_list(?MODULE) ++ ".beam", 
read_file_records(BeamName,[]),
    {ok, {}}.

% --------------------------------------------------------------------
% Function: handle_call/3
% Description: Handling call messages
% Returns: {reply, Reply, State}          |
%          {reply, Reply, State, Timeout} |
%          {noreply, State}               |
%          {noreply, State, Timeout}      |
%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%          {stop, Reason, State}            (terminate/2 is called)
% --------------------------------------------------------------------
handle_call(_Request, _From, State) ->
Reply = ok,
    {reply, Reply, State}.


% --------------------------------------------------------------------
% Function: handle_cast/2
% Description: Handling cast messages
% Returns: {noreply, State}          |
%          {noreply, State, Timeout} |
%          {stop, Reason, State}            (terminate/2 is called)
% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

% --------------------------------------------------------------------
% Function: handle_info/2
% Description: Handling all non call/cast messages
% Returns: {noreply, State}          |
%          {noreply, State, Timeout} |
%          {stop, Reason, State}            (terminate/2 is called)
% --------------------------------------------------------------------
handle_info(_Msg, State) ->
{noreply,State}.

% --------------------------------------------------------------------
% Function: terminate/2
% Description: Shutdown the server
% Returns: any (ignored by gen_server)
% --------------------------------------------------------------------
terminate(_Reason, State) ->
?DEBUG("fuck iam die state = ~p~n",[State]),
    ok.

% --------------------------------------------------------------------
% Func: code_change/3
% Purpose: Convert process state when code is changed
% Returns: {ok, NewState}
% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
