clear all
tic
batchSize = 100;                        % one batch means For each batch, 
                                        % we randomly chose $|S|$ nodes 
                                        % from the whole network under 
                                        % uniform distribution gradually 
                                        % from $|S|=10$ to $|S|=1000$ 
                                        % (this indicates in one batch the 
                                        % larger $|S|$ subset evolves from
                                        % smaller $|S|$ subset and all 
                                        % subsets evolve from $|S|=10$ 
                                        % subset)


for meanDegree = 1 : 1 : 5              % the loop for different mu
 
FilePath = pwd;                          % get the file path

%% load network
cd(fullfile(FilePath,'NetworkData'))          % cd the file path to 
                                         % network data document

networkName = 'ER_Network_1000node_3meandegree'; % set the file name 
                                               % of network
eval(['load(''',networkName,'.mat'')']); % load 'networkName' network data 
                                         % which is an edge set
                                         % each row is an edge
                                         % the first column is out vertex
                                         % the second column is in vertex

disp('network data loaded.')
A = double(A);                           % 'A' denoted as the net data

scale = 10;                              % the interval between subsets
                                         % i.e. |S|=scale,2*scale,...,1000
NumScale = floor(max(max(A))/scale);     % Number of subsets in one batch


filename = ['ER1000',num2str(meanDegree),'']; % the file name 

%% MFTP 
cd(fullfile(FilePath,'C++','max_cost_flow','max_cost_flow_exe')) % cd to the C++
                                                            % MFTP codes
disp('MFTP starts.')
for kkk = 1 : 1 : batchSize
    disp(['Batch = ',num2str(kkk), ...
        '. Meandegree = ',num2str(meanDegree),'..'])
    fprintf('%c%c', 8, 8);
    FuncProduceSubset( A,scale,filename );   % randomly generate subsets
    
    % run MFTP 
    for i = scale : scale : NumScale*scale
        eval(['[status,result] = system(''max_cost_flow<Input',filename ...
            ,'(',num2str(i),').txt>Output',filename,'(',num2str(i), ...
            ').txt'');'])
    end
    
    disp(' Done!')
    
    NumDriver = zeros(1,NumScale);     % the minimum number of diver nodes
    for i = scale : scale : NumScale*scale
        eval(['fid = fopen(''Output',filename, ...
            '(',num2str(i),').txt'',''r'');'])
        temp1 = str2double(fscanf(fid,'%s',[1,1]));
        NumDriver(i/scale) = temp1;
        fclose(fid);
    end
    
    if ~exist(fullfile(FilePath,'Result','interim_result'))
        mkdir(fullfile(FilePath,'Result','interim_result'));
    end
    cd(fullfile(FilePath,'Result','interim_result'))
    eval(['save MaxFlowResult',num2str(kkk),' NumDriver'])% save the result
    cd(fullfile(FilePath,'C++','max_cost_flow','max_cost_flow_exe'))
    
    % delete the used files
    for i = scale:scale:NumScale*scale
        eval(['delete(''Input',filename,'(',num2str(i),').txt'')'])
        try
            error(lastwarn)
        catch
            eval(['delete(''Input',filename,'(',num2str(i),').txt'')'])
        end
        eval(['delete(''Output',filename,'(',num2str(i),').txt'')'])
        try
            error(lastwarn)
        catch
            eval(['delete(''Output',filename,'(',num2str(i),').txt'')'])
        end
    end

end

%% average the result
NumDriverMat = zeros(batchSize,NumScale);
for i = 1 : 1 : batchSize
    eval(['load(''MaxCostResult',num2str(i),''')']);
    for j = 1 : 1 : NumScale
        NumDriverMat(i,j) = NumDriver(j);
    end
    clear NumDriverMaxCost
    clear NumControlNodeMaxCost
end

NumDriverResult = sum(NumDriverMat,1)/batchSize; % get the average result
                                                 % through batches


Frac= 1:scale/1000:1;

Nd = NumDriverResult/NumDriverResult(end);      % normalized the result
Nd = [0 Nd];                                    % Nd is the final 
                                                % normalized result of 
                                                % minimum number of 
                                                % driver nodes of
                                                % target subset

cd(fullfile(FilePath,'Result'))
eval(['save ',filename,'Result_Scale',num2str(scale), ...
    'Batch_Size',num2str(batchSize),''])        % save the result

end
toc