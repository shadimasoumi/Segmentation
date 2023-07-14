
clc
clear
% fout1= '/Users/shadi/Downloads/21NOV/22-11-21_14-40-32_9550100/F8';
% fout1='/Volumes/DCC Lab Hard Drive/data Nov/9NOV2022/22-11-09_15-39-58_9550100/S6';
% fout1='D:\DATA\OA-Pulmonary-probe-October13-2022\OA_J_1\22-10-03_11-03-53_9550100\F4';
fout1='/Volumes/DCC Lab Hard Drive/21November/F8';
%% 
fout='D:\DATA\23-02-22-Walter-second-PSOCT-after-dMRI\WAITERFEB\23-02-22_11-35-18_9550100\S4';
[~, st] = readNPMRaw(fout);
st.gpu = true;
roiz = 601:1700;
% st.frame_count= 1;
% sliceIndex= st.frame_count;
Int=[];
for slice = 1 %beginnigslice:sliceIndex-1
tom = gather(recstrTomNPM(fout,slice,st));
int=gather(tom2Int(tom));
int=int(roiz,:);
Int=cat(2,Int,int);
end
Intensity= 10*log10(Int(:,1:2:end) + Int(:,2:2:end));
% % Intensity= 10*log10(Int(roiz,1:2:end) + Int(roiz,2:2:end));
colormap gray
img= Intensity(:,:);
img2=imdilate(img,strel('disk',20));
img2=imerode(img2,strel('disk',30));

        
subplot(1,2,1)
imagesc(img)
subplot(1,2,2)
imagesc(img2)




%% 
%good one
clc
clear
% fout1= '/Users/shadimasoumi/Google Drive/DBS project/Data/PSOCT/S2';

fout1='/Volumes/DCC Lab Hard Drive/data Nov/9NOV2022/22-11-09_15-39-58_9550100/S6';
% fout1='/Volumes/DCC Lab Hard Drive/21November/F8';
[~, st] = readNPMRaw(fout1);
st.gpu = false;
roiz = 601:1700;
sliceIndex= 1;
Int=[];
for slice = 1:sliceIndex %beginnigslice:sliceIndex-1
tom = gather(recstrTomNPM(fout1,slice,st));
int=gather(tom2Int(tom));
Int=cat(2,Int,int);
end
Intensity= 10*log10(Int(roiz,1:2:end) + Int(roiz,2:2:end));
Intensity1 = imerode(Intensity,strel('disk',6));
load('phantom.mat');
maskSheath= OuterSheathPosition;
img=Intensity1;
for ind= 1:2048
    img(1:maskSheath(ind),ind)=0;
end
for ind= 1:2048
  for y=1:1100 
     if img(y,ind)>75
        img(y,ind)=1;%img(y,ind);
     else
        img(y,ind)=0;
     end
  end

end
img2=imdilate(img,strel('disk',20));
img2=imerode(img2,strel('disk',30));

% for ind=1:2048
% % A = find(img2(maskSheath(ind):end,ind)== 1,'first');
% new=maskSheath+10;
% A(ind) = find(img2(new(ind):end,ind)>0,1);
% end

        
subplot(2,2,1)
imagesc(Intensity)
hold on
plot(OuterSheathPosition)
subplot(2,2,2)
imagesc(Intensity1)
subplot(2,2,3)
imagesc(img)
subplot(2,2,4)
imagesc(img2)
hold on
plot(OuterSheathPosition,'r')
hold on
B= reshape(maskSheath,[1,1024]);
plot(A+B,'g')

%% 
clc
clear
% fout1= '/Users/shadi/Downloads/21NOV/22-11-21_14-40-32_9550100/F8';
fout='D:\DATA\23-02-22-Walter-second-PSOCT-after-dMRI\WAITERFEB\23-02-22_11-35-18_9550100\S4';
% fout1='/Volumes/DCC Lab Hard Drive/21November/F8';
[~, st] = readNPMRaw(fout);
st.gpu = false;
roiz = 601:1700;
sliceIndex= 1;%st.frame_count;
Int=[];

for slice = 1:sliceIndex %beginnigslice:sliceIndex-1
tom = gather(recstrTomNPM(fout,slice,st));
int=gather(tom2Int(tom));
Int=cat(2,Int,int);
end
lens=0;
IndexInnerSheath = 159-lens;
IndexOuterSheath = 213-lens;
%  IndexL(1)=IndexLens;
 IndexSh(1)=159-lens;
 IndexOut(1)=213-lens;
Intensity1= 10*log10(Int(roiz,1:2:end) + Int(roiz,2:2:end));
lens=0;
% Intensity1= Intensity1(lens:end,:);
Intensity=imdilate(Intensity1,strel('disk',8));
Intensityy = imerode(Intensity,strel('disk',4));




