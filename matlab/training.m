%% RESET
clc 
clear
close all

%% CAMPIONAMENTO DATI
% Inizializza la connessione Bluetooth
%device = ble("ArduinoNano33");
device = ble("37C2AE93-8C10-4C81-5D15-0C7E389BDB3F");

%caratteristiche accelerometro
c_acc_x=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10001-E8F2-537E-4F6C-D104768A1214");
c_acc_y=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10002-E8F2-537E-4F6C-D104768A1214");
c_acc_z=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10003-E8F2-537E-4F6C-D104768A1214");

%caratteristiche giroscopio
c_gyro_x=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10021-E8F2-537E-4F6C-D104768A1214");
c_gyro_y=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10022-E8F2-537E-4F6C-D104768A1214");
c_gyro_z=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10023-E8F2-537E-4F6C-D104768A1214");

%caratteristiche magnetometro
c_mag_x=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10031-E8F2-537E-4F6C-D104768A1214");
c_mag_y=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10032-E8F2-537E-4F6C-D104768A1214");
c_mag_z=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10033-E8F2-537E-4F6C-D104768A1214");

%Caratteristica timestamp
c_timeStamp=characteristic(device,"19B10000-E8F2-537E-4F6C-D104768A1214","19B10041-E8F2-537E-4F6C-D104768A1214");

%subscribe a tutte le caratteristiche
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

% Attendi i dati
disp("In attesa di dati...");

j=1;
p=datetime("now");
gesture = 100;
threshold_acc = 2;

% Campionamento
while (j <= gesture)
    data_acc_X = read(c_acc_x,"oldest");
    data_acc_Y = read(c_acc_y,"oldest");
    data_acc_Z = read(c_acc_z,"oldest");
    dati_acc_iniz(1)=typecast(uint8(data_acc_X),'single');
    dati_acc_iniz(2)=typecast(uint8(data_acc_Y),'single');
    dati_acc_iniz(3)=typecast(uint8(data_acc_Z),'single');

    data_acc_sum = sum(abs(dati_acc_iniz));

    if data_acc_sum >= threshold_acc
        disp(['# Gesture' num2str(j)]);
        i=1;
        while(i<=20)
            data_acc_X = read(c_acc_x,"oldest");
            data_acc_Y = read(c_acc_y,"oldest");
            data_acc_Z = read(c_acc_z,"oldest");

            data_gyro_X = read(c_gyro_x,"oldest");
            data_gyro_Y = read(c_gyro_y,"oldest");
            data_gyro_Z = read(c_gyro_z,"oldest");

            data_mag_X = read(c_mag_x,"oldest");
            data_mag_Y = read(c_mag_y,"oldest");
            data_mag_Z = read(c_mag_z,"oldest");

            data_timeStamp = read(c_timeStamp,"oldest");
            
            % Conversione
            dati_acc(i,1)=typecast(uint8(data_acc_X),'single');
            dati_acc(i,2)=typecast(uint8(data_acc_Y),'single');
            dati_acc(i,3)=typecast(uint8(data_acc_Z),'single');

            dati_gyro(i,1)=typecast(uint8(data_gyro_X),'single');
            dati_gyro(i,2)=typecast(uint8(data_gyro_Y),'single');
            dati_gyro(i,3)=typecast(uint8(data_gyro_Z),'single');

            % dati_mag(i,1)=typecast(uint8(data_mag_X),'single');
            % dati_mag(i,2)=typecast(uint8(data_mag_Y),'single');
            % dati_mag(i,3)=typecast(uint8(data_mag_Z),'single');

            % dati_timeStamp(i) = typecast(uint8(data_timeStamp),'int32');
            
            i=i+1;
        end
        dataMovimento{j}=[dati_acc dati_gyro];
        j = j+1;
    end
end
% tempo = (datetime("now")-p);

% unsubscribe
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

%% LOADING
bicipite = load("trainingBicipite100.mat");
spalle = load("trainingSpalle100.mat");
altro = load("trainingAltro100.mat");

trainingBicipite = bicipite.dataMovimento';
trainingSpalle = spalle.dataMovimento';
trainingAltro = altro.dataMovimento';

%% MODEL

for ind = 1:100
  featureBicipite1(ind,:) = mean(trainingBicipite{ind});
  featureBicipite2(ind,:) = std(trainingBicipite{ind});

  featureSpalle1(ind,:) = mean(trainingSpalle{ind});
  featureSpalle2(ind,:) = std(trainingSpalle{ind});

  featureAltro1(ind,:) = mean(trainingAltro{ind});
  featureAltro2(ind,:) = std(trainingAltro{ind});
end

X = [featureBicipite1,featureBicipite2;
featureSpalle1,featureSpalle2;
featureAltro1,featureAltro2]; 
% labels - 1: Bicipite, 2: Spalle, 3: Altro
Y = [ones(100,1);2*ones(100,1);3*ones(100,1)];

%% DATASET PREPARATION
rng('default') % For reproducibility
Partition = cvpartition(Y,'Holdout',0.20); %% 20% validazione
trainingInds = training(Partition); % Indices for the training set
XTrain = X(trainingInds,:);
YTrain = Y(trainingInds);
testInds = test(Partition); % Indices for the test set
XTest = X(testInds,:);
YTest = Y(testInds);

%% TRAINING
template = templateTree(...
    'MaxNumSplits', 399);

ensMdl = fitcensemble(...
    XTrain, ...
    YTrain, ...
    'Method', 'Bag', ...
    'NumLearningCycles', 20, ...
    'Learners', template, ...
    'ClassNames', [1; 2; 3]);


%% ACCURACY
% Evaluate performance of test data
testAccuracy = 1-loss(ensMdl,XTest,YTest)