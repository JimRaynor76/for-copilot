function varargout = behavior(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @behavior_OpeningFcn, ...
                   'gui_OutputFcn',  @behavior_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before behavior is made visible.
function behavior_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to behavior (see VARARGIN)

% Choose default command line output for behavior
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes behavior wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = behavior_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in sound_button.
function sound_button_Callback(hObject, eventdata, handles)
global tonesound2;
global sf;
sound(tonesound2,sf);

function Light_button_Callback(hObject, eventdata, handles)
function Soundlight_button_Callback(hObject, eventdata, handles)

function L_Vcorrectnumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function L_Vwrongnumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function L_Vnonresponsenumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function axes1_CreateFcn(hObject, eventdata, handles)
function axes1_ButtonDownFcn(hObject, eventdata, handles)
function pushbutton6_Callback(hObject, eventdata, handles)

function breakbutton_Callback(hObject, eventdata, handles)
global breakpoint;
breakpoint = 1;


function L_Vtotaltrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function PortL_Callback(hObject, eventdata, handles)
 so= daq.createSession ('ni'); 
  addDigitalChannel(so,'dev4','Port0/Line0:3', 'OutputOnly');
  outputSingleScan(so,[0 0 1 0]);
  pause(0.5);
  outputSingleScan(so,[0 0 0 0]);
  

% --- Executes on button press in Auto_running.
function Auto_running_Callback(hObject, eventdata, handles)
% hObject    handle to Auto_running (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global DurationInSeconds
global inputdata;
global DOutputs;
global tonesound1;
global tonesound2;
global breakpoint;
global Vcorrecttrial;
global Vwrongtrial;
global Vnoresptrial;
global trainingnumber;

global Acorrecttrial;
global Awrongtrial;
global Anoresptrial;

global A_Lcorrecttrial;
global A_Lwrongtrial;
global A_Lnoresptrial;

global A_Vcorrecttrial;
global A_Vwrongtrial;
global A_Vnoresptrial;

global L_Acorrecttrial;
global L_Awrongtrial;
global L_Anoresptrial;
global Noise_sound;
global L_Vcorrecttrial;
global L_Vwrongtrial;
global L_Vnoresptrial;
global L_A_Vcorrecttrial;
global L_A_Vwrongtrial;
global L_A_Vnoresptrial;

trainingnumber = 0;
Acorrecttrial = 0;
Awrongtrial = 0;
Anoresptrial = 0;

A_Vcorrecttrial= 0;
A_Vwrongtrial= 0;
A_Vnoresptrial= 0;

A_Lcorrecttrial= 0;
A_Lwrongtrial= 0;
A_Lnoresptrial= 0;

L_Acorrecttrial= 0;
L_Awrongtrial= 0;
L_Anoresptrial= 0;

L_Vcorrecttrial = 0;
L_Vwrongtrial = 0;
L_Vnoresptrial = 0;
L_A_Vcorrecttrial= 0;
L_A_Vwrongtrial= 0;
L_A_Vnoresptrial= 0;
Vcorrecttrial = 0;
Vwrongtrial = 0;
Vnoresptrial = 0;
 
% for auditory code
Acorrecttrial_right=0;Awrongtrial_right=0; Anoresptrial_right=0;
Acorrecttrial_left=0;Awrongtrial_left=0;  Anoresptrial_left=0;

set(handles.A_left_C,'String',num2str(Acorrecttrial_left)); 
set(handles.A_left_W, 'String',num2str(Awrongtrial_left)); 
set(handles.A_left_N, 'String',num2str(Anoresptrial_left)); 
 
set(handles.A_right_C,'String',num2str(Acorrecttrial_right)); 
set(handles.A_right_W, 'String',num2str(Awrongtrial_right)); 
set(handles.A_right_N, 'String',num2str(Anoresptrial_right)); 

% for auditory laser code 
A_Lcorrecttrial_right=0;A_Lwrongtrial_right=0; A_Lnoresptrial_right=0;
A_Lcorrecttrial_left=0; A_Lwrongtrial_left=0;  A_Lnoresptrial_left=0;

set(handles.A_Lleft_C,'String',num2str(A_Lcorrecttrial_left)); 
set(handles.A_Lleft_W, 'String',num2str(A_Lwrongtrial_left)); 
set(handles.A_Lleft_N, 'String',num2str(A_Lnoresptrial_left)); 
 
set(handles.A_Lright_C,'String',num2str(A_Lcorrecttrial_right)); 
set(handles.A_Lright_W, 'String',num2str(A_Lwrongtrial_right)); 
set(handles.A_Lright_N, 'String',num2str(A_Lnoresptrial_right)); 
  
pre_dur=.2;cue_dur=.2; post_dur=1.5;  % making additivity is 3; %  stimulus duration setting;
SR = 100000;                     % sample frequency (Hz)
beepLengthSecs = cue_dur;                          % duration (s)
Num_SR=round(beepLengthSecs*SR)
cf1 = linspace(3000,3000,Num_SR); % carrier frequency (Hz)
cf2 = linspace(12000,12000,Num_SR); % carrier frequency (Hz)
cf3 = linspace(6000,12000,Num_SR); % carrier frequency (Hz)
cf4 = linspace(12000,6000,Num_SR); % carrier frequency (Hz)
sound_ramp = 0.010;
Noise_sound = wgn(4410*3,1,10);Noise_sound=Noise_sound/max(abs(Noise_sound));
n = ceil(Num_SR);            % number of samples
m = ceil(round(SR* sound_ramp));          % ramp number
RampIndex = linspace(0,1,m); % modulation index matrix;
d = ones(1,n);
rampsize=size(RampIndex);
  for i = 1:rampsize(2);
   d(i)=RampIndex(i);
   d(n+1-i)=RampIndex(i);
  end;  
sn = SR*beepLengthSecs;                     % number of samples
s = (1:sn) / SR;                 % sound data preparation 
s1 = sin(2 *pi*cf1.*s)*0.5;       % sinusoidal modulation
s2 = sin(2 *pi*cf2.*s)*5;       % sinusoidal modulation
s3 = sin(2 *pi*cf3.*s);       % sinusoidal modulation
s4 = sin(2 *pi*cf4.*s);       % sinusoidal modulation
s1=d.*s1;
s2 = d.*s2;
s3=d.*s3;
s4 = d.*s4;
s_3k=[zeros(1,50000) s1 zeros(1,220001)];  s_3k=s_3k';  %50000 represents 0.5s;
s_3k_0=s_3k*0;                             s_3k_0=s_3k_0';
s_12k=[zeros(1,50000) s2 zeros(1,220001)]; s_12k=s_12k';
s_12k_0=s_12k*0;                            s_12k_0=s_12k_0';

% for auditory code
  numberoftime = 300;%numberoftime represent the time 
  controlvalue_center = 0; testdata_center=linspace(5,5,numberoftime);
  controlvalue_left = 0;testdata_left = linspace(5,5,numberoftime);
  controlvalue_right = 0;testdata_right = linspace(5,5,numberoftime); 
  time_duration = 0; 
  
  Ai= daq.createSession ('ni');     %dev needs change among different computers  
  Ai.addAnalogInputChannel('dev4', 0:1, 'Voltage');
  Ai.NumberOfScans=100;             % sample rate

  Ao=daq.createSession('ni'); % create a analogoutput channel to tell Intan for the recording during once triggered
  Ao.addAnalogOutputChannel('dev4',0:3,'voltage');%  1port auditory; 2port visual; %3port:commend line;4port:optogenetic;
%   Ao.IsContinuous=true;
  
       Ao.Rate=100000;       
       
       A_intensity=2;
       Y = wgn(20000, 1, 30)*0.001* A_intensity;sound(Y,Ao.Rate); % 0.2 s noise sound;
       Pre_duration=linspace(0, 0, pre_dur*Ao.Rate);  Pre_duration= Pre_duration';  %represented 0.5 s;
       post_duration=linspace(0, 0, post_dur*Ao.Rate+1);post_duration=post_duration'; % represented 2.8 s;
%        sound_signal_1=[Pre_duration;s1';post_duration]; sound_signal_2=[Pre_duration;s2';post_duration];
       Noise_sound=[Pre_duration;Y;post_duration];
       
       L_intensity=10;
       Light_1=linspace(L_intensity, L_intensity, cue_dur*Ao.Rate); % 3 represents the intensity of laser light 
       Light_1= Light_1';
       light_signal=[Pre_duration;Light_1;post_duration];
           
       Laser_state=1;           % 0 didnot work;%work
       head_time=0.2;
       delay_time=0.2;
       Laser_signal_1=linspace(5, 5, (head_time+cue_dur+delay_time)*Ao.Rate);     % 3 represents the intensity of laser light 
       Laser_signal_1=Laser_signal_1';
       Pre_duration_L=linspace(0, 0, (pre_dur-head_time)*Ao.Rate);  Pre_duration_L= Pre_duration_L';  %represented 0.5 s;
       post_duration_L=linspace(0, 0, (post_dur-delay_time)*Ao.Rate+1);post_duration_L=post_duration_L'; % represented 2.8 s;
       Laser_signal=[Pre_duration_L;Laser_signal_1;post_duration_L];
       Laser_signal=Laser_signal* Laser_state;
       
       control_RecordDuration=linspace(5, 5, Ao.Rate*1.9); % 2 represent 2 s
       control_RecordDuration=[control_RecordDuration 0];
       control_RecordDuration=control_RecordDuration';

       data_out_1=[Noise_sound light_signal control_RecordDuration Laser_signal*0.0005];
       data_out_2=[Noise_sound light_signal*0.0005 control_RecordDuration Laser_signal*0.0005];
       data_out_3=[Noise_sound*0.0005 light_signal control_RecordDuration Laser_signal*0.0005];
       data_out_4=[Noise_sound light_signal control_RecordDuration Laser_signal];
       data_out_5=[Noise_sound light_signal*0.0005 control_RecordDuration Laser_signal]; 
       data_out_6=[Noise_sound*0.0005 light_signal control_RecordDuration Laser_signal];
       data_out_7=[Noise_sound*0.0005 light_signal*0.0005 control_RecordDuration Laser_signal*2];
       
  Do= daq.createSession ('ni'); 
  addDigitalChannel(Do,'dev4','Port0/Line0:1', 'OutputOnly');
  outputSingleScan(Do,[0 0]);      
  stopindex=1;
breakpoint = 0;
sti_Num=[1 2 3 4 5 6]; 
 while trainingnumber <1000% determine the trial numner of training   
        trainingnumber = trainingnumber + 1;
     if breakpoint == 1;Ai.stop();stop(Ao);delete (Ai); delete (Ao);break; end;   
   while (controlvalue_center >90); % here set ai.samplerate 1000, so 300 represent 0.3 seconds
      inputdata1 = Ai.startForeground;
         subplot(4,1,1);plot(inputdata1(:,1));axis([0 100 -1 1]);
         subplot(4,1,2);plot(inputdata1(:,2));axis([0 100 -1 1]);
          Ai.stop();     
       data = inputdata1;
       testnumber = find(mean(data)<.15);        %.7 represent lick threshold
       controlvalue_center = length(testnumber);     
      if breakpoint == 1;Ai.stop();stop(Ao);delete (Ai); delete (Ao);break; end; 
   end;
     i=round(rand(1))+1;
     time_duration = 0;  
      % calculate the time from onsest of sound

      if trainingnumber<=1000;
           ii=rem(trainingnumber,length(sti_Num));
           if ii>0
               i=sti_Num(ii);
           else 
               i=sti_Num(length(sti_Num));
               sti_Num=randperm(6);
           end
      end
      disp(i);
 
%       i=3
      
     if i ==1;
         pause(.3);
         queueOutputData(Ao,data_out_1); startBackground(Ao);
%                 pause(.5)
%                 outputSingleScan(Do,[1 0]);
%                 pause(.03);
%                 outputSingleScan(Do,[0 0]); 
                Anoresptrial_left = Anoresptrial_left+1;      
                set(handles.A_left_N, 'String',num2str(Anoresptrial_left)); 
                 fid=fopen('E:\桌面\lmw\flah-noise-MD3mw','a+');
                 fprintf(fid,'%5d %5d\n',[i 0]);
                 fprintf(fid,'\n');
                 fclose(fid);
                 pause(2)

  elseif i ==2;
      pause(.3); 
      queueOutputData(Ao,data_out_2);
      startBackground(Ao); 
%                 pause(.5)
%                 outputSingleScan(Do,[0 1]);
%                 pause(.03);
%                 outputSingleScan(Do,[0 0]);
                 Anoresptrial_right = Anoresptrial_right+1;     
                set(handles.A_right_N, 'String',num2str(Anoresptrial_right));
                 fid=fopen('E:\桌面\lmw\flah-noise-MD3mw','a+');
                 fprintf(fid,'%5d %5d\n',[i 0]);
                 fprintf(fid,'\n');
                 fclose(fid);
                 pause(2)

     elseif i ==3;pause(.3);queueOutputData(Ao,data_out_3);startBackground(Ao);
%            pause(.5)
%                 outputSingleScan(Do,[1 0]);
%                 pause(.3);
%                 outputSingleScan(Do,[0 0]); 
                A_Lnoresptrial_left = A_Lnoresptrial_left+1;      
                set(handles.A_Lleft_N, 'String',num2str(A_Lnoresptrial_left)); 
                 fid=fopen('E:\桌面\lmw\flah-noise-MD3mw','a+');
                 fprintf(fid,'%5d %5d\n',[i 0]);
                 fprintf(fid,'\n');
                 fclose(fid);
                 pause(2)
                
  elseif i ==4; 
      pause(.3);
      queueOutputData(Ao,data_out_4); 
      startBackground(Ao); 
%             pause(.5)
%                 outputSingleScan(Do,[0 1]);
%                 pause(.3);
%                 outputSingleScan(Do,[0 0]);
                A_Lnoresptrial_right = A_Lnoresptrial_right+1;     
                set(handles.A_Lright_N, 'String',num2str(A_Lnoresptrial_right));
                 fid=fopen('E:\桌面\lmw\flah-noise-MD3mw','a+');
                 fprintf(fid,'%5d %5d\n',[i 0]);
                 fprintf(fid,'\n');
                 fclose(fid);
                 pause(2)
                           
       elseif i ==5;   
           pause(.3);
           queueOutputData(Ao,data_out_5); 
           startBackground(Ao);
                L_Vnoresptrial = L_Vnoresptrial+1;      
                set(handles.L_Vnonresponsenumber, 'String',num2str(L_Vnoresptrial)); 
%                      tt=datestr(now,13)
%              hhh=str2num(tt([1 2]));mmm=str2num(tt([4 5]));sss=str2num(tt([7 8]));
                 fid=fopen('E:\桌面\lmw\flah-noise-MD3mw','a+');             % save datafile   
                 fprintf(fid,'%5d %5d\n',[i 0]);
                 fprintf(fid,'\n');
                 fclose(fid);
                 pause(2)
                
                
       elseif i ==6;  
           pause(.3);
           queueOutputData(Ao,data_out_6); 
           startBackground(Ao) ;
                 L_A_Vnoresptrial = L_A_Vnoresptrial+1;     
                set(handles.L_A_Vnonresponsenumber, 'String',num2str(L_A_Vnoresptrial));
%                     tt=datestr(now,13)
%              hhh=str2num(tt([1 2]));mmm=str2num(tt([4 5]));sss=str2num(tt([7 8]));
                 fid=fopen('E:\桌面\lmw\flah-noise-MD3mw','a+');             % save datafile   
                 fprintf(fid,'%5d %5d\n',[i 0]);
                 fprintf(fid,'\n');
                 fclose(fid);
                 pause(2)
                           
       elseif i ==7;  
           pause(.3);
           queueOutputData(Ao,data_out_7); 
           startBackground(Ao) ;
                 L_A_Vnoresptrial = L_A_Vnoresptrial+1;     
                set(handles.L_A_Vnonresponsenumber, 'String',num2str(L_A_Vnoresptrial));
%                     tt=datestr(now,13)
%              hhh=str2num(tt([1 2]));mmm=str2num(tt([4 5]));sss=str2num(tt([7 8]));
                 fid=fopen('E:\桌面\lmw\flah-noise-MD3mw','a+');             % save datafile   
                 fprintf(fid,'%5d %5d\n',[i 0]);
                 fprintf(fid,'\n');
                 fclose(fid);
                 pause(2)
                           
    end;
 end;


% --- Executes during object creation, after setting all properties.


% --- Executes on button press in PortR.
function PortR_Callback(hObject, eventdata, handles)
% hObject    handle to PortR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 so= daq.createSession ('ni'); 
  addDigitalChannel(so,'dev4','Port0/Line0:3', 'OutputOnly');
  outputSingleScan(so,[0 0 0 1]);
  pause(0.5);
  outputSingleScan(so,[0 0 0 0]);; 


% --- Executes during object creation, after setting all properties.
function A_left_C_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_left_W_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_left_N_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function A_Lleft_C_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_Lleft_W_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_Lleft_N_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Atotaltrial_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Vrighttrial_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function A_right_N_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function A_right_C_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_Lright_N_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_Lright_C_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Vlefttrial_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function Vtotaltrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function A_Vcorrectnumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_Vwrongnumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_Vnonresponsenumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function A_Vtotaltrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function L_Arighttrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function L_Anonresponsenumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function L_Alefttrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function L_Atotaltrial_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function L_A_Vcorrectnumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function L_A_Vwrongnumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function L_A_Vnonresponsenumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





