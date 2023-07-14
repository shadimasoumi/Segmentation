function [mask, IndexInnerSheath,IndexOuterSheath,IndexBallLens] = SegmentationGraphTheoryLowProfile2023(Int,innerSheath,outerSheath,lens)
%function SegmentationGraphTheoryRaw takes an Intensity image, inner sheath interface, outer
%sheath interface and ball lens position in the first Aline as inputs and
%segment the sheath position (inner and outer interface) and ball lens using "graph cut theory" and shortestpath function. 
%The function also segments sample surface using intesity threshholding at each Aline. 
% The outputs are: inner sheath interface position (IndexInnerSheath),
% outer sheath interface position (IndexOuterSheath),ball lens position
% (IndexBallLens) and sample surface position (mask).
% you can find more explanations regarding function at https://docs.google.com/document/d/1_d8Z2g6wU7FuqjHEJF4l2_bAgwZrghwdY70G0u5doaw/edit?usp=sharing


baseIntensity= Int;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ball lens segmentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ballIn=lens; % input lens Index
tile=32;    %we devide the whole intesnity image into [st.alines_per_frame/2)*st.frame_count)/tile] images.
%In fact, every 32 Alines are considered as one image.    
thickness= 16;  %here we define a new roiz to segment lens.
%only 16 pixels above and 16 pixels under selected lens index are being proceed.(33 pixels in total)
%Every time, there is a 33-by-32 image to be processed.


pathXXX1=[]; 
pathXX1=[]; 
pathX1=[]; 

%performing median filtering, each output pixel contains the median value of its 5-by-5 neighbourhood.
Intensity=medfilt2(baseIntensity(),[5 5]);
% Intensity=baseIntensity; 
originalsize=size(Intensity);

%mat2tiles function considers every tile=32 Alines as one image.
    blocks=mat2tiles(Intensity(),originalsize(1),tile);
    
    for n=1:(originalsize(2))/tile
     
            %pad images with vertical columns on both sides
            %adding two column of zeros on each side and assigning lower
            %weight to them, in this way, seed is selected automatically.
            img1=blocks{1, n} ;
            img1=img1(ballIn-thickness:ballIn+thickness-2,:);


            szImg = size(img1);
            imgNew = zeros([szImg(1) szImg(2)+2]);
            imgNew(:,2:szImg(2)+1) = img1;
            szImgNew = size(imgNew);  
            % get  vertical gradient image (normalized)
            gradImg = nan(szImgNew);
               for i = 1:szImgNew(2)
                gradImg(:,i) = 1*gradient(imgNew(:,i),2);
               end
            gradImg = (gradImg-min(gradImg(:)))/(max(gradImg(:))-min(gradImg(:)));
            
       
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %generate adjacency matrix
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %minimum weight
            minWeight = 1E-5;
   
            %arry to store weights
            adjMW = nan([numel(imgNew(:)),8]);
            %arry to store point A locations
            adjMX = nan([numel(imgNew(:)),8]);
            %arry to store point B locations
            adjMY = nan([numel(imgNew(:)),8]);
            neighborIter = [1 1  1 0  0 -1 -1 -1;...
                            1 0 -1 1 -1  1  0 -1];
            szadjMW = size(adjMW);
            ind = 1; indR = 0;
            while ind ~= szadjMW(1)*szadjMW(2)
                [i, j] = ind2sub(szadjMW,ind);    
                [iX,iY] = ind2sub(szImgNew,i);    
                jX = iX + neighborIter(1,j);
                jY  = iY + neighborIter(2,j);
                 if jX >=1 && jX <= szImgNew(1) && jY >=1 && jY <= szImgNew(2)
                   %save weight
                   % set weight to minimum if on the sides
                   if   jY == 1 || jY == szImgNew(2)
                        adjMW(i,j) = minWeight;
                   else
                       %else, calculate the actual weight.
                      adjMW(i,j) = 2 - gradImg(iX,iY) - gradImg(jX,jY) + minWeight;
                   end
                   %save the subscript of the corresponding nodes
                    adjMX(i,j) = (sub2ind(szImgNew,iX,iY));
                    adjMY(i,j) = (sub2ind(szImgNew,jX,jY));
                 end
                ind = ind+1;
            end
            %assemble the adjacency matrix
            keepInd = ~isnan(adjMW(:)) & ~isnan(adjMX(:)) & ~isnan(adjMY(:));
            adjMW = adjMW(keepInd);
            adjMX = adjMX(keepInd);
            adjMY = adjMY(keepInd);
            
            %sparse matrices, based on with the gradient image
            %adjMatrixW is the graph
            adjMatrixW = graph((adjMX(:)),(adjMY(:)),adjMW(:));

             %adjMatrixW is the graph and 1 is the seed.
            [path1{1}] = shortestpath( (adjMatrixW), 1, numel(imgNew(:)) );
            [pathX1,pathY1] = ind2sub(szImgNew,path1{1});
            
            % get rid of first and last few points that is by the image
            % border
            pathX1 =pathX1(gradient(pathY1)~=0);
            pathY1 =pathY1(gradient(pathY1)~=0);
            pathX1=pathX1(1,2:end-1);
            %obtainig the actual sheath position in the image
            pathX1=pathX1+ballIn-thickness;
            pathY1=pathY1(1,2:end-1);
            %here we have a new innerhseath index
            %which is used to define new roiz for the second imag and so on
            
            %verifying size
            sizePX=size(pathX1);
            if sizePX(2)==tile
            pathX1=pathX1(1,1:end);
            else
                pathX1=pathX1(1,1:tile);
            end
            
            sizePY=size(pathY1);
            if sizePY(2)==tile
            pathY1=pathY1(1,1:end);
            else
                pathY1=pathY1(1,1:tile);
            end
            pathXX1=cat(2,pathXX1,pathX1);
    end
    