[~,threshold] = edge(Intensity1,'Canny');
fudgeFactor = 3;
Intensity2 = edge(Intensityy,'Canny',threshold * fudgeFactor);
%Intensity = edge(Intensityy,'Canny',threshold * fudgeFactor);
Intensity=imdilate(Intensity2,strel('disk',5));
Intensity = bwareaopen(Intensity2, 10);
h = fspecial('log',7,0.2);
BWsdil = imfilter(Intensity,h);
Intensity = imfill(BWsdil,[8],"holes");

Intensity=imclose(Intensity(),ones(10));
% Intensity=imdilate(Intensity,strel('disk',3));
Intensity = imerode(Intensity,strel('disk',2));

% 
% 
subplot(1, 3, 1);
imagesc(Intensity1)
subplot(1, 3, 2);
imagesc(Intensityy)
subplot(1, 3, 3);
imagesc(Intensity)

%% 

ps.NAlines=st.alines_per_frame/2;           
ps.NSlices=sliceIndex;

 IndexL = zeros(1,ps.NAlines*ps.NSlices); 
 IndexSh = zeros(1,ps.NAlines*ps.NSlices);
 IndexOut = zeros(1,ps.NAlines*ps.NSlices);
 answer=zeros(1,ps.NAlines*ps.NSlices);
IndexInnerSheath = 159-lens;
IndexOuterSheath = 213-lens;
%  IndexL(1)=IndexLens;
 IndexSh(1)=159-lens;
 IndexOut(1)=213-lens;
 SheathThinkness = IndexOuterSheath-IndexInnerSheath; %to calculate the outer sheath position based on the inner sheath.

 
 
 for Alines=2:(ps.NSlices*ps.NAlines)
    Width = 1; % a constant width to look for the max intensity.


    [~,tempSh(Alines)] = max(Intensityy(IndexSh(Alines-1)-Width:IndexSh(Alines-1)+Width,Alines),[],1); 
    IndexSh(Alines)= tempSh(Alines)+IndexSh(Alines-1)-2*Width;
    IndexSh(Alines)= IndexSh(Alines)-IndexSh(Alines-1)+IndexSh(Alines);  %Inner Sheath Position is obtained here.
    IndexShValue(Alines)=Intensityy(IndexSh(Alines),Alines); % Pixel value at the Inner Sheath position
    if (2 <= Alines) && (Alines <= 50)
           sigmaSh=std(IndexShValue(1:Alines));
    else
           sigmaSh=std(IndexShValue((Alines-48):Alines));
    end
    if Intensity(IndexSh(Alines),Alines)==1
        IndexSh(Alines)= tempSh(Alines)+IndexSh(Alines-1)-2*Width;
        IndexSh(Alines)= IndexSh(Alines)-IndexSh(Alines-1)+IndexSh(Alines);
%     elseif abs(IndexShValue(Alines)-IndexShValue(Alines-1))< sigmaSh
%              IndexSh(Alines)= tempSh(Alines)+IndexSh(Alines-1)-2*Width;
%              IndexSh(Alines)= IndexSh(Alines)-IndexSh(Alines-1)+IndexSh(Alines);
    else
            IndexSh(Alines)= IndexSh(Alines-1);
    end 
 end
IndexOut= IndexSh+ SheathThinkness;
InnerSheathPosition = reshape(IndexSh,[ps.NAlines,ps.NSlices]);
OuterSheathPosition = reshape(IndexOut,[ps.NAlines,ps.NSlices]);

%% 

sliceIndex=1;

% NAlines= 234;
IndexSh = reshape(InnerSheathPosition,[1,sliceIndex*1024]);
% IndexL = reshape(LensPosition,[1,sliceIndex*1024]);
IndexOut = reshape(OuterSheathPosition,[1,sliceIndex*1024]);
imagesc(Intensityy(:,:))
colormap gray
hold on 
plot(IndexSh,'r')
% hold on 
% plot(IndexL,'y')
hold on 
plot(IndexOut,'g')
%% 

clc
clear
%fout1= '/Users/shadi/Downloads/21NOV/22-11-21_14-40-32_9550100/S13';
fout1='D:\DATA\23-02-22-Walter-second-PSOCT-after-dMRI\WAITERFEB\23-02-22_11-35-18_9550100\S4';
[~, st] = readNPMRaw(fout1);
st.gpu = false;
roiz = 601:1700;
sliceIndex= 2;%%st.frame_count;
Int=[];
for slice = 1:sliceIndex %beginnigslice:sliceIndex-1
tom = gather(recstrTomNPM(fout1,slice,st));
int=gather(tom2Int(tom));
Int=cat(2,Int,int);
end
IndexInnerSheath = 160;
IndexOuterSheath = 216;
%  IndexL(1)=IndexLens;
 IndexSh(1)=160;
 IndexOut(1)=216;
Intensity1= 10*log10(Int(roiz,1:2:end) + Int(roiz,2:2:end));
Intensity=imdilate(Intensity1,strel('disk',8));
Intensityy = imerode(Intensity,strel('disk',4));



