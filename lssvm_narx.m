file_path = 'C:\Users\Usuario\Desktop\Trabalho Final\0-Matlab\4 - LSSVM\0-scripts\target_detrend.xlsx';

% Import the input data
[~, ~, raw] = xlsread(file_path,'Norm','A2:AA1235');
% Create output variable
input = reshape([raw{:}],size(raw));
input_set = input';

% Import the target data
[~, ~, raw] = xlsread(file_path,'Norm','A2:A1235');
% Create output variable
target = reshape([raw{:}],size(raw));
target_set = target';
% Clear temporary variables
clearvars raw;
clear input;

input_set = con2seq(input_set);
target_set = con2seq(target_set);

N = 7; % N is used to split the data sets. N-delay will be the the forecast horizon
delay = 2;

input = input_set(1:end-N); % split the data. input set lenght - N
target = target_set(1:end-N);
forecast_input  = input_set(end-N+1:end); %last N data points of the input set
forecast_target = target_set(end-N+1:end); %last N data points of the input set

%input sets (training, validation, test)
training_input = input(1:848); 
validation_input = input(849:1030);
test_input = input(1031:end);
%target sets (training, validation, test)
training_target = target(1:848);
validation_target = target(849:1030);
test_target = target(1031:end);

%cell type back to double type (data type has to be double to be fed into the lssvm)
training_input = cell2mat(training_input);
validation_input = cell2mat(validation_input);
test_input = cell2mat(test_input);
forecast_input = cell2mat(forecast_input);
training_target = cell2mat(training_target);
validation_target = cell2mat(validation_target);
test_target = cell2mat(test_target);
forecast_target = cell2mat(forecast_target);

%transposing the data to feed into the model - Matrix time-steps x 1
training_input = training_input';
validation_input = validation_input';
test_input = test_input';
forecast_input = forecast_input';
training_target = training_target';
validation_target = validation_target';
test_target = test_target';
forecast_target = forecast_target';

%{
The model needs to be trained using Xw (x_training), Yw (y_training) which is the result of windowize() or windowizeNARX().
The purpose of windowizeNARX() is to re-arrange the data points into a (block) Hankel matrix for (N)AR(X) time-series modeling
See toolbox documentation
%}
[x_training,y_training]=windowizeNARX(training_input,training_target,delay,delay);

%{
The kernel used is a Gaussian RBF kernel
Type classification or function estimation
gam and sig2 are tuning parameters. Gam is the regularization parameter, determining the trade-off between the training error
minimization and smoothness. sig2 is the squared bandwidth
tunelssvm() - Tune the tuning parameters of the model with respect to the given performance measure
simplex is an optimization algorithm that works for all kernels in the toolbox
leave-one-out cross validation is used
mse is the cost function
%}
kernel = 'RBF_kernel';
type = 'function estimation';
tic % tuning time starts here
[gam,sig2] = tunelssvm({x_training,y_training,type,[],[],kernel},'simplex',...
'leaveoneoutlssvm',{'mse'});
tuning_time = toc; % ends here

% Re-arrange validation, test and forecast data points
[x_validation,y_validation]=windowizeNARX(validation_input,validation_target,delay,delay);
[x_test,y_test]=windowizeNARX(test_input,test_target,delay,delay);
[x_forecast,y_forecast]=windowizeNARX(forecast_input, forecast_target,delay,delay);

% initlssvm() - Initiate the LS-SVM object before training
model = initlssvm(x_training,y_training,type,gam,sig2,kernel);
% trainlssvm() - Train the support values and the bias term of an LS-SVM
model = trainlssvm(model);
training_time = model.duration;
% plotlssvm() - Plot the LS-SVM results in the environment of the training data
plotlssvm(model);