pathXXX1=cat(1,pathXXX1,pathXX1);
ballIn=pathXXX1(end)-3;
IndexLens= pathXXX1();

%matching size again 
%sometimes there will be one or two extra column

bzi= size(baseIntensity);
bzo= size(IndexLens);

if bzo(2)== bzi(2)
    IndexLens= IndexLens;
elseif  bzo(2)> bzi(2)
    IndexLens= IndexLens(1:bzi(2));
else
    IndexLens= cat(2,IndexLens,IndexLens(end));
end

IndexBallLens=IndexLens; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Segmenting the inner interface of the sheath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sheathin=innerSheath; % input innerSheath Index
tile=32;    %we devide the whole intesnity image into [st.alines_per_frame/2)*st.frame_count)/tile] images.
%In fact, every 32 Alines are considered as one image.    
thickness= 20;  %here we define a new roiz to segmentation innerSheath.
%only 20 pixels above and 20 pixels under selected innerSheath index are being proceed.(41 pixels as a whole)
%Every time, there is a 41-by-32 image to be processed.


pathXXX1=[]; 
pathXX1=[]; 
pathX1=[]; 

%performing median filtering, each output pixel contains the median value of its 5-by-5 neighbourhood.
Intensity=medfilt2(baseIntensity(),[5 5]); 
originalsize=size(Intensity);

