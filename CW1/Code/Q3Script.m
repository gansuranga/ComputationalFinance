%% import data
% The 100 stocks of the FTSE 100 are merged together using R and saved to a
% csv. The values are then imported into matlab as a matrix, with y
% labels(names) and x labels(dates) imported as seperate vectors to
% preserve the matrix type. 
import_script
import_dates
import_names
stockNames = x;
Date = flipud(Date);
joinedstocks = flipud(joinedstocks);
FTSE = joinedstocks(:,size(joinedstocks,2));
%% Calculate return matrix
stocks_shift = circshift(joinedstocks, 1);
stocks_return = (joinedstocks - stocks_shift) ./ stocks_shift;
stocks_return = stocks_return(2:length(stocks_return),:);

FTSE_return = stocks_return(:,size(stocks_return,2));
stocks_return = stocks_return(:,1:size(stocks_return,2)-1);

Interest = 0.005 / 365;

%% Split into training and testing set
N = length(stocks_return);
stocks_ts = stocks_return(2:ceil(N/2),:);
stocks_tr = stocks_return(ceil(N/2)+1 : N,:);

FTSE_ts = FTSE_return(2:ceil(N/2),:);
FTSE_tr = FTSE_return(ceil(N/2)+1 : N,:);

Date_ts = Date(2:ceil(N/2),:);
Date_tr = Date(ceil(N/2)+1 : N,:);

