clear all
tic
batchSize = 1;                        % one batch means For each batch, 
                                        % we randomly chose $|S|$ nodes 
                                        % from the whole network under 
                                        % uniform distribution gradually 
                                        % from $|S|=10$ to $|S|=1000$ 
                                        % (this indicates in one batch the 
                                        % larger $|S|$ subset evolves from
                                        % smaller $|S|$ subset and all 
                                        % subsets evolve from $|S|=10$ 
                                        % subset)


for meanDegree = 3 : 1 : 3              % the loop for different mu
 
FilePath = pwd;                          % get the file path

%% load network
cd(fullfile(FilePath,'NetworkData'))          % cd the file path to 
                                         % network data document

networkName =[ 'ER_Network_1000node_',num2str(meanDegree),'meandegree']; % set the file name 
                                               % of network
eval(['load(''',networkName,'.mat'')']); % load 'networkName' network data 
                                         % which is an edge set
                                         % each row is an edge
                                         % the first column is out vertex
                                         % the second column is in vertex

disp('network data loaded.')
A = double(A);                           % 'A' denoted as the net data


scale = 100;                              % the interval between subsets
                                         % i.e. |S|=scale,2*scale,...,1000
NumScale = floor(max(max(A))/scale);     % Number of subsets in one batch


filename = ['ER1000',num2str(meanDegree),'']; % the file name 

%% MFTP 
cd(fullfile(FilePath,'MFTP')) % cd to the C++
                                                            % MFTP codes
disp('MFTP starts.')
for kkk = 1 : 1 : batchSize
    disp(['Batch = ',num2str(kkk), ...
        '. Meandegree = ',num2str(meanDegree),'..'])
    fprintf('%c%c', 8, 8);
    FuncProduceSubset( A,scale,filename );   % randomly generate subsets
    
    % run MFTP 
    for i = scale : scale : NumScale*scale
        if exist(fullfile(pwd,'in.txt'))
            eval(['delete(''in.txt'')'])
        end
        eval(['!rename', ' Input',filename,'(',num2str(i),').txt', ' in.txt'])
        eval(['[status,result] = system(''multi_layer'');'])
        eval(['delete(''in.txt'')'])
%         try
%             error(lastwarn)
%         catch
%             eval(['delete(''in.txt'')'])
%         end
        if exist(fullfile(pwd, ['Output',filename,'(',num2str(i),').txt']))
            eval(['delete(''Output',filename,'(',num2str(i),').txt'')'])
        end
        eval(['!rename',' out.txt', ' Output',filename,'(',num2str(i),').txt'])
    end
    
    disp(' Done!')
    
    NumDriver = zeros(1,NumScale);     % the minimum number of diver nodes
    for i = scale : scale : NumScale*scale
        eval(['fid = fopen(''Output',filename, ...
            '(',num2str(i),').txt'',''r'');'])
        temp1 = fscanf(fid,'%s',[1,7]);
%         for scanind = 1 : 1 : 7
%             temp1 = fscanf(fid,'%s',[1,1]);
%         end    
        temp1 = temp1(isstrprop(temp1,'digit'));
        NumDriver(i/scale) = str2double(temp1);
        fclose(fid);
    end
    
    if ~exist(fullfile(FilePath,'Result','interim_result'))
        mkdir(fullfile(FilePath,'Result','interim_result'));
    end
    cd(fullfile(FilePath,'Result','interim_result'))
    eval(['save MaxFlowResult',num2str(kkk),' NumDriver'])% save the result
    cd(fullfile(FilePath,'MFTP'))
    
    % delete the used files
    for i = scale:scale:NumScale*scale
        eval(['delete(''Output',filename,'(',num2str(i),').txt'')'])
%         try
%             error(lastwarn)
%         catch
%             eval(['delete(''Output',filename,'(',num2str(i),').txt'')'])
%         end
    end

end

%% average the result
NumDriverMat = zeros(batchSize,NumScale);
cd(fullfile(FilePath,'Result','interim_result'))
for i = 1 : 1 : batchSize
    eval(['load(''MaxFlowResult',num2str(i),''')']);
    for j = 1 : 1 : NumScale
        NumDriverMat(i,j) = NumDriver(j);
    end
    clear NumDriverMaxCost
    clear NumControlNodeMaxCost
end

NumDriverResultNorm = NumDriverMat/NumDriverMat(1,end);
NumDriverResult = sum(NumDriverMat,1)/batchSize; % get the average result
                                                 % through batches


Frac= 1:scale/1000:1;

Nd = NumDriverResult/NumDriverResult(end);      % normalized the result
Nd = [0 Nd];                                    % Nd is the final 
                                                % normalized result of 
                                                % minimum number of 
                                                % driver nodes of
                                                % target subset
variance = var(NumDriverResultNorm);
maxVari  = max(variance);                       % the variance of the final
                                                % results

disp(['max variance is ',num2str(maxVari),'. '])
                                                
cd(fullfile(FilePath,'Result'))
eval(['save ',filename,'Result_Scale',num2str(scale), ...
    'Batch_Size',num2str(batchSize),''])        % save the result

end
toc