%mat2tiles function considers every tile=32 Alines as one image.
    blocks=mat2tiles(Intensity(),originalsize(1),tile);
    
    for n=1:(originalsize(2))/tile

            img1=blocks{1, n} ;
            img1=img1(sheathin-thickness:sheathin+thickness-2,:);
            %pad images with vertical columns on both sides
            %adding two column of zeros on each side and assigning lower
            %weight to them, in this way, seed is selected automatically.
            szImg = size(img1);
            imgNew = zeros([szImg(1) szImg(2)+2]);
            imgNew(:,2:szImg(2)+1) = img1;
            szImgNew = size(imgNew);  
            % get  vertical gradient image (normalized)
            gradImg = nan(szImgNew);
               for i = 1:szImgNew(2)
                gradImg(:,i) = 1*gradient(imgNew(:,i),2);
               end
            gradImg = (gradImg-min(gradImg(:)))/(max(gradImg(:))-min(gradImg(:)));
            gradImg= (-1*(gradImg))+1;
            
       
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %generate adjacency matrix
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %minimum weight
            minWeight = 1E-5;
   
            %arry to store weights
            adjMW = nan([numel(imgNew(:)),8]);
            %arry to store point A locations
            adjMX = nan([numel(imgNew(:)),8]);
            %arry to store point B locations
            adjMY = nan([numel(imgNew(:)),8]);
            neighborIter = [1 1  1 0  0 -1 -1 -1;...
                            1 0 -1 1 -1  1  0 -1];
            szadjMW = size(adjMW);
            ind = 1; indR = 0;
            while ind ~= szadjMW(1)*szadjMW(2)
                [i, j] = ind2sub(szadjMW,ind);    
                [iX,iY] = ind2sub(szImgNew,i);    
                jX = iX + neighborIter(1,j);
                jY  = iY + neighborIter(2,j);
                 if jX >=1 && jX <= szImgNew(1) && jY >=1 && jY <= szImgNew(2)
                   %save weight
                   % set weight to minimum if on the sides
                   if   jY == 1 || jY == szImgNew(2)
                        adjMW(i,j) = minWeight;
                   else
                       %else, calculate the actual weight.
                      adjMW(i,j) = 2 - gradImg(iX,iY) - gradImg(jX,jY) + minWeight;
                   end
                   %save the subscript of the corresponding nodes
                    adjMX(i,j) = (sub2ind(szImgNew,iX,iY));
                    adjMY(i,j) = (sub2ind(szImgNew,jX,jY));
                 end
                ind = ind+1;
            end
            %assemble the adjacency matrix
            keepInd = ~isnan(adjMW(:)) & ~isnan(adjMX(:)) & ~isnan(adjMY(:));
            adjMW = adjMW(keepInd);
            adjMX = adjMX(keepInd);
            adjMY = adjMY(keepInd);
            
            %sparse matrices, based on with the gradient image
            %adjMatrixW is the graph
            adjMatrixW = graph((adjMX(:)),(adjMY(:)),adjMW(:));

             %adjMatrixW is the graph and 1 is the seed.
            [path1{1}] = shortestpath( (adjMatrixW), 1, numel(imgNew(:)) );
            [pathX1,pathY1] = ind2sub(szImgNew,path1{1});
            
            % get rid of first and last few points that is by the image
            % border
            pathX1 =pathX1(gradient(pathY1)~=0);
            pathY1 =pathY1(gradient(pathY1)~=0);
            pathX1=pathX1(1,2:end-1);
            
            %obtainig the actual sheath position in the image
            pathX1=pathX1+sheathin-thickness;
            pathY1=pathY1(1,2:end-1);
            
            %verifying size
            sizePX=size(pathX1);
            if sizePX(2)==tile
            pathX1=pathX1(1,1:end);
            else
                pathX1=pathX1(1,1:tile);
            end
            
            sizePY=size(pathY1);
            if sizePY(2)==tile
            pathY1=pathY1(1,1:end);
            else
                pathY1=pathY1(1,1:tile);
            end
            
            
            %here we have a new innerhseath index
            %which is used to define new roiz for the second imag  
            sheathin=pathX1(end)+1;
%             pathX1=pathX1+sheathin-thickness;
            pathXX1=cat(2,pathXX1,pathX1);
    end
pathXXX1=cat(1,pathXXX1,pathXX1);
sheathin=pathXXX1(end)+1;

IndexShIn= pathXXX1();
%matching size again
%sometimes there will be one or two extra column
bzi= size(baseIntensity);
bzo= size(IndexShIn);
if bzo(2)== bzi(2)
    IndexShIn= IndexShIn;
elseif  bzo(2)> bzi(2)
    IndexShIn= IndexShIn(1:bzi(2));
else
    IndexShIn= cat(2,IndexShIn,IndexShIn(end));
end
IndexInnerSheath=IndexShIn-4; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Segmenting the outer interface of the sheath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


baseIntensity= Int;
pathXXX1=[]; 
pathXX1=[]; 
pathX1=[]; 