[~,threshold] = edge(Intensity1,'Canny');
fudgeFactor = 3;
Intensity2 = edge(Intensityy,'Canny',threshold * fudgeFactor);
Intensity = edge(Intensityy,'Canny',threshold * fudgeFactor);
Intensity=imdilate(Intensity2,strel('disk',5));
Intensity = bwareaopen(Intensity2, 10);
h = fspecial('log',7,0.2);
BWsdil = imfilter(Intensity,h);
Intensity = imfill(BWsdil,[8],"holes");

Intensity=imclose(Intensity(),ones(10));
% Intensity=imdilate(Intensity,strel('disk',3));
Intensity = imerode(Intensity,strel('disk',8));

% 
% 
subplot(1, 3, 1);
imagesc(Intensityy)
subplot(1, 3, 2);
imagesc(Intensity1)
subplot(1, 3, 3);
imagesc(Intensity)


%% 

clc
clear
% fout1= '/Users/shadimasoumi/Google Drive/DBS project/Data/PSOCT/S2';

% fout1='/Volumes/DCC Lab Hard Drive/data Nov/9NOV2022/22-11-09_15-39-58_9550100/S6';
fout1='/Volumes/DCC Lab Hard Drive/21November/F8';
[~, st] = readNPMRaw(fout1);
st.gpu = false;
roiz = 601:1700;
sliceIndex= 1;
Int=[];
for slice = 1:sliceIndex %beginnigslice:sliceIndex-1
tom = gather(recstrTomNPM(fout1,slice,st));
int=gather(tom2Int(tom));
Int=cat(2,Int,int);
end
Intensity= 10*log10(Int(roiz,1:2:end) + Int(roiz,2:2:end));


% [~,threshold] = edge(Intensity,'Canny');
% fudgeFactor = 9;
% BWs = edge(Intensity,'Canny',threshold * fudgeFactor);
% h = fspecial('log',7,0.4);
% BWsdil = imfilter(BWs,h);
% img = imdilate(BWsdil,strel('disk',30));
% img2=imerode(img,strel('disk',15));
% subplot(2,2,1)
% imagesc(Intensity)
% subplot(2,2,2)
% imagesc(BWsdil)
% subplot(2,2,3)
% imagesc(img)
% subplot(2,2,4)
% imagesc(img2)

% Intensity1 = imerode(Intensity,strel('disk',6));
% load('phantom.mat');
% maskSheath= OuterSheathPosition;
% img=Intensity1;
% for ind= 1:2048
%     img(1:maskSheath(ind),ind)=0;
% end
% for ind= 1:2048
%   for y=1:1100 
%      if img(y,ind)>75
%         img(y,ind)=1;%img(y,ind);
%      else
%         img(y,ind)=0;
%      end
%   end
% 
% end
% img2=imdilate(img,strel('disk',20));
% img2=imerode(img2,strel('disk',30));
% 
% % for ind=1:2048
% % % A = find(img2(maskSheath(ind):end,ind)== 1,'first');
% % new=maskSheath+10;
% % A(ind) = find(img2(new(ind):end,ind)>0,1);
% % end
% 
%         
% subplot(2,2,1)
% imagesc(Intensity)
% hold on
% plot(OuterSheathPosition)
% subplot(2,2,2)
% imagesc(Intensity1)
% subplot(2,2,3)
% imagesc(img)
% subplot(2,2,4)
% imagesc(img2)
% hold on
% plot(OuterSheathPosition,'r')
% hold on
% B= reshape(maskSheath,[1,2048]);
% plot(A+B,'g')


%% 
clc
clear
% fout1='D:\DATA\HANU\22-12-15_20-03-51_9550100\S9';
fout1='D:\DATA\23-02-22-Walter-second-PSOCT-after-dMRI\WAITERFEB\23-02-22_11-35-18_9550100\S4';
% fout1='D:\DATA\OA-Pulmonary-probe-October13-2022\OA_J_1\22-10-03_11-03-53_9550100\F8';
[~, st] = readNPMRaw(fout1);
st.gpu = true;
roiz = 601:1700;
sliceIndex= 1;
Int=[];
for slice = sliceIndex %beginnigslice:sliceIndex-1
tom = gather(recstrTomNPM(fout1,slice,st));
int=gather(tom2Int(tom));
Int=cat(2,Int,int);
end
Intensity= log10(Int(roiz,1:2:end) + Int(roiz,2:2:end));



Intensity=medfilt2(Intensity(),[1 21]); 
Intensity=imdilate(Intensity,strel('disk',8));
Intensity = imerode(Intensity,strel('disk',4));


BW = im2bw(0.010*Intensity,0.095);
BW1=imdilate(BW,strel('disk',1));
BW2 = imerode(BW1,strel('disk',4));


colormap gray
subplot(1,4,1)
imagesc(Intensity)
subplot(1,4,2)
imagesc(BW)
subplot(1,4,3)
imagesc(BW1)
subplot(1,4,4)
imagesc(BW2)