%% Regularised
tau = 0.2;
y = 99;
NAssets = size(stocks_tr,2);
while y > 6
    tau = tau * 1.005;
    cvx_begin
    variable Port_reg(1,NAssets) nonnegative
    minimize( norm( FTSE_tr - stocks_tr * Port_reg', 2) +  ...
        tau * norm( Port_reg, 1 ) )
    cvx_end
    y = sum(Port_reg > 0.0001);
end
Port_reg(Port_reg < 0.0001) = 0;
Port_reg = Port_reg ./ sum(Port_reg);

%% Also 1/N
tau = 0.2;
y = 99;
NAssets = size(stocks_tr,2);
Port_N = ones(NAssets,1);
while y > 6
    tau = tau * 1.005;
    cvx_begin
    variable Port_reg_N(1,NAssets) nonnegative
    minimize( norm( stocks_tr * Port_N - stocks_tr * Port_reg_N', 2) +  ...
        tau * norm( Port_reg_N, 1 ) )
    cvx_end
    y = sum(Port_reg_N > 0.0001);
end
Port_reg_N(Port_reg_N < 0.0001) = 0;
Port_reg_N = Port_reg_N ./ sum(Port_reg_N);

%% Greedy

Port_greed = greedy(zeros(NAssets,1), stocks_tr, FTSE_tr);

for i = 1:5
    Port_greed = greedy(Port_greed, stocks_tr, FTSE_tr);
end

%% Also Greedy track 1/N

Port_greed_N = greedy(zeros(NAssets,1), stocks_tr, stocks_tr*Port_N);
for i = 1:5
    Port_greed_N = greedy(Port_greed_N, stocks_tr, FTSE_tr);
end

%% Differences in approximation of FTSE index
a(1) = mean(Port_greed * stocks_tr' - FTSE_tr');
a(2) = mean(Port_greed * stocks_tr' - FTSE_tr');
a(3) = mean(Port_reg * stocks_tr' - FTSE_tr');
a(4) = mean(Port_greed * stocks_ts' - FTSE_ts');
a(5) = mean(Port_reg * stocks_ts' - FTSE_ts');

b(1) = 2*var(Port_greed * stocks_tr' - FTSE_tr');
b(2) = 2*var(Port_greed * stocks_tr' - FTSE_tr');
b(3) = 2*var(Port_reg * stocks_tr' - FTSE_tr');
b(4) = 2*var(Port_greed * stocks_ts' - FTSE_ts');
b(5) = 2*var(Port_reg * stocks_ts' - FTSE_ts');
%% Use these portfolios to compute performance metrics on the test set

% Greedy
Greed_ret_ts = Port_greed * stocks_ts'; 
metric(1,1) = mean(Greed_ret_ts); %Greed_mean_ts
metric(2,1) = var(Greed_ret_ts);%Greed_var_ts
metric(3,1) = sharpe(Greed_ret_ts, Interest); %Greed_sharpe_ts
metric(4,1) = portvrisk(metric(1,1), metric(2,1)); %Greed_VaR_ts

% Regularised
Reg_ret_ts = Port_reg * stocks_ts'; 
metric(1,2) = mean(Reg_ret_ts); %Reg_mean_ts
metric(2,2) = var(Reg_ret_ts); %Reg_var_ts
metric(3,2) = sharpe(Reg_ret_ts, Interest); %Reg_sharpe_ts
metric(4,2) = portvrisk(metric(1,2), metric(2,2)); %Reg_VaR_ts

% FTSE
FTSE_ret_ts = FTSE_ts; 
metric(1,3) = mean(FTSE_ret_ts); % FTSE_mean_ts
metric(2,3) = var(FTSE_ret_ts); %FTSE_var_ts
metric(3,3) = sharpe(FTSE_ret_ts, Interest); %FTSE_sharpe_ts
metric(4,3) = portvrisk(metric(1,3), metric(2,3)); %FTSE_VaR_ts

% 1/N
N_ret_ts = Port_N' * stocks_ts'; 
metric(1,4) = mean(N_ret_ts);  %N_mean_ts
metric(2,4) = var(N_ret_ts); %N_var_ts
metric(3,4) = sharpe(N_ret_ts, Interest); %N_sharpe_ts
metric(4,4) = portvrisk(metric(1,4), metric(2,4)); %N_VaR_ts

% Greedy 1/N
Greed_ret_ts = Port_greed_N * stocks_ts'; 
metric(1,5) = mean(Greed_ret_ts); %Greed_mean_ts
metric(2,5) = var(Greed_ret_ts);%Greed_var_ts
metric(3,5) = sharpe(Greed_ret_ts, Interest); %Greed_sharpe_ts
metric(4,5) = portvrisk(metric(1,5), metric(2,5)); %Greed_VaR_ts

% Regularised 1/N
Reg_ret_ts = Port_reg_N * stocks_ts'; 
metric(1,6) = mean(Reg_ret_ts); %Reg_mean_ts
metric(2,6) = var(Reg_ret_ts); %Reg_var_ts
metric(3,6) = sharpe(Reg_ret_ts, Interest); %Reg_sharpe_ts
metric(4,6) = portvrisk(metric(1,6), metric(2,6)); %Reg_VaR_ts
%% Plot returns of greedy, regularised approximations vs. FTSE
figure(1)
scatter(FTSE_tr, Port_greed * stocks_tr', 2);
hold on
scatter(FTSE_tr, Port_reg * stocks_tr', 2);
xlabel('FTSE train');
ylabel('Approximation train');

figure(2)
scatter((Port_greed * stocks_tr'), (Port_reg * stocks_tr'), 2)

figure(3)
scatter(FTSE_ts, Port_greed * stocks_ts', 2);
hold on
scatter(FTSE_ts, Port_reg * stocks_ts', 2);
xlabel('FTSE train');
ylabel('Approximation train');

figure(4)
subplot(2,1,1)
hist(Port_greed * stocks_ts' - FTSE_ts', 50);
hold on
plot([a(4),a(4)],ylim,'r--','LineWidth',2)
title('Greedy')
ylabel('Frequency')

subplot(2,1,2)
hist(Port_reg * stocks_ts' - FTSE_ts', 50);
hold on
plot([a(5),a(5)],ylim,'r--','LineWidth',2)
xlabel('Difference in daily return with FTSE100')
ylabel('Frequency')
title('Lasso Regularisation')
hold off