s = size(baseIntensity);
Intensity=baseIntensity();
%performing median filtering.
Intensity=gather(Intensity); %transfer to memory
Intensity=medfilt2(Intensity(),[1 51]);
msk=baseIntensity;
% To segment the outer interface of the sheath,  we select the roiz based
% on the distance that exists between two inner and outer interface. and in
% combination with mat2tile function, every time, we consider a 9-by-16 image for further processing.

t=10; %selected roiz based on the anticipated outer sheath position
sheathThick=outerSheath-innerSheath;%53; %this is low profile probe approximate sheath thickness, it should be changed for other type of probes, 
%in fact, all the parameters, such as tile, thickness and ... need to be
%modified for other type of probes.
for i=1:s(2)
    msk(1:IndexInnerSheath(i)+(sheathThick)-t,i)=0;
    msk(IndexInnerSheath(i)+(sheathThick):end,i)=0;
end


Intensity1=msk.*Intensity;
ii=Intensity1(Intensity1~=0) ;
iii=reshape(ii,[],s(2));
Intensity=iii; %size of the Intesnity image here is 9-by-numberOfAlines

sizeIntensity=size(Intensity);
% the rest of the process is similar to previous section except that the seed in the first image 
%is selected automatically and the rest are chosen based on the previous images. 
 sheathin=t-2; %%%%%%%%%%%%%%%%%%%%%%%%%might not be needed.
    blocks=mat2tiles(Intensity(),sizeIntensity(1),tile);
    for n=1:(originalsize(2))/tile
        if n==1
                 img1=blocks{1, n} ;
            szImg = size(img1);
            imgNew = zeros([szImg(1) szImg(2)+2]);
            imgNew(:,2:szImg(2)+1) = img1;
            szImgNew = size(imgNew);  
            gradImg = nan(szImgNew);
               for i = 1:szImgNew(2)
                gradImg(:,i) = 1*gradient(imgNew(:,i),2); %%%%%%%%%%
               end

            gradImg = (gradImg-min(gradImg(:)))/(max(gradImg(:))-min(gradImg(:)));
            minWeight = 1E-5;
            adjMW = nan([numel(imgNew(:)),8]);
            adjMX = nan([numel(imgNew(:)),8]);
            adjMY = nan([numel(imgNew(:)),8]);
            neighborIter = [1 1  1 0  0 -1 -1 -1;...
                            1 0 -1 1 -1  1  0 -1];

            szadjMW = size(adjMW);
            ind = 1; indR = 0;
            while ind ~= szadjMW(1)*szadjMW(2)
                [i, j] = ind2sub(szadjMW,ind);    
                [iX,iY] = ind2sub(szImgNew,i);    
                jX = iX + neighborIter(1,j);
                jY  = iY + neighborIter(2,j);
                 if jX >=1 && jX <= szImgNew(1) && jY >=1 && jY <= szImgNew(2)

                   if   jY == 1 || jY == szImgNew(2) 
                        adjMW(i,j) = minWeight;
                   else
                      adjMW(i,j) = 2 - gradImg(iX,iY) - gradImg(jX,jY) + minWeight;
                   end
                    adjMX(i,j) = (sub2ind(szImgNew,iX,iY));
                    adjMY(i,j) = (sub2ind(szImgNew,jX,jY));
                 end
                ind = ind+1;
            end

            keepInd = ~isnan(adjMW(:)) & ~isnan(adjMX(:)) & ~isnan(adjMY(:));
            adjMW = adjMW(keepInd);
            adjMX = adjMX(keepInd);
            adjMY = adjMY(keepInd);


            adjMatrixW = graph((adjMX(:)),(adjMY(:)),adjMW(:));

             %adjMatrixW is the graph and 1 is the seed.
            [path1{1}] = shortestpath( (adjMatrixW), 1, numel(imgNew(:)) );

            [pathX1,pathY1] = ind2sub(szImgNew,path1{1});
            pathX1 =pathX1(gradient(pathY1)~=0);
            pathY1 =pathY1(gradient(pathY1)~=0);
            pathX1=pathX1(1,2:end-1);
            pathY1=pathY1(1,2:end-1);
            siz=size(pathX1);
            sheathin=pathX1(end);
        else
            img1=blocks{1, n} ;
            szImg = size(img1);
            imgNew = zeros([szImg(1) szImg(2)+1]);
            imgNew(:,1:szImg(2)) = img1;
            szImgNew = size(imgNew);  
            gradImg = nan(szImgNew);
               for i = 1:szImgNew(2)
                gradImg(:,i) = 1*gradient(imgNew(:,i),2); 
               end

            gradImg = (gradImg-min(gradImg(:)))/(max(gradImg(:))-min(gradImg(:)));
            minWeight = 1E-5;
            adjMW = nan([numel(imgNew(:)),8]);
            adjMX = nan([numel(imgNew(:)),8]);
            adjMY = nan([numel(imgNew(:)),8]);
            neighborIter = [1 1  1 0  0 -1 -1 -1;...
                            1 0 -1 1 -1  1  0 -1];

            szadjMW = size(adjMW);
            ind = 1; indR = 0;
            while ind ~= szadjMW(1)*szadjMW(2)
                [i, j] = ind2sub(szadjMW,ind);    
                [iX,iY] = ind2sub(szImgNew,i);    
                jX = iX + neighborIter(1,j);
                jY  = iY + neighborIter(2,j);
                 if jX >=1 && jX <= szImgNew(1) && jY >=1 && jY <= szImgNew(2)
                   if   jY == szImgNew(2) 
                        adjMW(i,j) = minWeight;
                   else
                      adjMW(i,j) = 2 - gradImg(iX,iY) - gradImg(jX,jY) + minWeight;
                   end
                    adjMX(i,j) = (sub2ind(szImgNew,iX,iY));
                    adjMY(i,j) = (sub2ind(szImgNew,jX,jY));
                 end
                ind = ind+1;
            end
            keepInd = ~isnan(adjMW(:)) & ~isnan(adjMX(:)) & ~isnan(adjMY(:));
            adjMW = adjMW(keepInd);
            adjMX = adjMX(keepInd);
            adjMY = adjMY(keepInd);;

            adjMatrixW = graph((adjMX(:)),(adjMY(:)),adjMW(:));

             %adjMatrixW is the graph and 1 is the seed.
            [path1{1}] = shortestpath( (adjMatrixW), sheathin, numel(imgNew(:)) );


            [pathX1,pathY1] = ind2sub(szImgNew,path1{1});
            pathX1 =pathX1(gradient(pathY1)~=0);
            pathY1 =pathY1(gradient(pathY1)~=0);
            
            %verifying size
            sPX=size(pathX1);
            if sPX(2)==tile
                pathX1=pathX1(1:end);
            else
                pathX1=pathX1(1:tile);
            end
            
            sPY=size(pathY1);
            
            if sPY(2)==tile
                pathY1=pathY1(1:end);
            else
                pathY1=pathY1(1:tile);

            end
        end
       pathXX1=cat(2,pathXX1,pathX1);
       sheathin=pathXX1(end);
%         
    end
      pathXXX1=cat(1,pathXXX1,pathXX1);
      sizeSheath=size((IndexInnerSheath));
            %verifying size
            sPX=size(pathXXX1);
            if sPX(2)==sizeSheath(2)
                pathXXX1=pathXXX1(1:end);
            else
                pathXXX1=pathXXX1(1:sizeSheath(2));
            end
       


      IndexShOut= pathXXX1+IndexInnerSheath+(sheathThick)-t;

sheathin=IndexShOut(end);  
IndexOuterSheath=IndexShOut+2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sample surface segmentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Int=gather(Int);
intTh=90;
mm = (Int)>intTh;
sizeInt=size(Int);
mm = mm & (1:sizeInt(1))'>IndexOuterSheath();
edgeDown = circshift(mm,1)&~mm;% find end of thresholded pixels

[mv,mp] = max(diff(cummax(cumsum(mm,1).*edgeDown,1),1,1),[],1);% compute length of continuous pixels above threshold

surf = mp-mv;
filtw = 20;
surf = medfilt1(cat(2,surf(end-filtw+1:end),surf,surf(1:filtw)),filtw);
mask = surf(filtw+1:end-filtw);

end