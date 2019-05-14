i = 2;
figure
subplot(1,2,1);
plot(-M_seabed( (i-1) * Dx_index + 1, 1:1000))
hold on
plot(1:Dy_index:1001, -(z_auv + old_samples(i,:)),'o');
xlabel("X [m]");
xlim([0 1001]);
t = get(gca, 'XTick');
set(gca, 'XTick', t, 'XTickLabel', t/100)
ylabel("Depth [m]");
hold off
subplot(1,2,2);
plot(-M_seabed( (i-1) * Dx_index + 1, 1:1000))
xlim([0 1001]);
hold on
plot(1:Dy_index:1001, -(z_auv + M_dep_samples(i,:)),'o');
xlabel("X [m]");
t = get(gca, 'XTick');
set(gca, 'XTick', t, 'XTickLabel', t/100)
ylabel("Depth [m]");
hold off