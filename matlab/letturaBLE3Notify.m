%% RESET
clc 
clear
close all

%% LOAD
modello = load("modello.mat");
modello = modello.ensMdl;

%% CAMPIONAMENTO DATI

% Inizializza la connessione Bluetooth
% device = ble("ArduinoNano33");
% device = ble("Arduino");

clear device;
device = ble("37C2AE93-8C10-4C81-5D15-0C7E389BDB3F");

% Caratteristiche accelerometro
c_acc_x=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10001-E8F2-537E-4F6C-D104768A1214");
c_acc_y=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10002-E8F2-537E-4F6C-D104768A1214");
c_acc_z=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10003-E8F2-537E-4F6C-D104768A1214");

% Caratteristiche giroscopio
c_gyro_x=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10021-E8F2-537E-4F6C-D104768A1214");
c_gyro_y=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10022-E8F2-537E-4F6C-D104768A1214");
c_gyro_z=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10023-E8F2-537E-4F6C-D104768A1214");

% Caratteristiche magnetometro
c_mag_x=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10031-E8F2-537E-4F6C-D104768A1214");
c_mag_y=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10032-E8F2-537E-4F6C-D104768A1214");
c_mag_z=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10033-E8F2-537E-4F6C-D104768A1214");

% Caratteristica timestamp
c_timeStamp=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10041-E8F2-537E-4F6C-D104768A1214");

% Subscribe a tutte le caratteristiche.
subscribe(c_acc_x);
subscribe(c_acc_y);
subscribe(c_acc_z);

subscribe(c_gyro_x);
subscribe(c_gyro_y);
subscribe(c_gyro_z);

subscribe(c_mag_x);
subscribe(c_mag_y);
subscribe(c_mag_z);

subscribe(c_timeStamp);

% Attesa dei dati
disp("In attesa di dati...");

j=1;
tempoIniziale = datetime('now');
threshold_acc = 2;

% Inizializzazione
dati_acc = zeros(1,3);
dati_gyro = zeros(1,3);
dati_mag = zeros(1,3);
dati_timeStamp = zeros(2,1);

classificazione = {};

% Campionamento
while (seconds(datetime('now') - tempoIniziale) <= 20) % Ciclo di 20 secondi
    data_acc_X = read(c_acc_x,"latest");
    data_acc_Y = read(c_acc_y,"latest");
    data_acc_Z = read(c_acc_z,"latest");
    dati_acc_iniz(1)=typecast(uint8(data_acc_X),'single');
    dati_acc_iniz(2)=typecast(uint8(data_acc_Y),'single');
    dati_acc_iniz(3)=typecast(uint8(data_acc_Z),'single');

    data_acc_sum = sum(abs(dati_acc_iniz));

    if data_acc_sum >= threshold_acc
        disp(['# Gesture' num2str(j)]);
        i=1;
        while(i<=30) % 30 campioni per ogni Gesture
            data_acc_X = read(c_acc_x,"latest");
            data_acc_Y = read(c_acc_y,"latest");
            data_acc_Z = read(c_acc_z,"latest");

            data_gyro_X = read(c_gyro_x,"latest");
            data_gyro_Y = read(c_gyro_y,"latest");
            data_gyro_Z = read(c_gyro_z,"latest");

            data_mag_X = read(c_mag_x,"latest");
            data_mag_Y = read(c_mag_y,"latest");
            data_mag_Z = read(c_mag_z,"latest");

            data_timeStamp = read(c_timeStamp,"latest");
            
            % Conversione
            dati_acc_gest(i,1)=typecast(uint8(data_acc_X),'single');
            dati_acc_gest(i,2)=typecast(uint8(data_acc_Y),'single');
            dati_acc_gest(i,3)=typecast(uint8(data_acc_Z),'single');

            dati_gyro_gest(i,1)=typecast(uint8(data_gyro_X),'single');
            dati_gyro_gest(i,2)=typecast(uint8(data_gyro_Y),'single');
            dati_gyro_gest(i,3)=typecast(uint8(data_gyro_Z),'single');

            dati_mag_gest(i,1)=typecast(uint8(data_mag_X),'single');
            dati_mag_gest(i,2)=typecast(uint8(data_mag_Y),'single');
            dati_mag_gest(i,3)=typecast(uint8(data_mag_Z),'single');

            dati_timeStamp_gest(i) = typecast(uint8(data_timeStamp),'int32');

            i=i+1;
        end
        
        % Salvataggio dei dati della Gesture
        dataMovimentoAcc{j} = dati_acc_gest;
        dataMovimentoGyro{j} = dati_gyro_gest;
        dataMovimentoMag{j} = dati_mag_gest;
        dataMovimentoTime{j} = dati_timeStamp_gest;
        
        % Classificazione
        dataMovimentoClassificazione{j}=[dati_acc_gest dati_gyro_gest];
        feature1 = mean(dataMovimentoClassificazione{j});
        feature2 = std(dataMovimentoClassificazione{j});
        features = [feature1 feature2];

        [y,Prob] = predict(modello,features);
        if y == 1
            disp(['Bicipite: ' num2str(Prob(1)) ', Spalle: ' num2str(Prob(2)) ', Altro: ' num2str(Prob(3))]);
            classificazione = [classificazione, 'Bicipite'];
        elseif y == 2
            disp(['Spalle: ' num2str(Prob(2)) ', Bicipite: ' num2str(Prob(1)) ', Altro: ' num2str(Prob(3)) ]) ;
            classificazione = [classificazione, 'Spalle'];
         elseif y == 3
             disp(['Altro: ' num2str(Prob(3)) ', Bicipite: ' num2str(Prob(1)) ', Spalle: ' num2str(Prob(2))]);
             classificazione = [classificazione, 'Altro'];
        end
        j = j+1;
    end
