% First part is importing the data and detrending it

% import the input set and detrend it
[~, ~, raw] = xlsread('C:\Users\Usuario\Desktop\Trabalho Final\0-Matlab\3 - RNA NARX\input_detrend.xlsx','Norm','A2:AA1235');
% transpose input matrix to feed into the ann
input = reshape([raw{:}],size(raw));
input = input';
% clear temporary variables
clearvars raw;

% import target set and detrend it
% Import the data
[~, ~, raw] = xlsread('C:\Users\Usuario\Desktop\Trabalho Final\0-Matlab\3 - RNA NARX\target_detrend.xlsx','Norm','A2:A1235');
% Create output variable and transpose the matrix to feed into the ann
target = reshape([raw{:}],size(raw));
target = target';
% Clear temporary variables
clearvars raw;

% X is the input
% T stands for target
% con2seq - Concurrent vectors to sequential vectors
X = con2seq(input); 
T = con2seq(target);

delay = 2; %NARX delay - same delay for input and target
N = 7; % N-delay =  Number of steps-ahead.

input = X(1:end-N); % split the data. Data set - N
target = T(1:end-N);
InputForecast  = X(end-N+1:end); % last N data points of the input set
TargetForecast = T(end-N+1:end); % last N data points of the target set

%neural net parameters
netLoop = 'open';
neurons = 20; %number of neurons
trainFcn = 'trainlm';  % Levenberg-Marquardt backpropagation
%initialize network
net = narxnet(1:delay,1:delay,neurons,netLoop,trainFcn);

%Preparing the data set for NARX model
[Xs,InputStateXs,LayerStateXs,Ts] = preparets(net,input,{},target);
%Training, validation and test ratio
net.divideFcn = 'divideblock'; %the default divide function in matlab is divirand
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

%network performance function - see "help nnperformance" for others
%mean squared error (mse)
net.performFcn = 'mse';

% Train the Network
tic
[net,tr] = train(net,Xs,Ts,InputStateXs,LayerStateXs);
TimeTraining = toc; %Training time
NumEpochs = tr.num_epochs; %number of epochs - type "tr" in the command window for more

%Network simulation
Y = net(Xs, InputStateXs, LayerStateXs);

% Closed Loop Network
netc = closeloop(net); %closed loop network - "view(netc)" in command window
%preparing the data for (N-delay) steps-ahead simulation
[XsForecast,InputStateForecast,LayerStateForecast,TsForecast] = preparets(netc,InputForecast, {}, TargetForecast);

%Closed networks simulation
Ypred = netc(XsForecast,InputStateForecast,LayerStateForecast); %Step-ahead results
% We need future data of the exogenous data to make a prediction

%Training, validation and test outputs
OutputTraining = Y(tr.trainInd);
OutputValidation = Y(tr.valInd);
OutputTest = Y(tr.testInd);

%Errors vectors (output-target)
ErrorTraining = gsubtract(Ts(1:length(tr.trainInd)),OutputTraining);
ErrorValidation = gsubtract(Ts(length(tr.trainInd)+1:length(tr.trainInd)+length(tr.valInd)),OutputValidation);
ErrorTest = gsubtract(Ts((length(Ts)-length(tr.testInd)+1):end), OutputTest);

%Performance
%mse
MSEtraining = mse(ErrorTraining);
MSEvalidation = mse(ErrorValidation);
MSEtest = mse(ErrorTest);

%mae
MAEtraining = mae(ErrorTraining);
MAEvalidation = mae(ErrorValidation);
MAEtest = mae(ErrorTest);

%Prediction error
ErrorPred = gsubtract(TsForecast,Ypred); %Error vector N-step length
%Pred performance
MSEpred = perform(net, TsForecast, Ypred); %mse
MAEpred = mae(ErrorPred); %mae

%Plot approximated function
figure
hold on
plot(cell2mat(Ts),'Marker','.','LineStyle','none');
plot(cell2mat(Y), 'r');
hold off
legend({'Ibovespa','Network output'},'Location','Northwest')
xlabel('Time (days)');
ylabel('Output x Target');
title('Artificial neural network regression, 20 neurons');
ax = gca;
ax.FontSize = 13;
axis tight

%Graph predicted values
indice = 900
figure;
plot([cell2mat(target(indice:end)),nan(1,N-delay);
nan(1,length(target(indice:end))),cell2mat(Ypred);
nan(1,length(target(indice:end))),cell2mat(TsForecast)]')
legend('Ibovespa','Network predictions','Target values', 'location', 'northwest')
xlabel('Time (days)');
ylabel('Ibovespa');
ax = gca;
ax.FontSize = 20;