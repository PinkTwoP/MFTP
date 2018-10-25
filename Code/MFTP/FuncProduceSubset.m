function [  ] = FuncProduceSubset( NetData,scale,filename )

A = NetData;

indexSelfloop = A(:,1) == A(:,2);
A(indexSelfloop,:) = [];

sizeof_A=size(A);





maxnum=max(A);
vertices=max(maxnum);
edges=sizeof_A(1);


s=scale:scale:vertices;
numofsubset=size(s);
numofsubset=numofsubset(2);

if(mod(vertices,10)~=0)
    s(numofsubset+1)=vertices;
end

nums=size(s);
nums=nums(2);

for  k=1:nums
    
    a=randperm(vertices);
    
    str1=num2str(s(k));
    str=['Input',filename,'(',str1,').txt'];
    fid=fopen(str,'wt');
    
    fprintf(fid,'%d ',vertices); % number of vertices for each layer(n)
    fprintf(fid,'%d ',edges);    % edges in layer 1(m1)
    fprintf(fid,'%d ',1);        % edges in layer 2(m2)
    fprintf(fid,'%d ',s(k));     % vertices which must be controlled in layer 1(s1)
    fprintf(fid,'%d \n',0);        % vertices which must be controlled in layer 2(s2)
    
    fprintf(fid,'\n');
    for i = 1 : 1 : edges          % m1 lines: two vertices of a directed edge in layer 1, vertices are numbered from 1 to n
        fprintf(fid,'%d %d \n',A(i,1),A(i,2));
    end
    
    fprintf(fid,'\n');
    for i = 1 : 1 : 1              % m2 lines: two vertices of a directed edge in layer 2, vertices are numbered from 1 to n
        fprintf(fid,'%d %d \n',1,2);
    end
    
    fprintf(fid,'\n');
    for i = 1 : 1 : s(k)           % s1 numbers, vertices which must be controlled in layer 1
        fprintf(fid,'%d ',a(i));
    end
    fprintf(fid,'\n');
    
    for i = 1 : 1 : 0              % s2 numbers, vertices which must be controlled in layer 2
        fprintf(fid,'%d ',a(i));
    end
    fprintf(fid,'\n');
    fclose(fid);
    
end

end

