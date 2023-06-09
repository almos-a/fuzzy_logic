% Mamdani FIS 
clear
close all
clc

%%
load('Data.mat');
X = inputData(:,2:4);
Y = inputData(:,9);
%% load data
in_name = ["in1","in2","in3"];
out_name = ["out1","out2","out3","out3","out4"];

[m, n] = size(X) ;
[p, q] = size(Y);
P = 0.80 ; % usig 80% data for training and 20% for validation
idx = randperm(m);
idy = randperm(p);

trnX = X(idx(1:round(P*m)),:); 
vldX = X(idx(round(P*m)+1:end),:);

trnY = Y(idx(1:round(P*m)),:); 
vldY = Y(idx(round(P*m)+1:end),:);

% % using odd even split
% trnX = X(1:2:end,:); % Training input data set odd idx
% trnY = Y(1:2:end,:); % Training output data set
% vldX = X(2:2:end,:); % Validation input data set even idx
% vldY = Y(2:2:end,:); % Validation output data set
%% Initialise fis
dataRange = [min(inputData)' max(inputData)'];

fisin = mamfis; % mamdani fis

for i = 2:4
    fisin = addInput(fisin,dataRange(i,:),'Name',in_name(i-1),'NumMFs',3,'MFType',"gaussmf"); % gbellmf works with sugeno
end
for j = 9
    fisin = addOutput(fisin,dataRange(j,:),'Name',out_name(j-4),'NumMFs',27,'MFType',"gaussmf");
end
figure
plotfis(fisin)
%% Initial tuning of fis with data
options = tunefisOptions('Method','particleswarm',...
    'OptimizationType','learning');
options.UseParallel = true;
options.MethodOptions.MaxIterations = 20;
rng('default')
runtunefis = true;

fisout1 = tunefis(fisin,[],trnX,trnY,options); 
figure
plotfis(fisout1)

[fisout1.Rules.Description]'
plotActualAndExpectedResultsWithRMSE(fisout1,vldX,vldY)
%% tune FIS parameters
[in,out,rule] = getTunableSettings(fisout1);
options.OptimizationType = 'tuning';
options.Method = 'patternsearch';
options.MethodOptions.MaxIterations = 60;
options.MethodOptions.UseCompletePoll = true;

fisout = tunefis(fisout1,[in;out;rule],trnX,trnY,options); 

figure
plotfis(fisout)
%% check performance
plotActualAndExpectedResultsWithRMSE(fisout,vldX,vldY);

%% HELPER FUNCTIONS
function plotActualAndExpectedResultsWithRMSE(fis,x,y)

% Calculate RMSE bewteen actual and expected results
[rmse,actY] = calculateRMSE(fis,x,y);

% Plot results
figure
subplot(2,1,1)
hold on
bar(actY)
bar(y)
bar(min(actY,y),'FaceColor',[0.5 0.5 0.5])
hold off
% axis([0 5 0 30])
xlabel("Validation input dataset index"),ylabel("outputs")
legend(["Actual Outputs" "Expected Outputs" "Minimum of actual and expected values"],...
        'Location','NorthWest')
title("RMSE = " + num2str(rmse))

subplot(2,1,2)
bar(actY-y)
xlabel("Validation input dataset index"),ylabel("Error")
title("Difference Between Actual and Expected Values")

end

function [rmse,actY] = calculateRMSE(fis,x,y)

% Specify options for FIS evaluation
persistent evalOptions
if isempty(evalOptions)
    evalOptions = evalfisOptions("EmptyOutputFuzzySetMessage","none", ...
        "NoRuleFiredMessage","none","OutOfRangeInputValueMessage","none");
end

% Evaluate FIS
actY = evalfis(fis,x,evalOptions);

% Calculate RMSE 
del = actY - y;
rmse = sqrt(mean(del.^2));

end