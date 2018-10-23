function [  ] = FuncProduceSubset( NetData,scale,filename )

A = NetData;
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
fprintf(fid,'%d %d %d \n',vertices,edges,s(k));
 for i=1:edges
    fprintf(fid,'%d %d\n',A(i,1),A(i,2));
 end
  
 for i=1:s(k)
     fprintf(fid,'%d ',a(i));
 end
 
   fclose(fid);
    
 end

end