% simlssvm() - simlssvm evaluate the LS-SVM at given points - training points
training_sim = simlssvm(model, x_training);
training_error = gsubtract(y_training,training_sim);
% performance metrics
training_mse = sum(sum(training_error.^2)) / numel(training_error);
training_mae = mae(training_error);
training_r2 = 1 - (sum((y_training - training_sim).^2) / sum((y_training - mean(y_training)).^2));

% validation points sim
validation_sim = simlssvm(model, x_validation);
validation_error = gsubtract(y_validation,validation_sim);
% performance metrics
validation_mse = sum(sum(validation_error.^2)) / numel(validation_error);
validation_mae = mae(validation_error);
validation_r2 = 1 - (sum((y_validation - validation_sim).^2) / sum((y_validation - mean(y_validation)).^2));

% test points simulation
test_sim = simlssvm(model, x_test);
test_error = gsubtract(y_test,test_sim);
% performance metrics
test_mse = sum(sum(test_error.^2)) / numel (test_error);
test_mae = mae(test_error);
test_r2 = 1 - (sum((y_test - test_sim).^2) / sum((y_test - mean(y_test)).^2));

%{
predict() - Iterative prediction of a trained LS-SVM NARX model (in recurrent mode)
%}
y_prediction = predict({x_training,y_training,type,gam,sig2}, forecast_input, N);
prediction_error = gsubtract(y_forecast,y_prediction); % error vector
% performance metrics
prediction_mse = sum(sum(prediction_error.^2)) / numel (prediction_error);
prediction_mae = mae(prediction_error);
prediction_r2 = 1 - (sum((y_forecast - y_prediction).^2) / sum((y_forecast - mean(y_forecast)).^2));

%Plots
%coloring
color1 = 'k'; %used on original target data set
color2 = 'b'; %used on original training set
color3 = 'g'; %used on original validation set
color4 = 'r'; %used on original test set
color5 = 'm'; %used on prediction
dot_size = 12;

%training plot
figure
plot(y_training,'Color',color1','Marker','.','LineStyle','none','MarkerSize',dot_size);
hold on
plot(training_sim, 'Color', color2);
legend({'Original data','Model output'},'Location','Northwest');
xlabel('Time (days)');
ylabel('Model output x Desired value');
title(['Training - LS-SVM_{\gamma= ' num2str(gam) ',\sigma^2= ' num2str(sig2) '}^{RBF}']);
ax = gca;
ax.FontSize = 20;
axis tight

%validation plot
figure
plot(y_validation,'Color',color1','Marker','.','LineStyle','none','MarkerSize',dot_size);
hold on
plot(validation_sim, 'Color', color3);
legend({'Original data','Model output'},'Location','Northwest');
xlabel('Time (days)');
ylabel('Model output x Desired value');
title(['Simulation: Validation set - LS-SVM_{\gamma= ' num2str(gam) ',\sigma^2= ' num2str(sig2) '}^{RBF}']);
ax = gca;
ax.FontSize = 20;
axis tight

%test plot
figure
plot(y_test,'Color',color1','Marker','.','LineStyle','none','MarkerSize',dot_size);
hold on
plot(test_sim, 'Color', color4);
legend({'Original data','Model output'},'Location','Northwest');
xlabel('Time (days)');
ylabel('Model output x Desired value');
title(['Simulation: Test set - LS-SVM_{\gamma= ' num2str(gam) ',\sigma^2= ' num2str(sig2) '}^{RBF}']);
ax = gca;
ax.FontSize = 20;
axis tight

%forecast plot
figure
plot(y_forecast,'Color',color1','Marker','.','LineStyle','none','MarkerSize',dot_size);
hold on
plot(y_prediction,'-*','Color', color5);
legend({'Original data','Prediction output'},'Location','Northeast');
xlabel('Time (days)');
ylabel('Prediction x Desired value');
title(['Prediction - LS-SVM_{\gamma= ' num2str(gam) ',\sigma^2= ' num2str(sig2) '}^{RBF}']);
ax = gca;
ax.FontSize = 13;
axis tight