end

% Unsubscribe a tutte le caratteristiche
unsubscribe(c_acc_x);
unsubscribe(c_acc_y);
unsubscribe(c_acc_z);

unsubscribe(c_gyro_x);
unsubscribe(c_gyro_y);
unsubscribe(c_gyro_z);

unsubscribe(c_mag_x);
unsubscribe(c_mag_y);
unsubscribe(c_mag_z);

unsubscribe(c_timeStamp);

 %% CALIBRAZIONE: RIMOZIONE OFFSET
 
 m_offset_gyro = [1.9006, 1.8695, 1.4221];
 
 m_offset_acc = [-0.0023, -0.0353, -0.0180];
 
%% FILTRAGIO DATI FILTRO PASSA BANDA

for i=1:j-1

    % Rimozione offset
    dataMovimentoMag{i} = cast(dataMovimentoMag{i},"double");
    dataMovimentoAcc{i} = cast(dataMovimentoAcc{i} - m_offset_acc,"double");
    dataMovimentoGyro{i} = cast(dataMovimentoGyro{i} - m_offset_gyro,"double");

    % FILTRO
    f_low =0.3;
    f_high=2;

    nCampioni = size(dataMovimentoAcc{i},1);

    dt=double(dataMovimentoTime{i}(nCampioni)-dataMovimentoTime{i}(1))/(1000 * nCampioni); % 1000ms

    % FILTRAGGIO ACCELERAZIONI
    % default method BUTTERWORTH
    fpb=designfilt('bandpassiir', 'FilterOrder', 4, 'HalfPowerFrequency1', f_low, 'HalfPowerFrequency2',f_high,'SampleRate', 1/dt);
    dataMovimentoAcc_filt{i}=filtfilt(fpb,dataMovimentoAcc{i});

    % FILTRAGGIO GYRO
    % default method BUTTERWORTH
    dataMovimentoGyro_filt{i}=filtfilt(fpb,dataMovimentoGyro{i});
end

%% SENSOR FUSION CON MAGNETOMETRO - KALMANN FILTER
gravity = [0,0,0.9749 * 9.81];

for i=1:j-1
    dt=double(dataMovimentoTime{i}(nCampioni)-dataMovimentoTime{i}(1))/(1000 * nCampioni); % 1000ms
    fuse = ahrsfilter('SampleRate',1/dt);

    q{i} = fuse(dataMovimentoAcc{i},dataMovimentoGyro{i},dataMovimentoMag{i});

    %     figure('Name','Orientation Estimate');
    %     plot(eulerd( q, 'ZYX', 'frame'));
    %     title('Orientation Estimate');
    %     legend('Z-rotation', 'Y-rotation', 'X-rotation');
    %     ylabel('Degrees');

    % COMPENSAZIONE GRAVITA'
    gframe = rotateframe(q{i},gravity);
    dataMovimentoAcc_comp{i} = dataMovimentoAcc{i}.*9.81 - gframe;

    dataMovimentoAcc_comp{i} = cast(dataMovimentoAcc_comp{i},"double");

    % FILTRAGGIO ACCELERAZIONI COMPENSATE
    f_low =0.6;
    f_high=1.5;

    % default method BUTTER
    fpb=designfilt('bandpassiir', 'FilterOrder', 4, 'HalfPowerFrequency1', f_low, 'HalfPowerFrequency2',f_high,'SampleRate', 1/dt);

    dataMovimentoAcc_compfilt{i}=filtfilt(fpb,dataMovimentoAcc_comp{i});
