% Detrend data script

t = 0:1233; % data set lenght and the horizon on plot
ticker = Ibovespa; %Ibovespa is a variable with the data points
title = 'Tendência - Ibovespa';

figure('Name',title,'NumberTitle','off');
plot(t, ticker);
legend('Original data','Location','northwest');
xlabel('Time (days)');
ylabel('Ibovespa (points)');
detrend_data = detrend(ticker);
trend = ticker - detrend_data;
hold on
plot(t,trend,':r', 'LineWidth', 1.5)
plot(t,detrend_data,'m')
plot(t,zeros(size(Data)),':k', 'LineWidth', 1.5) %detrend line average
legend('Original data','Trend of original data','Detrended data',...
       'Detrended data average','Location','northwest')
xlabel('Número de amostras');
ylabel('Ibovespa (points)');
ax = gca;
ax.FontSize = 20;
axis tight
%title(titulo_grafico); shg