end



%% Conversione Deg -> Rad e G -> m/s^2

for i=1:j-1
dataMovimentoAcc{i} = dataMovimentoAcc{i}.*9.81;
dataMovimentoGyro{i} = deg2rad(dataMovimentoGyro{i});

dataMovimentoAcc_filt{i} = dataMovimentoAcc_filt{i}.*9.81;
dataMovimentoGyro_filt{i} = deg2rad(dataMovimentoGyro_filt{i});

dataMovimentoAcc_compfilt{i} = dataMovimentoAcc_compfilt{i};
end

%% CONFRONTO GRAFICO
fig = figure('Name', 'Movimenti');

% Creazione del pannello a schede
tab_group = uitabgroup(fig);

for i = 1:j-1
    % Creazione di una nuova scheda per ogni movimento
    tab = uitab(tab_group, 'Title', sprintf('Movimento %d: %s', i, classificazione{i}));
    
    % Creazione di un nuovo pannello all'interno della scheda
    panel = uipanel(tab);

    % TimeStamp
    sub(1,1:nCampioni) = dataMovimentoTime{i}(1,1);
    
    % Plot delle accelerazioni non filtrate
    subplot(3,1,1, 'Parent', panel);
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)),dataMovimentoAcc{i}(:,1),'DisplayName','X NON Filtrata','Color','b');
    hold on;
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)),dataMovimentoAcc{i}(:,2),'DisplayName','Y NON Filtrata','Color','g');
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)),dataMovimentoAcc{i}(:,3),'DisplayName','Z NON Filtrata','Color','r');
    hold off;
    legend('show');
    xlabel('Tempo [ms]');
    ylabel('Accelerazioni [m/s^2]');
    title('Accelerazioni NON Filtrate');
    
    % Plot delle accelerazioni compensate per la gravità
    subplot(3,1,2, 'Parent', panel);
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)),dataMovimentoAcc_compfilt{i}(:,1),'DisplayName','X compensata gravità','Color','b');
    hold on;
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)),dataMovimentoAcc_compfilt{i}(:,2),'DisplayName','Y compensata gravità','Color','g');
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)),dataMovimentoAcc_compfilt{i}(:,3),'DisplayName','Z compensata gravità','Color','r');
    hold off;
    legend('show');
    xlabel('Tempo [ms]');
    ylabel('Accelerazioni [m/s^2]');
    title('Accelerazioni filtrate con compensazione della gravità');
    
    % Plot delle accelerazioni filtrate
    subplot(3,1,3, 'Parent', panel);
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)) ,dataMovimentoAcc_filt{i}(:,1),'DisplayName','X Filtrata','Color','b');
    hold on;
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)) ,dataMovimentoAcc_filt{i}(:,2),'DisplayName','Y Filtrata','Color','g');
    plot((dataMovimentoTime{i}(1,:) - sub(1,:)) ,dataMovimentoAcc_filt{i}(:,3),'DisplayName','Z Filtrata','Color','r');
    hold off;
    legend('show');
    xlabel('Tempo [ms]');
    ylabel('Accelerazioni [m/s^2]');
    title('Accelerazioni Filtrate');
end

%% INTEGRAZIONI
for i = 1:j-1
    dataMovimentoVelInt{i} = cumtrapz(dataMovimentoAcc_filt{i}.* dt, 1) ;
    dataMovimentoPosizioneInt{i} = cumtrapz(dataMovimentoVelInt{i} .*dt,1);
end

%% PLOT POSIZIONI
mainFig = figure('Name', 'Posizioni x y z');
tabGroup = uitabgroup(mainFig);

for i = 1:j-1
    % Creazione di una nuova scheda
    tab = uitab(tabGroup, 'Title', sprintf('Movimento %d: %s', i, classificazione{i}));
    
    % Creazione del grafico nella scheda corrente
    axes('parent', tab);
    plot3(dataMovimentoPosizioneInt{i}(:,1), dataMovimentoPosizioneInt{i}(:,2), dataMovimentoPosizioneInt{i}(:,3), '-');
    
    % Imposta la stessa scala per entrambi gli assi
    axis equal;
    grid on;
    
    % Etichette degli assi
    xlabel('Asse X');
    ylabel('Asse Y');
    zlabel('Asse Z');
    
    % Titolo della figura
    title(['Posizione XYZ ', num2str(i)]);
end